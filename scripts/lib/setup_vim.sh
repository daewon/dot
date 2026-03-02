#!/usr/bin/env bash

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
