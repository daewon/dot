#!/usr/bin/env bash
# Shared tool definitions for setup/cleanup/verify.
# shellcheck disable=SC2034

DOT_REQUIRED_MISE_TOOLS=(
  fzf@0.68.0
  rg@15.1.0
  fd@10.3.0
  bat@0.26.1
  jq@1.8.1
  yq@4.52.4
  shellcheck@0.11.0
  black@26.1.0
  ruff@0.15.2
  npm:pyright@1.1.408
  npm:vscode-langservers-extracted@4.10.0
  npm:yaml-language-server@1.20.0
  npm:prettier@3.8.1
)

DOT_OPTIONAL_MISE_TOOLS=(
  marksman@2026-02-08
  yazi@26.1.22
  difftastic@0.67.0
  npm:typescript-language-server@5.1.3
  npm:typescript@5.9.3
  npm:dmux@5.2.0
)

DOT_REQUIRED_CLI_COMMANDS=(
  fzf
  rg
  fd
  bat
  jq
  yq
  shellcheck
)

DOT_OPTIONAL_CLI_COMMANDS=(
  marksman
  yazi
  difft
  typescript-language-server
  tsc
  dmux
)

DOT_PREZTO_RUNCOMS=(
  zlogin
  zlogout
  zprofile
  zshenv
)

dot_strip_tool_version() {
  local tool="$1"
  printf '%s\n' "${tool%@*}"
}

dot_state_dir() {
  printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/dot"
}

dot_setup_manifest_file() {
  printf '%s/setup-manifest.v1.tsv\n' "$(dot_state_dir)"
}

dot_print_repo_symlink_entries() {
  local repo_root="$1"
  printf '%s\t%s\n' "$HOME/.config/helix" "$repo_root/config/helix"
  printf '%s\t%s\n' "$HOME/.config/lazygit" "$repo_root/config/lazygit"
  printf '%s\t%s\n' "$HOME/.tmux.conf" "$repo_root/config/tmux.conf.user"
  printf '%s\t%s\n' "$HOME/.zsh.shared.zsh" "$repo_root/config/zsh.shared.zsh"
  printf '%s\t%s\n' "$HOME/.zpreztorc" "$repo_root/config/zpreztorc"
  printf '%s\t%s\n' "$HOME/.local/bin/dot-difft" "$repo_root/scripts/difft-external.sh"
  printf '%s\t%s\n' "$HOME/.local/bin/dot-difft-pager" "$repo_root/scripts/difft-pager.sh"
  printf '%s\t%s\n' "$HOME/.local/bin/dot-lazygit-theme" "$repo_root/scripts/lazygit-theme.sh"
}

dot_print_prezto_runcom_symlink_entries() {
  local home_dir="${1:-$HOME}"
  local rc=""
  for rc in "${DOT_PREZTO_RUNCOMS[@]}"; do
    printf '%s\t%s\n' "$home_dir/.$rc" "$home_dir/.zprezto/runcoms/$rc"
  done
}

dot_print_managed_git_clones() {
  local home_dir="${1:-$HOME}"
  printf '%s\t%s\n' "$home_dir/.zprezto" "sorin-ionescu/prezto"
  printf '%s\t%s\n' "$home_dir/.tmux/plugins/tpm" "tmux-plugins/tpm"
}
