#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=scripts/lib/toolset.sh
source "$REPO_ROOT/scripts/lib/toolset.sh"
# shellcheck source=scripts/lib/scriptlib.sh
source "$REPO_ROOT/scripts/lib/scriptlib.sh"
# shellcheck source=scripts/lib/setup_clipboard.sh
source "$REPO_ROOT/scripts/lib/setup_clipboard.sh"
# shellcheck source=scripts/lib/setup_tmux.sh
source "$REPO_ROOT/scripts/lib/setup_tmux.sh"
# shellcheck source=scripts/lib/setup_coursier.sh
source "$REPO_ROOT/scripts/lib/setup_coursier.sh"
# shellcheck source=scripts/lib/setup_scala.sh
source "$REPO_ROOT/scripts/lib/setup_scala.sh"
# shellcheck source=scripts/lib/setup_state.sh
source "$REPO_ROOT/scripts/lib/setup_state.sh"
# shellcheck source=scripts/lib/setup_vim.sh
source "$REPO_ROOT/scripts/lib/setup_vim.sh"
# shellcheck source=scripts/lib/setup_options.sh
source "$REPO_ROOT/scripts/lib/setup_options.sh"
# shellcheck source=scripts/lib/setup_runtime.sh
source "$REPO_ROOT/scripts/lib/setup_runtime.sh"

TOTAL_STEPS=10
STEP=0
FAILED_STEP=0

INSTALL_OPTIONAL_TOOLS="${INSTALL_OPTIONAL_TOOLS-}"   # 1 or 0 (resolved later)
SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL-}"             # 1 or 0 (resolved later)
INSTALL_TMUX_PLUGINS="${INSTALL_TMUX_PLUGINS:-1}"     # 1 or 0
UPDATE_PACKAGES="${UPDATE_PACKAGES:-0}"               # 1 or 0
DRY_RUN="${DRY_RUN:-0}"                               # 1 or 0
MANIFEST_FILE="$(dot_setup_manifest_file)"
MANIFEST_DIR="$(dirname "$MANIFEST_FILE")"
MANIFEST_VERSION="1"
GIT_SHARED_INCLUDE_PATH="$(dot_git_shared_include_path "$REPO_ROOT")"
TS="$(date +%Y%m%d-%H%M%S)"
APT_UPDATED=0
DOT_GH_CREDENTIAL_HOSTS=(
  "https://github.com"
  "https://gist.github.com"
)
declare -a MANIFEST_ENTRIES=()

on_error() {
  FAILED_STEP="$STEP"
  err "failed at step ${FAILED_STEP}"
}
trap on_error ERR

parse_setup_args "$@"

resolve_install_optional_tools
resolve_set_default_shell

dot_validate_bool_flags_01 INSTALL_OPTIONAL_TOOLS INSTALL_TMUX_PLUGINS SET_DEFAULT_SHELL UPDATE_PACKAGES DRY_RUN || exit 2

step "preflight"
setup_preflight

step "install global required tools (CLI/runtime/LSP/formatter)"
setup_required_tools

step "install optional tools"
setup_optional_tools

step "ensure zsh is installed"
setup_ensure_zsh_installed

step "install prezto"
setup_install_prezto

step "link prezto runcoms and write ~/.zshrc wrapper"
setup_configure_zsh_runcoms

step "link dotfiles from repo"
setup_link_repo_dotfiles

step "configure git include and tmux plugins"
setup_configure_git_and_tmux

step "final check and optional default shell switch"
setup_finalize_default_shell

step "write setup manifest"
write_setup_manifest

log "summary"
setup_print_summary

ok "setup completed"
