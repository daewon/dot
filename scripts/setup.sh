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
TS="$(date +%Y%m%d-%H%M%S)"
declare -a MANIFEST_ENTRIES=()

log() {
  printf '[setup] %s\n' "$*"
}

step() {
  STEP=$((STEP + 1))
  printf '\n[%d/%d] %s\n' "$STEP" "$TOTAL_STEPS" "$*"
}

ok() {
  printf '  [ok] %s\n' "$*"
}

warn() {
  printf '  [warn] %s\n' "$*"
}

err() {
  printf '  [error] %s\n' "$*" >&2
}

print_mise_install_hint() {
  warn "install mise, reload your shell, then re-run setup:"
  cat <<'EOF'
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    exec "$SHELL" -l
EOF
}

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--dry-run|-n]

Options:
  --dry-run, -n  Show what would run without applying changes
  --help, -h     Show this help

Env flags:
  INSTALL_OPTIONAL_TOOLS=0|1   Install optional tools
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

run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

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

resolve_install_optional_tools() {
  local reply=""
  local selected_value=""

  if [ -n "$INSTALL_OPTIONAL_TOOLS" ]; then
    return
  fi

  if dot_is_interactive_tty; then
    printf '\n[setup] Install optional tools (Python/Scala/TypeScript/dmux + metals launcher)? [y/N]: '
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
run mise use -g "${DOT_REQUIRED_MISE_TOOLS[@]}"
ok "required global tools installed"

step "install optional tools"
if [ "$INSTALL_OPTIONAL_TOOLS" = "1" ]; then
  run mise use -g "${DOT_OPTIONAL_MISE_TOOLS[@]}"
  CS_BIN=""
  if CS_BIN="$(dot_find_cmd cs 2>/dev/null)"; then
    run "$CS_BIN" install --install-dir "$HOME/.local/bin" metals
    ok "metals installed via coursier"
  else
    err "required command not found for metals install: cs"
    exit 1
  fi
  ok "optional global tools installed"
else
  warn "skipped optional tools (INSTALL_OPTIONAL_TOOLS=0)"
fi

step "ensure zsh is installed"
if command -v zsh >/dev/null 2>&1; then
  ok "zsh already installed: $(command -v zsh)"
else
  if command -v apt-get >/dev/null 2>&1; then
    run sudo apt-get update
    run sudo apt-get install -y zsh
    ok "zsh installed via apt-get"
  elif command -v brew >/dev/null 2>&1; then
    run brew install zsh
    ok "zsh installed via brew"
  else
    err "zsh not found and no supported package manager detected (apt-get/brew); install zsh manually"
    exit 1
  fi
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
INCLUDE_COUNT="$(git config --global --get-all include.path 2>/dev/null | grep -Fxc "$REPO_ROOT/config/gitconfig.shared" || true)"
INCLUDE_COUNT="$(printf '%s' "$INCLUDE_COUNT" | tr -d '[:space:]')"
if [ "${INCLUDE_COUNT:-0}" = "0" ]; then
  run git config --global --add include.path "$REPO_ROOT/config/gitconfig.shared"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would add git include.path: $REPO_ROOT/config/gitconfig.shared"
  else
    ok "added git include.path: $REPO_ROOT/config/gitconfig.shared"
  fi
elif [ "${INCLUDE_COUNT:-0}" = "1" ]; then
  ok "git include.path already configured"
else
  warn "duplicate git include.path entries found (${INCLUDE_COUNT}); normalizing to one"
  run git config --global --unset-all include.path "$REPO_ROOT/config/gitconfig.shared"
  run git config --global --add include.path "$REPO_ROOT/config/gitconfig.shared"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would normalize git include.path to one entry"
  else
    ok "normalized git include.path to one entry"
  fi
fi
manifest_add_entry "git_include_path" "$REPO_ROOT/config/gitconfig.shared"
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
