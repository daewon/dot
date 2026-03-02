#!/usr/bin/env bash

run_with_log() {
  local name="$1"
  shift
  local logfile="$LOG_DIR/${name}.log"

  if "$@" >"$logfile" 2>&1; then
    local warn_count=""
    local err_count=""

    warn_count="$(count_matches "\\[warn\\]" "$logfile")"
    err_count="$(count_matches "\\[error\\]" "$logfile")"
    ok "${name}: success (warn=${warn_count}, err=${err_count})"
  else
    err "${name}: failed (log: $logfile)"
    sed -n '1,160p' "$logfile" >&2 || true
    return 1
  fi
}

run_expect_failure() {
  local name="$1"
  local expected_rc="$2"
  local expected_pattern="$3"
  shift 3
  local logfile="$LOG_DIR/${name}.log"
  local rc=0

  if "$@" >"$logfile" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  if [ "$rc" != "$expected_rc" ]; then
    err "${name}: expected rc=${expected_rc}, got rc=${rc} (log: $logfile)"
    sed -n '1,160p' "$logfile" >&2 || true
    return 1
  fi
  if [ -n "$expected_pattern" ] && ! grep -Fq "$expected_pattern" "$logfile"; then
    err "${name}: expected pattern not found: $expected_pattern (log: $logfile)"
    sed -n '1,160p' "$logfile" >&2 || true
    return 1
  fi
  ok "${name}: expected failure observed (rc=${rc})"
}

run_setup_min() {
  run_with_log "$1" env INSTALL_OPTIONAL_TOOLS=0 INSTALL_TMUX_PLUGINS=0 SET_DEFAULT_SHELL=0 "$REPO_ROOT/setup.sh"
}

run_setup_default() {
  run_with_log "$1" env INSTALL_OPTIONAL_TOOLS=1 SET_DEFAULT_SHELL=0 "$REPO_ROOT/setup.sh"
}

run_cleanup() {
  local name="$1"
  local remove_global="${2:-0}"

  run_with_log "$name" env REMOVE_GLOBAL_TOOLS="$remove_global" "$REPO_ROOT/cleanup.sh"
}
