### cisco log module
cisco() {
  logbash_run_module "$1" "$2" "${cisco_log_target:-}"
}
