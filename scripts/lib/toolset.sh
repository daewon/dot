#!/usr/bin/env bash
# Shared tool definitions for setup/cleanup/verify.
# shellcheck disable=SC2034

DOT_REQUIRED_MISE_TOOLS=(
  node@24.13.1
  python@3.12.12
  github:tmux/tmux-builds@3.6a
  lazygit@0.59.0
  uv@0.10.4
  coursier@2.1.25-M23
  fzf@0.68.0
  rg@15.1.0
  fd@10.3.0
  bat@0.26.1
  jq@1.8.1
  yq@4.52.4
  shellcheck@0.11.0
  helix@25.07.1
  marksman@2026-02-08
  difftastic@0.67.0
  npm:vscode-langservers-extracted@4.10.0
  npm:yaml-language-server@1.20.0
  npm:prettier@3.8.1
)

DOT_OPTIONAL_MISE_TOOLS=(
  java@temurin-21.0.10+7.0.LTS
  asdf:mise-plugins/mise-mill@1.1.2
  npm:pyright@1.1.408
  npm:typescript-language-server@5.1.3
  npm:typescript@5.9.3
  npm:dmux@5.2.0
  # Intentionally unpinned to follow latest Codex CLI builds.
  npm:@openai/codex
)

DOT_REQUIRED_CLI_COMMANDS=(
  node
  python
  tmux
  lazygit
  uv
  cs
  fzf
  rg
  fd
  bat
  jq
  yq
  shellcheck
  hx
  marksman
  difft
)

DOT_OPTIONAL_CLI_COMMANDS=(
  java
  mill
  pyright-langserver
  typescript-language-server
  tsc
  dmux
  codex
  vim
)

DOT_REPO_SYMLINK_REL_ENTRIES=(
  ".config/helix"$'\t'"config/helix"
  ".config/lazygit"$'\t'"config/lazygit"
  ".tmux.conf"$'\t'"config/tmux.conf.user"
  ".zsh.shared.zsh"$'\t'"config/zsh.shared.zsh"
  ".zpreztorc"$'\t'"config/zpreztorc"
  ".local/bin/dot-difft"$'\t'"scripts/difft-external.sh"
  ".local/bin/dot-difft-pager"$'\t'"scripts/difft-pager.sh"
  ".local/bin/dot-lazygit-theme"$'\t'"scripts/lazygit-theme.sh"
  ".local/bin/sclip"$'\t'"scripts/sclip.sh"
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
  local rel_link=""
  local rel_target=""
  local entry=""
  for entry in "${DOT_REPO_SYMLINK_REL_ENTRIES[@]}"; do
    rel_link="${entry%%$'\t'*}"
    rel_target="${entry#*$'\t'}"
    printf '%s\t%s\n' "$HOME/$rel_link" "$repo_root/$rel_target"
  done
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

dot_print_optional_managed_git_clones() {
  local home_dir="${1:-$HOME}"
  printf '%s\t%s\n' "$home_dir/.vim_runtime" "amix/vimrc"
}

dot_print_optional_managed_file_markers() {
  local home_dir="${1:-$HOME}"
  printf '%s\t%s\n' "$home_dir/.vimrc" "dot-setup managed vimrc"
}
