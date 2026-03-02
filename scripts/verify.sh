#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=scripts/lib/toolset.sh
source "$REPO_ROOT/scripts/lib/toolset.sh"
# shellcheck source=scripts/lib/scriptlib.sh
source "$REPO_ROOT/scripts/lib/scriptlib.sh"
# shellcheck source=scripts/lib/verify_assert.sh
source "$REPO_ROOT/scripts/lib/verify_assert.sh"
# shellcheck source=scripts/lib/verify_runner.sh
source "$REPO_ROOT/scripts/lib/verify_runner.sh"
# shellcheck source=scripts/lib/verify_contract.sh
source "$REPO_ROOT/scripts/lib/verify_contract.sh"
# shellcheck source=scripts/lib/verify_options.sh
source "$REPO_ROOT/scripts/lib/verify_options.sh"
# shellcheck source=scripts/lib/verify_preflight.sh
source "$REPO_ROOT/scripts/lib/verify_preflight.sh"

TOTAL_STEPS=8
STEP=0
FAILED_STEP=0

VERIFY_PROFILE="${VERIFY_PROFILE:-full}" # fast | full | stress
SETUP_ONLY_LOOPS="${SETUP_ONLY_LOOPS:-}"
CYCLE_LOOPS="${CYCLE_LOOPS:-}"
RUN_DEFAULT_SETUP="${RUN_DEFAULT_SETUP:-}" # 1 or 0
DEFAULT_SETUP_LOOPS="${DEFAULT_SETUP_LOOPS:-}"
RESTORE_AT_END="${RESTORE_AT_END:-}" # 1 or 0
VERIFY_CLIPBOARD_RUNTIME="${VERIFY_CLIPBOARD_RUNTIME:-0}" # 1 or 0

LOG_DIR="${TMPDIR:-/tmp}/dot-verify-$(date +%Y%m%d-%H%M%S)"
MANIFEST_FILE="$(dot_setup_manifest_file)"
MANIFEST_VERSION="1"
GIT_SHARED_INCLUDE_PATH="$(dot_git_shared_include_path "$REPO_ROOT")"
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
  scripts/lib/setup_tmux.sh
  scripts/lib/setup_coursier.sh
  scripts/lib/setup_clipboard.sh
  scripts/lib/setup_state.sh
  scripts/lib/setup_vim.sh
  scripts/lib/setup_options.sh
  scripts/lib/verify_assert.sh
  scripts/lib/verify_runner.sh
  scripts/lib/verify_contract.sh
  scripts/lib/verify_options.sh
  scripts/lib/verify_preflight.sh
  scripts/lib/toolset.sh
  scripts/lib/scriptlib.sh
  scripts/difft-external.sh
  scripts/difft-pager.sh
  scripts/lazygit-theme.sh
  scripts/sclip.sh
)

log() { printf '[verify] %s\n' "$*"; }

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

parse_verify_args "$@"
validate_verify_config

step "preflight"
verify_preflight_checks || exit 1

step "syntax check"
verify_syntax_checks || exit 1

step "contract guardrails"
run_contract_guardrails

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
printf '  sclip link        : %s\n' "$(dot_resolve_path "$HOME/.local/bin/sclip")"
printf '  setup manifest    : %s\n' "$MANIFEST_FILE"
printf '  logs              : %s\n' "$LOG_DIR"
ok "verification completed"
