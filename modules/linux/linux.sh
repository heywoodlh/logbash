### linux log module
linux() {
  logbash_run_module "$1" "$2" "${linux_log_target:-}"
}
