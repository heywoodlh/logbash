#!/usr/bin/env bash

# Shared file selection and search primitives. Log files are selected once for
# every module so default, --all, and --date behavior stays identical.
selected_log_files=()

logbash_expand_targets() {
  local target_spec="$1"
  local -a matches=()

  # compgen expands the pattern supplied as one argument, preserving spaces in
  # configured directories (for example, /logs/My Logs/*.log).
  mapfile -t matches < <(compgen -G "$target_spec" || true)
  selected_log_files+=("${matches[@]}")
}

logbash_sort_newest_first() {
  local file record
  local -a sorted=()

  while IFS= read -r -d '' record; do
    sorted+=("${record#*$'\t'}")
  done < <(
    for file in "${selected_log_files[@]}"; do
      [[ -f "$file" ]] || continue
      printf '%s\t%s\0' "$(stat -c '%Y' -- "$file")" "$file"
    done | sort -z -n -r
  )
  selected_log_files=("${sorted[@]}")
}

logbash_select_files() {
  local target_spec="$1" file basename cutoff_epoch day_epoch next_day_epoch
  local -a candidates=() selected=()

  selected_log_files=()
  logbash_expand_targets "$target_spec"
  candidates=("${selected_log_files[@]}")
  selected_log_files=()

  if [[ -n "${search_date_day:-}" ]]; then
    # Logbash's containers rotate daily files as YYYY_MM_DD.log. Selecting the
    # matching archive avoids opening every historical log for a date query.
    local date_token="${search_date_day//-/_}"
    for file in "${candidates[@]}"; do
      basename="${file##*/}"
      [[ "$basename" == *"$date_token"* ]] && selected+=("$file")
    done

    # Non-daily custom file names retain a mtime-based fallback.
    if [[ ${#selected[@]} -eq 0 ]]; then
      day_epoch="$(date -d "$search_date_day" +%s)"
      next_day_epoch="$(date -d "$search_date_day + 1 day" +%s)"
      for file in "${candidates[@]}"; do
        [[ -f "$file" ]] || continue
        if (( $(stat -c '%Y' -- "$file") >= day_epoch && $(stat -c '%Y' -- "$file") < next_day_epoch )); then
          selected+=("$file")
        fi
      done
    fi
  elif [[ -n "${search_all:-}" ]]; then
    selected=("${candidates[@]}")
  else
    cutoff_epoch="$(date -d '7 days ago' +%s)"
    for file in "${candidates[@]}"; do
      [[ -f "$file" ]] || continue
      (( $(stat -c '%Y' -- "$file") >= cutoff_epoch )) && selected+=("$file")
    done
  fi

  selected_log_files=("${selected[@]}")
  logbash_sort_newest_first
}

logbash_search_selected() {
  local pattern="$1" file found=1

  for file in "${selected_log_files[@]}"; do
    if rg --with-filename --no-messages --color=never -- "$pattern" "$file"; then
      found=0
    fi
  done
  if [[ "$found" -ne 0 && -z "${search_date_day:-}" && -z "${search_all:-}" && -z "${tail:-}" ]]; then
    printf 'No matches in the default 7-day window. Use --date YYYY-MM-DD or --all for historical logs.\n' >&2
  fi
  return "$found"
}

logbash_follow_selected() {
  local pattern="$1"

  [[ ${#selected_log_files[@]} -gt 0 ]] || return 0
  tail -n 0 -F -- "${selected_log_files[@]}" | rg --line-buffered --color=never -- "$pattern"
}

logbash_run_module() {
  local module_dir="$1" target="$2" target_spec="$3"
  local submodules_dir="$module_dir/submodules" target_file
  local -a submodules=()
  local file

  for file in "$submodules_dir"/*; do
    [[ -f "$file" ]] && submodules+=("$(basename "$file")")
  done

  if [[ -n "${help_requested:-}" ]]; then
    printf 'usage: %s %s [ %s] [ %s ]\n' "$0" "$(basename "$module_dir")" "${submodules[*]}" "$optional_args"
    return 0
  fi

  local known_submodule=0
  for file in "${submodules[@]}"; do
    [[ "$target" == "$file" ]] && known_submodule=1
  done
  if [[ "$known_submodule" -ne 1 ]]; then
    printf 'usage: %s %s [ %s] [ %s ]\n' "$0" "$(basename "$module_dir")" "${submodules[*]}" "$optional_args"
    return 1
  fi

  target_file="$submodules_dir/$target"
  unset grep_pattern search_command
  source "$target_file"
  logbash_select_files "$target_spec"

  if [[ -n "${grep_pattern:-}" ]]; then
    if [[ -n "${tail:-}" ]]; then
      logbash_follow_selected "$grep_pattern"
    else
      logbash_search_selected "$grep_pattern"
    fi
  elif [[ -n "${search_command:-}" ]]; then
    printf 'search_command is no longer supported; use grep_pattern in %s.\n' "$target_file" >&2
    return 2
  fi
}
