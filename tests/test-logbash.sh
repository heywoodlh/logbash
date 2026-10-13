#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
logbash_bin="${LOGBASH_BIN:-$root_dir/logbash.sh}"
tmp_dir="$(mktemp -d '/tmp/logbash behavior.XXXXXX')"
trap 'rm -rf "$tmp_dir"' EXIT

today_day="$(date +%F)"
recent_day="$(date -d '1 day ago' +%F)"
old_day="$(date -d '30 days ago' +%F)"
today_token="${today_day//-/_}"
recent_token="${recent_day//-/_}"
old_token="${old_day//-/_}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_not_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" != *"$needle"* ]] || fail "expected output not to contain: $needle"
}

write_log() {
  local module="$1" filename="$2" timestamp="$3" content="$4"
  mkdir -p "$tmp_dir/logs/$module"
  printf '%s\n' "$content" > "$tmp_dir/logs/$module/$filename"
  touch -d "$timestamp" "$tmp_dir/logs/$module/$filename"
}

cat > "$tmp_dir/config.sh" <<CONFIG
export linux_log_target="$tmp_dir/logs/linux/*.log"
export http_log_target="$tmp_dir/logs/http/*.log"
export palo_log_target="$tmp_dir/logs/palo/*.log"
export cisco_log_target="$tmp_dir/logs/cisco/*.log"
export unifi_log_target="$tmp_dir/logs/unifi/*.log"
CONFIG

write_log unifi "${old_token}.log" "$old_day 12:00:01 UTC" 'dnsmasq-dhcp[1]: OLD_DHCP'
write_log unifi "${recent_token}.log" "$recent_day 12:00:01 UTC" 'dnsmasq-dhcp[1]: RECENT_DHCP'
write_log unifi "${today_token}.log" "$today_day 12:00:01 UTC" 'dnsmasq-dhcp[1]: NEWEST_DHCP
router vpn connected
router sshd login
router SRC=10.0.0.1
router admin_ip=10.0.0.2'
write_log linux "${today_token}.log" "$today_day 12:00:01 UTC" 'host sshd[1]: accepted SSH_MARKER
host sshd[1]: Failed password SSH_FAILED_MARKER
host audit: msg=audit type=EXECVE AUDIT_MARKER euid=0 ROOT_MARKER
host /bin/sudo SUDO_MARKER'
write_log http "${today_token}.log" "$today_day 12:00:01 UTC" 'http HTTP 200 HTTP_MARKER'
write_log cisco "${today_token}.log" "$today_day 12:00:01 UTC" 'cisco %SNMP-3-AUTHFAIL SNMP_MARKER
cisco %SEC-6-IPACCESSLOGP ACL_MARKER'
write_log palo "${today_token}.log" "$today_day 12:00:01 UTC" 'palo THREAT scan SCAN_MARKER
palo CONFIG commit COMMIT_MARKER
palo auth admin ADMIN_MARKER
palo THREAT high HIGH_MARKER
palo THREAT crit CRIT_MARKER'

run_logbash() {
  LOGBASH_CONFIG="$tmp_dir/config.sh" bash "$logbash_bin" "$@"
}

# Default searches must be bounded to seven days and process the newest file first.
default_output="$(run_logbash unifi dhcp)"
assert_contains "$default_output" NEWEST_DHCP
assert_contains "$default_output" RECENT_DHCP
assert_not_contains "$default_output" OLD_DHCP
[[ "${default_output%%$'\n'*}" == *NEWEST_DHCP* ]] || fail 'default search did not start with the newest log'

# --all restores the historical archive.
all_output="$(run_logbash unifi dhcp --all)"
assert_contains "$all_output" OLD_DHCP

# --date selects the matching daily archive without scanning unrelated history.
date_output="$(run_logbash unifi dhcp --date "$old_day")"
assert_contains "$date_output" OLD_DHCP
assert_not_contains "$date_output" NEWEST_DHCP

# Every built-in module and submodule uses the shared selection path.
for target in \
  'linux auditd AUDIT_MARKER' \
  'linux commands AUDIT_MARKER' \
  'linux root-commands ROOT_MARKER' \
  'linux ssh SSH_MARKER' \
  'linux ssh-failed-login SSH_FAILED_MARKER' \
  'linux sudo SUDO_MARKER' \
  'linux all SSH_MARKER' \
  'http 200 HTTP_MARKER' \
  'cisco snmpfail SNMP_MARKER' \
  'cisco acldeny ACL_MARKER' \
  'palo scan SCAN_MARKER' \
  'palo commit COMMIT_MARKER' \
  'palo admin ADMIN_MARKER' \
  'palo threats HIGH_MARKER' \
  'unifi admin admin_ip=10.0.0.2' \
  'unifi dhcp NEWEST_DHCP' \
  'unifi firewall SRC=10.0.0.1' \
  'unifi ssh sshd login' \
  'unifi vpn vpn connected' \
  'unifi all NEWEST_DHCP'; do
  read -r module submodule marker <<< "$target"
  output="$(run_logbash "$module" "$submodule")"
  assert_contains "$output" "$marker"
done

if run_logbash unifi dhcp --all --date "$old_day" >/dev/null 2>&1; then
  fail '--all and --date must be mutually exclusive'
fi

if run_logbash unifi dhcp --date invalid-date >/dev/null 2>&1; then
  fail 'invalid dates must fail'
fi

if run_logbash unifi dhcp --date= >/dev/null 2>&1; then
  fail '--date= must require a date value'
fi

if run_logbash unifi dhcp --date 'Oct 13 2026' >/dev/null 2>&1; then
  fail '--date must require YYYY-MM-DD'
fi

if run_logbash unifi ../unifi.sh >/dev/null 2>&1; then
  fail 'submodule path traversal must be rejected'
fi

module_traversal_output="$(run_logbash ../linux/linux ssh 2>&1 || true)"
assert_contains "$module_traversal_output" 'usage:'

printf 'logbash behavior tests passed\n'
