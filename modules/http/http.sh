### http log module
http() {
  logbash_run_module "$1" "$2" "${http_log_target:-}"
}
