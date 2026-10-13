### palo log module
palo() {
  logbash_run_module "$1" "$2" "${palo_log_target:-}"
}
