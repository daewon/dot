#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=scripts/lib/toolset.sh
source "$REPO_ROOT/scripts/lib/toolset.sh"
# shellcheck source=scripts/lib/scriptlib.sh
source "$REPO_ROOT/scripts/lib/scriptlib.sh"

TOTAL_STEPS=10
STEP=0
FAILED_STEP=0

INSTALL_OPTIONAL_TOOLS="${INSTALL_OPTIONAL_TOOLS-}"   # 1 or 0 (resolved later)
SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL:-0}"           # 1 or 0
INSTALL_TMUX_PLUGINS="${INSTALL_TMUX_PLUGINS:-1}"     # 1 or 0
DRY_RUN="${DRY_RUN:-0}"                               # 1 or 0
MANIFEST_FILE="$(dot_setup_manifest_file)"
MANIFEST_DIR="$(dirname "$MANIFEST_FILE")"
MANIFEST_VERSION="1"
GIT_SHARED_INCLUDE_PATH="$(dot_git_shared_include_path "$REPO_ROOT")"
TS="$(date +%Y%m%d-%H%M%S)"
APT_UPDATED=0
declare -a MANIFEST_ENTRIES=()

log() {
  printf '[setup] %s\n' "$*"
}

print_mise_install_hint() {
  warn "install mise, reload your shell, then re-run setup:"
  cat <<'EOF'
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    exec "$SHELL" -l
EOF
}

print_mise_permission_hint() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/mise"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mise"
  local primary_group=""

  primary_group="$(id -gn 2>/dev/null || true)"
  if [ -z "$primary_group" ]; then
    primary_group="$USER"
  fi

  warn "mise global install needs writable directories:"
  printf '    %s\n' "$config_dir" "$data_dir" "$state_dir" "$cache_dir"
  warn "if any path is root-owned, fix ownership then re-run setup:"
  cat <<EOF
    sudo chown -R "$USER:$primary_group" \
      "$config_dir" \
      "$data_dir" \
      "$state_dir" \
      "$cache_dir"
EOF
}

print_tmux_backend_hint() {
  local tmux_tool=""
  tmux_tool="$(dot_preferred_tmux_tool)"
  warn "legacy tmux backend detected (source build path)"
  cat <<EOF
    prefer prebuilt backend:
      mise install $tmux_tool
      mise use -g $tmux_tool
EOF
}

dot_preferred_tmux_tool() {
  local tool=""
  for tool in "${DOT_REQUIRED_MISE_TOOLS[@]}"; do
    case "$tool" in
      github:tmux/tmux-builds@*)
        printf '%s\n' "$tool"
        return 0
        ;;
    esac
  done
  printf '%s\n' "github:tmux/tmux-builds@3.6a"
}

install_system_package() {
  local apt_package="$1"
  local brew_package="${2:-$1}"
  local label="${3:-$1}"
  local -a sudo_cmd=(sudo)

  if command -v apt-get >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then
      if [ "$APT_UPDATED" = "0" ]; then
        run apt-get update
        APT_UPDATED=1
      fi
      run apt-get install -y "$apt_package"
    else
      if ! command -v sudo >/dev/null 2>&1; then
        err "$label install requires sudo but sudo is unavailable"
        return 1
      fi
      if ! dot_is_interactive_tty; then
        sudo_cmd=(sudo -n)
        if [ "$DRY_RUN" != "1" ] && ! sudo -n true >/dev/null 2>&1; then
          err "$label install needs passwordless sudo in non-interactive mode (sudo -n)"
          err "install $label manually or re-run setup in an interactive terminal"
          return 1
        fi
      fi
      if [ "$APT_UPDATED" = "0" ]; then
        run "${sudo_cmd[@]}" apt-get update
        APT_UPDATED=1
      fi
      run "${sudo_cmd[@]}" apt-get install -y "$apt_package"
    fi
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    run brew install "$brew_package"
    return 0
  fi

  err "no supported package manager for '$label' (apt-get/brew)"
  return 1
}

ensure_mise_global_prerequisites_or_exit() {
  if ! ensure_mise_global_dirs_writable; then
    print_mise_permission_hint
    exit 1
  fi
}

ensure_writable_dir() {
  local dir="$1"
  local label="$2"
  local parent=""

  if [ -e "$dir" ] && [ ! -d "$dir" ]; then
    err "$label exists but is not a directory: $dir"
    return 1
  fi

  if [ "$DRY_RUN" = "1" ]; then
    if [ -d "$dir" ]; then
      if [ ! -w "$dir" ]; then
        err "$label is not writable: $dir"
        return 1
      fi
      return 0
    fi
    parent="$(dirname "$dir")"
    if [ -e "$parent" ] && [ ! -w "$parent" ]; then
      err "$label parent is not writable: $parent"
      return 1
    fi
    return 0
  fi

  if ! mkdir -p "$dir"; then
    err "$label could not be created: $dir"
    return 1
  fi
  if [ ! -w "$dir" ]; then
    err "$label is not writable: $dir"
    return 1
  fi
}

ensure_mise_global_dirs_writable() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/mise"
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/mise"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

  ensure_writable_dir "$config_dir" "mise config directory" || return 1
  ensure_writable_dir "$data_dir" "mise data directory" || return 1
  ensure_writable_dir "$state_dir" "mise state directory" || return 1
  ensure_writable_dir "$cache_dir" "mise cache directory" || return 1
}

run_mise_use_global() {
  local output_file=""

  if [ "$DRY_RUN" = "1" ]; then
    run mise use -g "$@"
    return
  fi

  output_file="$(mktemp)"
  if mise use -g "$@" > >(tee -a "$output_file") 2> >(tee -a "$output_file" >&2); then
    rm -f "$output_file"
    return 0
  fi

  if grep -Eiq 'permission denied|os error 13' "$output_file"; then
    print_mise_permission_hint
  fi
  if grep -Eiq 'asdf-tmux|curses not found|ncurses|Failed to install asdf:tmux' "$output_file"; then
    print_tmux_backend_hint
  fi
  rm -f "$output_file"
  return 1
}

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--dry-run|-n]

Options:
  --dry-run, -n  Show what would run without applying changes
  --help, -h     Show this help

Env flags:
  INSTALL_OPTIONAL_TOOLS=0|1   Install optional tools
                               (Python/Scala/TypeScript/dmux + metals + vim runtime)
                               (default: prompt on interactive TTY, otherwise 0)
  INSTALL_TMUX_PLUGINS=0|1     Install tmux plugins with TPM (default: 1)
  SET_DEFAULT_SHELL=0|1        Try switching login shell to zsh (default: 0)
EOF
}

on_error() {
  FAILED_STEP="$STEP"
  err "failed at step ${FAILED_STEP}"
}
trap on_error ERR

manifest_add_entry() {
  local kind="$1"
  local path="$2"
  local meta="${3:-}"
  if [ -n "$meta" ]; then
    MANIFEST_ENTRIES+=("$kind"$'\t'"$path"$'\t'"$meta")
  else
    MANIFEST_ENTRIES+=("$kind"$'\t'"$path")
  fi
}

write_setup_manifest() {
  local tmp=""
  local line=""
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry-run] write %s\n' "$MANIFEST_FILE"
    ok "would update setup manifest"
    return
  fi
  mkdir -p "$MANIFEST_DIR"
  tmp="${MANIFEST_FILE}.tmp.$$"
  {
    printf 'version\t%s\n' "$MANIFEST_VERSION"
    printf 'repo_root\t%s\n' "$REPO_ROOT"
    for line in "${MANIFEST_ENTRIES[@]}"; do
      printf '%s\n' "$line"
    done
  } >"$tmp"
  mv "$tmp" "$MANIFEST_FILE"
  ok "setup manifest updated: $MANIFEST_FILE"
}

backup_if_unmanaged_path() {
  local path="$1"
  local expected_target="$2"
  local ts="$3"
  if [ -L "$path" ]; then
    if dot_is_link_target "$path" "$expected_target"; then
      return
    fi
    backup_path "$path" "$ts"
    return
  fi
  if [ -e "$path" ]; then
    backup_path "$path" "$ts"
  fi
}

backup_path() {
  local path="$1"
  local ts="${2:-$TS}"
  if [ -e "$path" ] || [ -L "$path" ]; then
    run mv "$path" "${path}.bak.${ts}"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would back up $path -> ${path}.bak.${ts}"
    else
      ok "backed up $path -> ${path}.bak.${ts}"
    fi
  fi
}

ensure_managed_clone() {
  local clone_path="$1"
  local clone_url="$2"
  local origin_snippet="$3"
  local label="$4"
  local recursive="$5"
  local required_path="${6:-}"
  local origin=""
  local needs_clone=1

  if [ -d "$clone_path/.git" ]; then
    origin="$(git -C "$clone_path" remote get-url origin 2>/dev/null || true)"
    if printf '%s' "$origin" | grep -Fq "$origin_snippet"; then
      if [ -n "$required_path" ] && [ ! -e "$clone_path/$required_path" ]; then
        warn "$label looks incomplete ($required_path missing); backing up before re-clone"
        backup_path "$clone_path"
      else
        ok "$label already present"
        needs_clone=0
      fi
    else
      warn "$label origin mismatch: ${origin:-unknown}; backing up before re-clone"
      backup_path "$clone_path"
    fi
  elif [ -e "$clone_path" ] || [ -L "$clone_path" ]; then
    warn "$label path exists but is not a managed clone; backing up before clone"
    backup_path "$clone_path"
  fi

  if [ "$needs_clone" = "1" ]; then
    run mkdir -p "$(dirname "$clone_path")"
    if [ "$recursive" = "1" ]; then
      run git clone --recursive "$clone_url" "$clone_path"
    else
      run git clone "$clone_url" "$clone_path"
    fi
    if [ "$DRY_RUN" = "1" ]; then
      ok "would clone $label"
    else
      ok "$label cloned"
    fi
  fi
}

ensure_optional_vim_binary() {
  local vim_bin=""
  if vim_bin="$(dot_find_cmd vim 2>/dev/null)"; then
    ok "vim already installed: $vim_bin"
    return
  fi

  if ! install_system_package vim vim "vim"; then
    err "vim not found and automatic install failed; install vim manually or run with INSTALL_OPTIONAL_TOOLS=0"
    exit 1
  fi
  if [ "$DRY_RUN" = "1" ]; then
    ok "vim install command prepared (dry-run)"
    return
  fi
  ok "vim installed via package manager"

  if vim_bin="$(dot_find_cmd vim 2>/dev/null)"; then
    ok "vim command available: $vim_bin"
  else
    err "vim install completed but command is still unavailable: vim"
    exit 1
  fi
}

ensure_optional_vim_runtime() {
  local clone_path=""
  local clone_origin=""
  local vimrc_path=""
  local vimrc_marker=""
  local python_bin=""

  while IFS=$'\t' read -r clone_path clone_origin; do
    ensure_managed_clone \
      "$clone_path" \
      "https://github.com/${clone_origin}.git" \
      "$clone_origin" \
      "vim runtime" \
      "0" \
      "vimrcs/basic.vim"
    manifest_add_entry "git_clone_origin" "$clone_path" "$clone_origin"
  done < <(dot_print_optional_managed_git_clones "$HOME")

  while IFS=$'\t' read -r vimrc_path vimrc_marker; do
    if [ -e "$vimrc_path" ] || [ -L "$vimrc_path" ]; then
      if [ ! -L "$vimrc_path" ] && grep -Fq "$vimrc_marker" "$vimrc_path" 2>/dev/null; then
        run rm -f "$vimrc_path"
        if [ "$DRY_RUN" = "1" ]; then
          ok "would replace managed $vimrc_path"
        else
          ok "replacing managed $vimrc_path"
        fi
      else
        backup_path "$vimrc_path" "$TS"
      fi
    fi
    if [ "$DRY_RUN" = "1" ]; then
      printf '  [dry-run] write %s\n' "$vimrc_path"
    else
cat >"$vimrc_path" <<'EOF'
" dot-setup managed vimrc (safe for cleanup.sh)
" Add your own customizations in ~/.vim_runtime/my_configs.vim

set runtimepath+=~/.vim_runtime

source ~/.vim_runtime/vimrcs/basic.vim
source ~/.vim_runtime/vimrcs/filetypes.vim
source ~/.vim_runtime/vimrcs/plugins_config.vim
source ~/.vim_runtime/vimrcs/extended.vim
try
  source ~/.vim_runtime/my_configs.vim
catch
endtry
EOF
    fi
    ok "vimrc configured: $vimrc_path"
    manifest_add_entry "managed_file_contains" "$vimrc_path" "$vimrc_marker"
  done < <(dot_print_optional_managed_file_markers "$HOME")

  if [ -f "$HOME/.vim_runtime/update_plugins.py" ]; then
    if python_bin="$(dot_find_cmd python3 2>/dev/null)"; then
      :
    elif python_bin="$(dot_find_cmd python 2>/dev/null)"; then
      :
    else
      warn "python not found; skipped vim plugin update"
      return
    fi
    if [ "$DRY_RUN" = "1" ]; then
      printf '  [dry-run] %q %q\n' "$python_bin" "$HOME/.vim_runtime/update_plugins.py"
      ok "vim plugins would be updated"
    else
      if "$python_bin" "$HOME/.vim_runtime/update_plugins.py"; then
        ok "vim plugins updated"
      else
        warn "vim plugin update failed; run manually: $python_bin $HOME/.vim_runtime/update_plugins.py"
      fi
    fi
  else
    warn "missing vim plugin updater: $HOME/.vim_runtime/update_plugins.py"
  fi
}

resolve_install_optional_tools() {
  local reply=""
  local selected_value=""

  if [ -n "$INSTALL_OPTIONAL_TOOLS" ]; then
    return
  fi

  if dot_is_interactive_tty; then
    printf '\n[setup] Install optional tools (Python/Scala/TypeScript/dmux + metals launcher + vim runtime)? [y/N]: '
    IFS= read -r reply || true
    if selected_value="$(dot_parse_yes_no_to_bool_01 "$reply")"; then
      INSTALL_OPTIONAL_TOOLS="$selected_value"
    else
      warn "invalid response '$reply'; defaulting to no"
      INSTALL_OPTIONAL_TOOLS=0
    fi
    ok "interactive selection: INSTALL_OPTIONAL_TOOLS=$INSTALL_OPTIONAL_TOOLS"
    return
  fi

  INSTALL_OPTIONAL_TOOLS=0
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
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

resolve_install_optional_tools

dot_validate_bool_flags_01 INSTALL_OPTIONAL_TOOLS INSTALL_TMUX_PLUGINS SET_DEFAULT_SHELL DRY_RUN || exit 2

step "preflight"
if ! dot_require_cmd git; then
  err "required command not found: git"
  exit 1
fi
if ! dot_require_cmd mise; then
  err "required command not found: mise"
  print_mise_install_hint
  exit 1
fi
ok "repo: $REPO_ROOT"
if [ "$DRY_RUN" = "1" ]; then
  warn "dry-run mode enabled (no files or settings will be changed)"
fi

step "install global required tools (CLI/runtime/LSP/formatter)"
ensure_mise_global_prerequisites_or_exit
run_mise_use_global "${DOT_REQUIRED_MISE_TOOLS[@]}"
ok "required global tools installed"

step "install optional tools"
if [ "$INSTALL_OPTIONAL_TOOLS" = "1" ]; then
  run_mise_use_global "${DOT_OPTIONAL_MISE_TOOLS[@]}"
  CS_BIN=""
  if CS_BIN="$(dot_find_cmd cs 2>/dev/null)"; then
    run "$CS_BIN" install --install-dir "$HOME/.local/bin" metals
    ok "metals installed via coursier"
  else
    err "required command not found for metals install: cs"
    exit 1
  fi
  ensure_optional_vim_binary
  ensure_optional_vim_runtime
  ok "optional tools installed"
else
  warn "skipped optional tools (INSTALL_OPTIONAL_TOOLS=0)"
fi

step "ensure zsh is installed"
if command -v zsh >/dev/null 2>&1; then
  ok "zsh already installed: $(command -v zsh)"
else
  if ! install_system_package zsh zsh "zsh"; then
    err "zsh not found and automatic install failed; install zsh manually"
    exit 1
  fi
  ok "zsh installed via package manager"
fi

step "install prezto"
ensure_managed_clone \
  "$HOME/.zprezto" \
  "https://github.com/sorin-ionescu/prezto.git" \
  "sorin-ionescu/prezto" \
  "prezto" \
  "1" \
  "init.zsh"

step "link prezto runcoms and write ~/.zshrc wrapper"
while IFS=$'\t' read -r runcom_link runcom_target; do
  backup_if_unmanaged_path "$runcom_link" "$runcom_target" "$TS"
  run ln -sfn "$runcom_target" "$runcom_link"
  manifest_add_entry "symlink" "$runcom_link" "$runcom_target"
done < <(dot_print_prezto_runcom_symlink_entries "$HOME")
if [ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
  if [ ! -L "$HOME/.zshrc" ] && grep -Fq "dot-setup managed zshrc" "$HOME/.zshrc" 2>/dev/null; then
    run rm -f "$HOME/.zshrc"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would replace managed ~/.zshrc"
    else
      ok "replacing managed ~/.zshrc"
    fi
  else
    run mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$TS"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would back up $HOME/.zshrc -> $HOME/.zshrc.bak.$TS"
    else
      ok "backed up $HOME/.zshrc -> $HOME/.zshrc.bak.$TS"
    fi
  fi
fi
if [ "$DRY_RUN" = "1" ]; then
  printf '  [dry-run] write %s\n' "$HOME/.zshrc"
else
cat >"$HOME/.zshrc" <<'EOF'
# dot-setup managed zshrc (safe for cleanup.sh)
[ -s "$HOME/.zprezto/init.zsh" ] && source "$HOME/.zprezto/init.zsh"
[ -f "$HOME/.zsh.shared.zsh" ] && source "$HOME/.zsh.shared.zsh"
EOF
fi
ok "zsh runcoms and wrapper configured"
manifest_add_entry "managed_file_contains" "$HOME/.zshrc" "dot-setup managed zshrc"

step "link dotfiles from repo"
run mkdir -p "$HOME/.config"
run mkdir -p "$HOME/.local/bin"
while IFS=$'\t' read -r managed_link managed_target; do
  backup_if_unmanaged_path "$managed_link" "$managed_target" "$TS"
done < <(dot_print_repo_symlink_entries "$REPO_ROOT")
while IFS=$'\t' read -r managed_link managed_target; do
  run ln -sfn "$managed_target" "$managed_link"
  manifest_add_entry "symlink" "$managed_link" "$managed_target"
done < <(dot_print_repo_symlink_entries "$REPO_ROOT")
if [ "$DRY_RUN" = "1" ]; then
  ok "would create/update symlinks"
else
  ok "symlinks created"
fi

step "configure git include and tmux plugins"
INCLUDE_COUNT="$(dot_git_include_count "$GIT_SHARED_INCLUDE_PATH")"
if [ "${INCLUDE_COUNT:-0}" = "0" ]; then
  run git config --global --add include.path "$GIT_SHARED_INCLUDE_PATH"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would add git include.path: $GIT_SHARED_INCLUDE_PATH"
  else
    ok "added git include.path: $GIT_SHARED_INCLUDE_PATH"
  fi
elif [ "${INCLUDE_COUNT:-0}" = "1" ]; then
  ok "git include.path already configured"
else
  warn "duplicate git include.path entries found (${INCLUDE_COUNT}); normalizing to one"
  run git config --global --unset-all include.path "$GIT_SHARED_INCLUDE_PATH"
  run git config --global --add include.path "$GIT_SHARED_INCLUDE_PATH"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would normalize git include.path to one entry"
  else
    ok "normalized git include.path to one entry"
  fi
fi
manifest_add_entry "git_include_path" "$GIT_SHARED_INCLUDE_PATH"
ensure_managed_clone \
  "$HOME/.tmux/plugins/tpm" \
  "https://github.com/tmux-plugins/tpm" \
  "tmux-plugins/tpm" \
  "tmux tpm" \
  "0" \
  "tpm"
while IFS=$'\t' read -r clone_path clone_origin; do
  manifest_add_entry "git_clone_origin" "$clone_path" "$clone_origin"
done < <(dot_print_managed_git_clones "$HOME")
if [ "$INSTALL_TMUX_PLUGINS" = "1" ]; then
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry-run] %q\n' "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    ok "tmux plugins would be installed"
  else
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    ok "tmux plugins installed"
  fi
else
  warn "skipped tmux plugin installation (INSTALL_TMUX_PLUGINS=0)"
fi

step "final check and optional default shell switch"
if [ "$SET_DEFAULT_SHELL" = "1" ]; then
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry-run] %q %q %q %q\n' chsh -s "$(command -v zsh)" "$USER"
    ok "default login shell would be switched to zsh"
  elif chsh -s "$(command -v zsh)" "$USER"; then
    ok "default login shell switched to zsh"
  else
    warn "chsh failed. try interactively or run:"
    if command -v usermod >/dev/null 2>&1; then
      warn "sudo usermod -s \"$(command -v zsh)\" \"$USER\""
    else
      warn "chsh -s \"$(command -v zsh)\" \"$USER\""
    fi
  fi
else
  ok "default shell switch skipped by config (SET_DEFAULT_SHELL=0)"
fi

step "write setup manifest"
write_setup_manifest

log "summary"
printf '  login shell: %s\n' "$(dot_current_login_shell)"
printf '  helix link : %s\n' "$(dot_resolve_path "$HOME/.config/helix")"
printf '  lazygit link: %s\n' "$(dot_resolve_path "$HOME/.config/lazygit")"
printf '  tmux link  : %s\n' "$(dot_resolve_path "$HOME/.tmux.conf")"
printf '  zsh link   : %s\n' "$(dot_resolve_path "$HOME/.zsh.shared.zsh")"
printf '  dot-difft  : %s\n' "$(dot_resolve_path "$HOME/.local/bin/dot-difft")"
printf '  dot-difft-pager: %s\n' "$(dot_resolve_path "$HOME/.local/bin/dot-difft-pager")"
printf '  dot-lazygit-theme: %s\n' "$(dot_resolve_path "$HOME/.local/bin/dot-lazygit-theme")"
VIM_BIN="$(dot_find_cmd vim 2>/dev/null || true)"
if [ -n "$VIM_BIN" ]; then
  printf '  vim bin    : %s\n' "$VIM_BIN"
else
  printf '  vim bin    : missing\n'
fi
printf '  setup manifest: %s\n' "$MANIFEST_FILE"
printf '  mise toolset (effective):\n'
if [ "$DRY_RUN" = "1" ]; then
  warn "skipped 'mise current' in dry-run mode"
else
  if MISE_CURRENT_OUTPUT="$(mise current 2>&1)"; then
    printf '%s\n' "$MISE_CURRENT_OUTPUT" | sed 's/^/    /'
  else
    warn "failed to read 'mise current'; run: mise current"
    printf '%s\n' "$MISE_CURRENT_OUTPUT" | sed 's/^/    /'
  fi
fi

ok "setup completed"
