#!/usr/bin/env bash
# Shared tool definitions for setup/cleanup/verify.
# shellcheck disable=SC2034

DOT_REQUIRED_MISE_TOOLS=(
  fzf@latest
  rg@latest
  fd@latest
  bat@latest
  jq@latest
  yq@latest
  shellcheck@latest
  black@latest
  ruff@latest
  npm:pyright@latest
  npm:vscode-langservers-extracted@latest
  npm:yaml-language-server@latest
  npm:prettier@latest
)

DOT_OPTIONAL_MISE_TOOLS=(
  marksman@latest
  yazi@latest
  difftastic@latest
  npm:typescript-language-server@latest
  npm:typescript@latest
  npm:dmux@latest
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

DOT_PREZTO_RUNCOMS=(
  zlogin
  zlogout
  zprofile
  zshenv
  zpreztorc
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
  printf '%s\t%s\n' "$HOME/.config/helix" "$repo_root/helix"
  printf '%s\t%s\n' "$HOME/.config/lazygit" "$repo_root/lazygit"
  printf '%s\t%s\n' "$HOME/.tmux.conf" "$repo_root/tmux.conf.user"
  printf '%s\t%s\n' "$HOME/.zsh.shared.zsh" "$repo_root/zsh.shared.zsh"
  printf '%s\t%s\n' "$HOME/.local/bin/dot-difft" "$repo_root/difft-external.sh"
  printf '%s\t%s\n' "$HOME/.local/bin/dot-difft-pager" "$repo_root/difft-pager.sh"
  printf '%s\t%s\n' "$HOME/.local/bin/dot-lazygit-theme" "$repo_root/lazygit-theme.sh"
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
