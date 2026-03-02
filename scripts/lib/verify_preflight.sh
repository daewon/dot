#!/usr/bin/env bash

verify_preflight_checks() {
  local cmd=""
  local file=""

  for cmd in "${VERIFY_REQUIRED_CMDS[@]}"; do
    if ! dot_require_cmd "$cmd"; then
      err "required command not found: $cmd"
      return 1
    fi
  done
  for file in setup.sh cleanup.sh scripts/setup.sh scripts/cleanup.sh; do
    [ -x "$REPO_ROOT/$file" ] || { err "$file is not executable"; return 1; }
  done
  mkdir -p "$LOG_DIR"
  ok "repo: $REPO_ROOT"
  ok "logs: $LOG_DIR"
  ok "config: profile=$VERIFY_PROFILE setup_only=$SETUP_ONLY_LOOPS cycle=$CYCLE_LOOPS default=$RUN_DEFAULT_SETUP default_loops=$DEFAULT_SETUP_LOOPS restore=$RESTORE_AT_END clipboard_runtime=$VERIFY_CLIPBOARD_RUNTIME"
}

verify_syntax_checks() {
  local file=""
  local shellcheck_bin=""
  local -a shellcheck_targets=()

  for file in "${VERIFY_LINT_TARGETS[@]}"; do
    bash -n "$REPO_ROOT/$file"
  done
  shellcheck_bin="$(dot_find_cmd shellcheck 2>/dev/null || true)"
  if [ -n "${shellcheck_bin:-}" ]; then
    for file in "${VERIFY_LINT_TARGETS[@]}"; do
      shellcheck_targets+=("$REPO_ROOT/$file")
    done
    "$shellcheck_bin" -x "${shellcheck_targets[@]}"
    ok "shellcheck passed"
  else
    warn "shellcheck not found; skipped static shell analysis"
  fi
  ok "bash syntax valid"
}
