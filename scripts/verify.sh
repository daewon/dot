#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=scripts/lib/toolset.sh
source "$REPO_ROOT/scripts/lib/toolset.sh"
# shellcheck source=scripts/lib/scriptlib.sh
source "$REPO_ROOT/scripts/lib/scriptlib.sh"

TOTAL_STEPS=8
STEP=0
FAILED_STEP=0

VERIFY_PROFILE="${VERIFY_PROFILE:-full}" # fast | full | stress
SETUP_ONLY_LOOPS="${SETUP_ONLY_LOOPS:-}"
CYCLE_LOOPS="${CYCLE_LOOPS:-}"
RUN_DEFAULT_SETUP="${RUN_DEFAULT_SETUP:-}" # 1 or 0
DEFAULT_SETUP_LOOPS="${DEFAULT_SETUP_LOOPS:-}"
RESTORE_AT_END="${RESTORE_AT_END:-}" # 1 or 0

LOG_DIR="${TMPDIR:-/tmp}/dot-verify-$(date +%Y%m%d-%H%M%S)"
MANIFEST_FILE="$(dot_setup_manifest_file)"
MANIFEST_VERSION="1"
CONTRACT_TMP=""

VERIFY_REQUIRED_CMDS=(
  bash
  git
  grep
  find
  wc
  seq
  mktemp
  sed
  awk
)

VERIFY_LINT_TARGETS=(
  setup.sh
  cleanup.sh
  verify.sh
  scripts/setup.sh
  scripts/cleanup.sh
  scripts/verify.sh
  scripts/lib/toolset.sh
  scripts/lib/scriptlib.sh
  scripts/difft-external.sh
  scripts/difft-pager.sh
  scripts/lazygit-theme.sh
)

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
  --profile NAME         Verification profile: fast | full | stress (default: full)
  --setup-only-loops N   Repeat setup(min profile) N times
  --cycle-loops N        Repeat cleanup->setup cycle N times
  --skip-default-setup   Skip default-profile setup verification
  --default-loops N      Repeat default-profile setup N times
  --no-restore           Skip final restore setup
  --help, -h             Show this help

Environment flags (same meaning as options):
  VERIFY_PROFILE=full
  SETUP_ONLY_LOOPS=<int>=profile default
  CYCLE_LOOPS=<int>=profile default
  RUN_DEFAULT_SETUP=0|1=profile default
  DEFAULT_SETUP_LOOPS=<int>=profile default
  RESTORE_AT_END=0|1=profile default
EOF
}

apply_profile_defaults() {
  case "$VERIFY_PROFILE" in
    fast)
      : "${SETUP_ONLY_LOOPS:=1}"
      : "${CYCLE_LOOPS:=1}"
      : "${RUN_DEFAULT_SETUP:=0}"
      : "${DEFAULT_SETUP_LOOPS:=0}"
      : "${RESTORE_AT_END:=1}"
      ;;
    full)
      : "${SETUP_ONLY_LOOPS:=2}"
      : "${CYCLE_LOOPS:=2}"
      : "${RUN_DEFAULT_SETUP:=1}"
      : "${DEFAULT_SETUP_LOOPS:=1}"
      : "${RESTORE_AT_END:=1}"
      ;;
    stress)
      : "${SETUP_ONLY_LOOPS:=4}"
      : "${CYCLE_LOOPS:=4}"
      : "${RUN_DEFAULT_SETUP:=1}"
      : "${DEFAULT_SETUP_LOOPS:=2}"
      : "${RESTORE_AT_END:=1}"
      ;;
    *)
      err "invalid profile: $VERIFY_PROFILE (expected: fast|full|stress)"
      exit 2
      ;;
  esac
}

on_error() {
  FAILED_STEP="$STEP"
  err "failed at step ${FAILED_STEP}"
  err "see logs in: $LOG_DIR"
}
trap on_error ERR

cleanup_tmp_artifacts() {
  if [ -n "${CONTRACT_TMP:-}" ] && [ -d "$CONTRACT_TMP" ]; then
    rm -rf "$CONTRACT_TMP"
  fi
}
trap cleanup_tmp_artifacts EXIT

count_matches() {
  local pattern="$1"
  local file="$2"
  local c=""
  c="$(grep -c "$pattern" "$file" 2>/dev/null || true)"
  printf '%s' "${c:-0}"
}

count_git_include() {
  local c=""
  c="$(git config --global --get-all include.path 2>/dev/null | grep -Fxc "$REPO_ROOT/config/gitconfig.shared" || true)"
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
  local include_optional="${1:-0}"
  local include_count=""
  local resolved_link=""
  local manifest_line=""
  local link_path=""
  local link_target=""
  local clone_path=""
  local clone_origin=""
  local optional_file=""
  local optional_marker=""
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
  manifest_line="version"$'\t'"$MANIFEST_VERSION"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest version mismatch"; return 1; }
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
  manifest_line="git_include_path"$'\t'"$REPO_ROOT/config/gitconfig.shared"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing git include entry"; return 1; }
  for cmd in "${DOT_REQUIRED_CLI_COMMANDS[@]}"; do
    tool_available "$cmd" || { err "command not found after setup: $cmd"; return 1; }
  done
  if [ "$include_optional" = "1" ]; then
    for cmd in "${DOT_OPTIONAL_CLI_COMMANDS[@]}"; do
      tool_available "$cmd" || { err "optional command not found after default setup: $cmd"; return 1; }
    done
    while IFS=$'\t' read -r clone_path clone_origin; do
      manifest_line="git_clone_origin"$'\t'"$clone_path"$'\t'"$clone_origin"
      grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing optional clone entry: $clone_path"; return 1; }
    done < <(dot_print_optional_managed_git_clones "$HOME")
    while IFS=$'\t' read -r optional_file optional_marker; do
      manifest_line="managed_file_contains"$'\t'"$optional_file"$'\t'"$optional_marker"
      grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing optional managed file entry: $optional_file"; return 1; }
    done < <(dot_print_optional_managed_file_markers "$HOME")
  fi

  ok "state check passed (include=1, links aligned, optional=${include_optional})"
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

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      [ "$#" -ge 2 ] || { err "missing value for --profile"; exit 2; }
      VERIFY_PROFILE="$2"
      shift
      ;;
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

apply_profile_defaults
dot_validate_bool_flags_01 RUN_DEFAULT_SETUP RESTORE_AT_END || exit 2
dot_validate_nonneg_int_flags SETUP_ONLY_LOOPS CYCLE_LOOPS DEFAULT_SETUP_LOOPS || exit 2

step "preflight"
for cmd in "${VERIFY_REQUIRED_CMDS[@]}"; do
  if ! dot_require_cmd "$cmd"; then
    err "required command not found: $cmd"
    exit 1
  fi
done
for file in setup.sh cleanup.sh scripts/setup.sh scripts/cleanup.sh; do
  [ -x "$REPO_ROOT/$file" ] || { err "$file is not executable"; exit 1; }
done
mkdir -p "$LOG_DIR"
ok "repo: $REPO_ROOT"
ok "logs: $LOG_DIR"
ok "config: profile=$VERIFY_PROFILE setup_only=$SETUP_ONLY_LOOPS cycle=$CYCLE_LOOPS default=$RUN_DEFAULT_SETUP default_loops=$DEFAULT_SETUP_LOOPS restore=$RESTORE_AT_END"

step "syntax check"
for file in "${VERIFY_LINT_TARGETS[@]}"; do
  bash -n "$REPO_ROOT/$file"
done
SHELLCHECK_BIN=""
SHELLCHECK_BIN="$(dot_find_cmd shellcheck 2>/dev/null || true)"
if [ -n "${SHELLCHECK_BIN:-}" ]; then
  SHELLCHECK_TARGETS=()
  for file in "${VERIFY_LINT_TARGETS[@]}"; do
    SHELLCHECK_TARGETS+=("$REPO_ROOT/$file")
  done
  "$SHELLCHECK_BIN" -x "${SHELLCHECK_TARGETS[@]}"
  ok "shellcheck passed"
else
  warn "shellcheck not found; skipped static shell analysis"
fi
ok "bash syntax valid"

step "contract guardrails"
CONTRACT_TMP="$(mktemp -d "${TMPDIR:-/tmp}/dot-verify-contract.XXXXXX")"
mkdir -p "$CONTRACT_TMP/state-unknown/dot"
cat >"$CONTRACT_TMP/state-unknown/dot/setup-manifest.v1.tsv" <<EOF
version	1
repo_root	$REPO_ROOT
unknown_kind	/tmp/foo	bar
EOF
mkdir -p "$CONTRACT_TMP/state-version/dot"
cat >"$CONTRACT_TMP/state-version/dot/setup-manifest.v1.tsv" <<EOF
version	2
repo_root	$REPO_ROOT
EOF
mkdir -p "$CONTRACT_TMP/state-malformed/dot"
cat >"$CONTRACT_TMP/state-malformed/dot/setup-manifest.v1.tsv" <<EOF
version	1
repo_root	$REPO_ROOT
symlink	/tmp/foo
EOF
run_expect_failure \
  "setup-invalid-bool-flag" 2 "INSTALL_OPTIONAL_TOOLS must be 0 or 1" \
  env INSTALL_OPTIONAL_TOOLS=2 "$REPO_ROOT/setup.sh" --dry-run
run_expect_failure \
  "cleanup-invalid-bool-flag" 2 "REMOVE_GLOBAL_TOOLS must be 0 or 1" \
  env REMOVE_GLOBAL_TOOLS=2 "$REPO_ROOT/cleanup.sh" --dry-run
run_expect_failure \
  "cleanup-malformed-manifest-row" 1 "invalid setup manifest row" \
  env XDG_STATE_HOME="$CONTRACT_TMP/state-malformed" "$REPO_ROOT/cleanup.sh" --dry-run
run_expect_failure \
  "cleanup-unknown-manifest-kind" 1 "unknown setup manifest entry" \
  env XDG_STATE_HOME="$CONTRACT_TMP/state-unknown" "$REPO_ROOT/cleanup.sh" --dry-run
run_with_log \
  "cleanup-manifest-version-fallback" \
  env XDG_STATE_HOME="$CONTRACT_TMP/state-version" "$REPO_ROOT/cleanup.sh" --dry-run
grep -Fq "falling back to static cleanup targets" "$LOG_DIR/cleanup-manifest-version-fallback.log" \
  || { err "cleanup-manifest-version-fallback: expected fallback message"; exit 1; }
ok "cleanup-manifest-version-fallback: fallback path confirmed"
cleanup_tmp_artifacts
CONTRACT_TMP=""

step "dry-run smoke"
run_with_log "setup-dry-run" "$REPO_ROOT/setup.sh" --dry-run
run_with_log "cleanup-dry-run" "$REPO_ROOT/cleanup.sh" --dry-run

step "baseline setup(min profile)"
run_setup_min "setup-baseline"
assert_setup_state 0

step "setup-only idempotency"
backup_before="$(count_backup_files)"
for i in $(seq 1 "$SETUP_ONLY_LOOPS"); do
  run_setup_min "setup-only-${i}"
  assert_setup_state 0
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
  assert_setup_state 0
done
ok "cycle loops passed"

step "default profile setup check"
if [ "$RUN_DEFAULT_SETUP" = "1" ]; then
  for i in $(seq 1 "$DEFAULT_SETUP_LOOPS"); do
    run_setup_default "setup-default-${i}"
    assert_setup_state 1
  done
  ok "default profile setup passed"
else
  warn "skipped default profile setup check"
fi

if [ "$RESTORE_AT_END" = "1" ]; then
  run_cleanup "final-restore-cleanup" 1
  run_setup_min "final-restore"
  assert_setup_state 0
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
