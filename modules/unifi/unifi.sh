### unifi log module
unifi() {
  logbash_run_module "$1" "$2" "${unifi_log_target:-}"
}
