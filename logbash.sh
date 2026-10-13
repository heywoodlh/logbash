#!/usr/bin/env bash
set -o pipefail

rootDir="$(dirname "$(realpath "$0")")"
if [[ -n "${LOGBASH_CONFIG:-}" ]]; then
  [[ -e "${LOGBASH_CONFIG}" ]] || { echo "Config file not found: ${LOGBASH_CONFIG}" >&2; exit 1; }
  config_file="${LOGBASH_CONFIG}"
else
  config_file="${rootDir}/config.sh"
fi
modules_dir="${rootDir}/modules"
optional_args='--tail --all --date "YYYY-MM-DD"'

set -o noglob
source "$config_file"
set +o noglob
source "${rootDir}/lib/logbash-search.sh"

positionals=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tail)
      tail=1
      ;;
    --all)
      search_all=1
      ;;
    --date)
      shift
      [[ $# -gt 0 ]] || { echo "--date requires a date value." >&2; exit 2; }
      [[ "${disable_date:-}" != "true" ]] || { echo "--date is disabled by configuration." >&2; exit 2; }
      search_date="$1"
      ;;
    --date=*)
      [[ "${disable_date:-}" != "true" ]] || { echo "--date is disabled by configuration." >&2; exit 2; }
      search_date="${1#*=}"
      [[ -n "$search_date" ]] || { echo "--date requires a date value." >&2; exit 2; }
      ;;
    --help|-h)
      echo "usage: $0 [ cisco http linux palo unifi ] [ $optional_args ]"
      exit 0
      ;;
    --)
      shift
      positionals+=("$@")
      break
      ;;
    *)
      positionals+=("$1")
      ;;
  esac
  shift
done

if [[ -n "${tail:-}" && -n "${search_date:-}" ]]; then
  echo "Cannot run both --tail and --date arguments." >&2
  exit 2
fi
if [[ -n "${search_all:-}" && -n "${search_date:-}" ]]; then
  echo "Cannot run both --all and --date arguments." >&2
  exit 2
fi
if [[ -n "${tail:-}" && -n "${search_all:-}" ]]; then
  echo "Cannot run both --tail and --all arguments." >&2
  exit 2
fi
if [[ -n "${search_date:-}" ]]; then
  if [[ ! "$search_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || ! search_date_day="$(date -d "$search_date" +%F)" || [[ "$search_date_day" != "$search_date" ]]; then
    echo "Invalid date passed to --date argument." >&2
    exit 2
  fi
fi

target_command="${positionals[0]:-}"
subcommands="${positionals[*]:1}"

modules_array=()
for file in "$modules_dir"/*; do
  [[ -d "$file" ]] && modules_array+=("$(basename "$file")")
done

module_dir="$modules_dir/$target_command"
module_file="$module_dir/$target_command.sh"
known_module=0
for module in "${modules_array[@]}"; do
  [[ "$target_command" == "$module" ]] && known_module=1
done
if [[ "$known_module" -eq 1 && -f "$module_file" ]]; then
  source "$module_file"
  "$target_command" "$module_dir" "$subcommands"
else
  echo "usage: $0 [ ${modules_array[*]}] [ $optional_args ]" >&2
  exit 2
fi
