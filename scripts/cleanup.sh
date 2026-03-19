#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=scripts/lib/toolset.sh
source "$REPO_ROOT/scripts/lib/toolset.sh"
# shellcheck source=scripts/lib/scriptlib.sh
source "$REPO_ROOT/scripts/lib/scriptlib.sh"
# shellcheck source=scripts/lib/cleanup_runtime.sh
source "$REPO_ROOT/scripts/lib/cleanup_runtime.sh"

TOTAL_STEPS=5
STEP=0
FAILED_STEP=0

DRY_RUN="${DRY_RUN:-0}"                         # 1 or 0
REMOVE_GLOBAL_TOOLS="${REMOVE_GLOBAL_TOOLS-}"   # 1 or 0 (resolved later)
FORCE_REMOVE_ZSHRC="${FORCE_REMOVE_ZSHRC:-0}"   # 1 or 0
MANIFEST_FILE="$(dot_setup_manifest_file)"
MANIFEST_DIR="$(dirname "$MANIFEST_FILE")"
MANIFEST_USED=0
MANIFEST_VERSION="1"
GIT_SHARED_INCLUDE_PATH="$(dot_git_shared_include_path "$REPO_ROOT")"

on_error() {
  FAILED_STEP="$STEP"
  err "failed at step ${FAILED_STEP}"
}
trap on_error ERR

parse_cleanup_args "$@"

resolve_remove_global_tools

dot_validate_bool_flags_01 DRY_RUN REMOVE_GLOBAL_TOOLS FORCE_REMOVE_ZSHRC || exit 2

step "preflight"
cleanup_preflight

step "remove zsh/tmux/dotfile/editor artifacts"
cleanup_remove_managed_artifacts

step "remove prezto and tmux plugin manager"
cleanup_remove_clone_artifacts

step "remove git include and optional global tool entries"
cleanup_remove_git_and_tool_entries

step "summary"
cleanup_print_summary

ok "cleanup completed"
