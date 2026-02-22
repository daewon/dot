#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"
# shellcheck source=./toolset.sh
source "$REPO_ROOT/toolset.sh"
# shellcheck source=./scriptlib.sh
source "$REPO_ROOT/scriptlib.sh"

TOTAL_STEPS=7
STEP=0
FAILED_STEP=0

SETUP_ONLY_LOOPS="${SETUP_ONLY_LOOPS:-3}"
CYCLE_LOOPS="${CYCLE_LOOPS:-3}"
RUN_DEFAULT_SETUP="${RUN_DEFAULT_SETUP:-1}" # 1 or 0
DEFAULT_SETUP_LOOPS="${DEFAULT_SETUP_LOOPS:-1}"
RESTORE_AT_END="${RESTORE_AT_END:-1}"       # 1 or 0

LOG_DIR="${TMPDIR:-/tmp}/dot-verify-$(date +%Y%m%d-%H%M%S)"
MANIFEST_FILE="$(dot_setup_manifest_file)"

log() { printf '[verify] %s\n' "$*"; }
step() {
  STEP=$((STEP + 1))
  printf '\n[%d/%d] %s\n' "$STEP" "$TOTAL_STEPS" "$*"
}
ok() { printf '  [ok] %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
err() { printf '  [error] %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: ./verify.sh [options]

Options:
  --setup-only-loops N   Repeat setup(min profile) N times (default: 3)
  --cycle-loops N        Repeat cleanup->setup cycle N times (default: 3)
  --skip-default-setup   Skip default-profile setup verification
  --default-loops N      Repeat default-profile setup N times (default: 1)
  --no-restore           Skip final restore setup
  --help, -h             Show this help

Environment flags (same meaning as options):
  SETUP_ONLY_LOOPS=3
  CYCLE_LOOPS=3
  RUN_DEFAULT_SETUP=1
  DEFAULT_SETUP_LOOPS=1
  RESTORE_AT_END=1
EOF
}

on_error() {
  FAILED_STEP="$STEP"
  err "failed at step ${FAILED_STEP}"
  err "see logs in: $LOG_DIR"
}
trap on_error ERR

count_matches() {
  local pattern="$1"
  local file="$2"
  local c=""
  c="$(grep -c "$pattern" "$file" 2>/dev/null || true)"
  printf '%s' "${c:-0}"
}

count_git_include() {
  local c=""
  c="$(git config --global --get-all include.path 2>/dev/null | grep -Fxc "$REPO_ROOT/gitconfig.shared" || true)"
  c="$(printf '%s' "$c" | tr -d '[:space:]')"
  printf '%s' "${c:-0}"
}

tool_available() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if command -v mise >/dev/null 2>&1 && mise which "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

count_backup_files() {
  local c=""
  c="$(find "$HOME" -maxdepth 3 \
    \( -name '.zshrc.bak.*' -o -name '.tmux.conf.bak.*' -o -name '.zsh.shared.zsh.bak.*' \
       -o -name '.zlogin.bak.*' -o -name '.zlogout.bak.*' -o -name '.zprofile.bak.*' \
       -o -name '.zshenv.bak.*' -o -name '.zpreztorc.bak.*' -o -name 'helix.bak.*' \
       -o -name 'lazygit.bak.*' -o -name 'dot-difft.bak.*' -o -name 'dot-difft-pager.bak.*' \
       -o -name 'dot-lazygit-theme.bak.*' \) \
    2>/dev/null | wc -l || true)"
  c="$(printf '%s' "$c" | tr -d '[:space:]')"
  printf '%s' "${c:-0}"
}

assert_setup_state() {
  local include_count=""
  local resolved_link=""
  local manifest_line=""
  local link_path=""
  local link_target=""
  local clone_path=""
  local clone_origin=""
  local cmd=""

  include_count="$(count_git_include)"
  [ "$include_count" = "1" ] || { err "git include.path count expected 1, got: $include_count"; return 1; }
  while IFS=$'\t' read -r link_path link_target; do
    resolved_link="$(dot_resolve_path "$link_path")"
    [ "$resolved_link" = "$link_target" ] || { err "symlink mismatch: $link_path -> $resolved_link (expected $link_target)"; return 1; }
  done < <(dot_print_repo_symlink_entries "$REPO_ROOT")
  while IFS=$'\t' read -r link_path link_target; do
    resolved_link="$(dot_resolve_path "$link_path")"
    [ "$resolved_link" = "$link_target" ] || { err "runcom symlink mismatch: $link_path -> $resolved_link (expected $link_target)"; return 1; }
  done < <(dot_print_prezto_runcom_symlink_entries "$HOME")
  [ -f "$MANIFEST_FILE" ] || { err "setup manifest missing: $MANIFEST_FILE"; return 1; }
  manifest_line="repo_root"$'\t'"$REPO_ROOT"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest repo_root mismatch"; return 1; }
  while IFS=$'\t' read -r link_path link_target; do
    manifest_line="symlink"$'\t'"$link_path"$'\t'"$link_target"
    grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing symlink entry: $link_path"; return 1; }
  done < <(dot_print_repo_symlink_entries "$REPO_ROOT")
  while IFS=$'\t' read -r link_path link_target; do
    manifest_line="symlink"$'\t'"$link_path"$'\t'"$link_target"
    grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing runcom entry: $link_path"; return 1; }
  done < <(dot_print_prezto_runcom_symlink_entries "$HOME")
  manifest_line="managed_file_contains"$'\t'"$HOME/.zshrc"$'\t'"dot-setup managed zshrc"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing zshrc marker entry"; return 1; }
  while IFS=$'\t' read -r clone_path clone_origin; do
    manifest_line="git_clone_origin"$'\t'"$clone_path"$'\t'"$clone_origin"
    grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing clone entry: $clone_path"; return 1; }
  done < <(dot_print_managed_git_clones "$HOME")
  manifest_line="git_include_path"$'\t'"$REPO_ROOT/gitconfig.shared"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing git include entry"; return 1; }
  for cmd in "${DOT_REQUIRED_CLI_COMMANDS[@]}"; do
    tool_available "$cmd" || { err "command not found after setup: $cmd"; return 1; }
  done

  ok "state check passed (include=1, links aligned)"
}

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

run_setup_min() {
  run_with_log "$1" env INSTALL_OPTIONAL_TOOLS=0 INSTALL_TMUX_PLUGINS=0 SET_DEFAULT_SHELL=0 "$REPO_ROOT/setup.sh"
}

run_setup_default() {
  run_with_log "$1" env SET_DEFAULT_SHELL=0 "$REPO_ROOT/setup.sh"
}

run_cleanup() {
  run_with_log "$1" env REMOVE_GLOBAL_TOOLS=0 "$REPO_ROOT/cleanup.sh"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --setup-only-loops)
      [ "$#" -ge 2 ] || { err "missing value for --setup-only-loops"; exit 2; }
      SETUP_ONLY_LOOPS="$2"
      shift
      ;;
    --cycle-loops)
      [ "$#" -ge 2 ] || { err "missing value for --cycle-loops"; exit 2; }
      CYCLE_LOOPS="$2"
      shift
      ;;
    --skip-default-setup)
      RUN_DEFAULT_SETUP=0
      ;;
    --default-loops)
      [ "$#" -ge 2 ] || { err "missing value for --default-loops"; exit 2; }
      DEFAULT_SETUP_LOOPS="$2"
      shift
      ;;
    --no-restore)
      RESTORE_AT_END=0
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      err "unknown option: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

for n in "$SETUP_ONLY_LOOPS" "$CYCLE_LOOPS" "$DEFAULT_SETUP_LOOPS"; do
  if ! [[ "$n" =~ ^[0-9]+$ ]]; then
    err "loop values must be non-negative integers"
    exit 2
  fi
done

step "preflight"
for cmd in bash git grep find wc seq; do
  if ! dot_require_cmd "$cmd"; then
    err "required command not found: $cmd"
    exit 1
  fi
done
[ -x "$REPO_ROOT/setup.sh" ] || { err "setup.sh is not executable"; exit 1; }
[ -x "$REPO_ROOT/cleanup.sh" ] || { err "cleanup.sh is not executable"; exit 1; }
mkdir -p "$LOG_DIR"
ok "repo: $REPO_ROOT"
ok "logs: $LOG_DIR"
ok "config: setup_only=$SETUP_ONLY_LOOPS cycle=$CYCLE_LOOPS default=$RUN_DEFAULT_SETUP default_loops=$DEFAULT_SETUP_LOOPS restore=$RESTORE_AT_END"

step "syntax check"
bash -n "$REPO_ROOT/setup.sh"
bash -n "$REPO_ROOT/cleanup.sh"
bash -n "$REPO_ROOT/verify.sh"
SHELLCHECK_BIN=""
if dot_require_cmd shellcheck; then
  SHELLCHECK_BIN="$(command -v shellcheck)"
elif dot_require_cmd mise; then
  SHELLCHECK_BIN="$(mise which shellcheck 2>/dev/null || true)"
fi
if [ -n "${SHELLCHECK_BIN:-}" ]; then
  "$SHELLCHECK_BIN" \
    "$REPO_ROOT/setup.sh" \
    "$REPO_ROOT/cleanup.sh" \
    "$REPO_ROOT/verify.sh" \
    "$REPO_ROOT/toolset.sh" \
    "$REPO_ROOT/scriptlib.sh" \
    "$REPO_ROOT/difft-external.sh" \
    "$REPO_ROOT/difft-pager.sh" \
    "$REPO_ROOT/lazygit-theme.sh"
  ok "shellcheck passed"
else
  warn "shellcheck not found; skipped static shell analysis"
fi
ok "bash syntax valid"

step "dry-run smoke"
run_with_log "setup-dry-run" "$REPO_ROOT/setup.sh" --dry-run
run_with_log "cleanup-dry-run" "$REPO_ROOT/cleanup.sh" --dry-run

step "baseline setup(min profile)"
run_setup_min "setup-baseline"
assert_setup_state

step "setup-only idempotency"
backup_before="$(count_backup_files)"
for i in $(seq 1 "$SETUP_ONLY_LOOPS"); do
  run_setup_min "setup-only-${i}"
  assert_setup_state
done
backup_after="$(count_backup_files)"
if [ "$backup_before" = "$backup_after" ]; then
  ok "backup growth check passed (delta=0)"
else
  err "backup files increased during setup-only loops: before=$backup_before after=$backup_after"
  exit 1
fi

step "cleanup->setup cycle idempotency"
for i in $(seq 1 "$CYCLE_LOOPS"); do
  run_cleanup "cycle-${i}-cleanup"
  run_setup_min "cycle-${i}-setup"
  assert_setup_state
done
ok "cycle loops passed"

step "default profile setup check"
if [ "$RUN_DEFAULT_SETUP" = "1" ]; then
  for i in $(seq 1 "$DEFAULT_SETUP_LOOPS"); do
    run_setup_default "setup-default-${i}"
    assert_setup_state
  done
  ok "default profile setup passed"
else
  warn "skipped default profile setup check"
fi

if [ "$RESTORE_AT_END" = "1" ]; then
  run_setup_min "final-restore"
  assert_setup_state
  ok "final restore complete"
else
  warn "final restore skipped by config"
fi

log "summary"
printf '  include.path count: %s\n' "$(count_git_include)"
printf '  helix link        : %s\n' "$(dot_resolve_path "$HOME/.config/helix")"
printf '  lazygit link      : %s\n' "$(dot_resolve_path "$HOME/.config/lazygit")"
printf '  tmux link         : %s\n' "$(dot_resolve_path "$HOME/.tmux.conf")"
printf '  zsh shared link   : %s\n' "$(dot_resolve_path "$HOME/.zsh.shared.zsh")"
printf '  dot-difft link    : %s\n' "$(dot_resolve_path "$HOME/.local/bin/dot-difft")"
printf '  dot-difft-pager   : %s\n' "$(dot_resolve_path "$HOME/.local/bin/dot-difft-pager")"
printf '  dot-lazygit-theme : %s\n' "$(dot_resolve_path "$HOME/.local/bin/dot-lazygit-theme")"
printf '  setup manifest    : %s\n' "$MANIFEST_FILE"
printf '  logs              : %s\n' "$LOG_DIR"
ok "verification completed"
