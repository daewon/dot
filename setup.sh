#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

TOTAL_STEPS=10
STEP=0
FAILED_STEP=0

INSTALL_OPTIONAL_TOOLS="${INSTALL_OPTIONAL_TOOLS:-1}" # 1 or 0
SET_DEFAULT_SHELL="${SET_DEFAULT_SHELL:-0}"           # 1 or 0
INSTALL_TMUX_PLUGINS="${INSTALL_TMUX_PLUGINS:-1}"     # 1 or 0
DRY_RUN="${DRY_RUN:-0}"                               # 1 or 0

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

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--dry-run|-n]

Options:
  --dry-run, -n  Show what would run without applying changes
  --help, -h     Show this help

Env flags:
  INSTALL_OPTIONAL_TOOLS=0|1   Install optional tools (default: 1)
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

is_link_target() {
  local link_path="$1"
  local expected_target="$2"
  local actual_target=""
  local resolved_link=""
  local resolved_expected=""

  [ -L "$link_path" ] || return 1
  actual_target="$(readlink "$link_path" || true)"
  if [ "$actual_target" = "$expected_target" ]; then
    return 0
  fi
  if [ -e "$expected_target" ]; then
    resolved_link="$(resolve_path "$link_path")"
    resolved_expected="$(resolve_path "$expected_target")"
    if [ -n "$resolved_link" ] && [ "$resolved_link" = "$resolved_expected" ]; then
      return 0
    fi
  fi
  return 1
}

backup_if_unmanaged_path() {
  local path="$1"
  local expected_target="$2"
  local ts="$3"
  if [ -L "$path" ]; then
    if is_link_target "$path" "$expected_target"; then
      return
    fi
    run mv "$path" "${path}.bak.${ts}"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would back up $path -> ${path}.bak.${ts}"
    else
      ok "backed up $path -> ${path}.bak.${ts}"
    fi
    return
  fi
  if [ -e "$path" ]; then
    run mv "$path" "${path}.bak.${ts}"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would back up $path -> ${path}.bak.${ts}"
    else
      ok "backed up $path -> ${path}.bak.${ts}"
    fi
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "required command not found: $cmd"
    exit 1
  fi
}

resolve_path() {
  local p="$1"
  local out=""
  if command -v readlink >/dev/null 2>&1 && readlink -f "$REPO_ROOT" >/dev/null 2>&1; then
    out="$(readlink -f "$p" 2>/dev/null || true)"
    printf '%s' "${out:-missing}"
    return
  fi
  if command -v realpath >/dev/null 2>&1; then
    out="$(realpath "$p" 2>/dev/null || true)"
    printf '%s' "${out:-missing}"
    return
  fi
  if command -v perl >/dev/null 2>&1; then
    out="$(perl -MCwd=abs_path -e 'my $p=shift; my $r=abs_path($p); print defined($r) ? $r : "missing";' "$p" 2>/dev/null || true)"
    printf '%s' "${out:-missing}"
    return
  fi
  printf 'missing'
}

current_login_shell() {
  if command -v getent >/dev/null 2>&1; then
    getent passwd "$USER" | cut -d: -f7
    return
  fi
  if command -v dscl >/dev/null 2>&1; then
    dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}'
    return
  fi
  printf '%s' "${SHELL:-unknown}"
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

step "preflight"
require_cmd git
require_cmd mise
ok "repo: $REPO_ROOT"
if [ "$DRY_RUN" = "1" ]; then
  warn "dry-run mode enabled (no files or settings will be changed)"
fi

step "trust and install local mise toolchain"
run mise trust "$REPO_ROOT/mise.toml"
run mise install
ok "mise.toml toolchain installed"

step "install global required tools (LSP/formatter)"
run mise use -g black@latest ruff@latest \
  npm:pyright@latest npm:vscode-langservers-extracted@latest \
  npm:yaml-language-server@latest npm:prettier@latest
ok "required global tools installed"

step "install optional tools"
if [ "$INSTALL_OPTIONAL_TOOLS" = "1" ]; then
  run mise use -g marksman@latest yazi@latest \
    npm:typescript-language-server@latest npm:typescript@latest npm:dmux@latest
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
if [ -d "$HOME/.zprezto" ]; then
  if [ -s "$HOME/.zprezto/init.zsh" ] && [ -d "$HOME/.zprezto/runcoms" ]; then
    ok "~/.zprezto already exists"
  else
    warn "~/.zprezto looks incomplete; recloning"
    run rm -rf "$HOME/.zprezto"
    run git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would re-clone prezto"
    else
      ok "prezto re-cloned"
    fi
  fi
else
  run git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would clone prezto"
  else
    ok "prezto cloned"
  fi
fi

step "link prezto runcoms and write ~/.zshrc wrapper"
TS="$(date +%Y%m%d-%H%M%S)"
for rc in zlogin zlogout zprofile zshenv zpreztorc; do
  backup_if_unmanaged_path "$HOME/.$rc" "$HOME/.zprezto/runcoms/$rc" "$TS"
  run ln -sfn "$HOME/.zprezto/runcoms/$rc" "$HOME/.$rc"
done
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

step "link dotfiles from repo"
run mkdir -p "$HOME/.config"
backup_if_unmanaged_path "$HOME/.config/helix" "$REPO_ROOT/helix" "$TS"
backup_if_unmanaged_path "$HOME/.tmux.conf" "$REPO_ROOT/tmux.conf.user" "$TS"
backup_if_unmanaged_path "$HOME/.zsh.shared.zsh" "$REPO_ROOT/zsh.shared.zsh" "$TS"
run ln -sfn "$REPO_ROOT/helix" "$HOME/.config/helix"
run ln -sfn "$REPO_ROOT/tmux.conf.user" "$HOME/.tmux.conf"
run ln -sfn "$REPO_ROOT/zsh.shared.zsh" "$HOME/.zsh.shared.zsh"
if [ "$DRY_RUN" = "1" ]; then
  ok "would create/update symlinks"
else
  ok "symlinks created"
fi

step "configure git include and tmux plugins"
INCLUDE_COUNT="$(git config --global --get-all include.path 2>/dev/null | grep -Fx "$REPO_ROOT/gitconfig.shared" | wc -l || true)"
INCLUDE_COUNT="$(printf '%s' "$INCLUDE_COUNT" | tr -d '[:space:]')"
if [ "${INCLUDE_COUNT:-0}" = "0" ]; then
  run git config --global --add include.path "$REPO_ROOT/gitconfig.shared"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would add git include.path: $REPO_ROOT/gitconfig.shared"
  else
    ok "added git include.path: $REPO_ROOT/gitconfig.shared"
  fi
elif [ "${INCLUDE_COUNT:-0}" = "1" ]; then
  ok "git include.path already configured"
else
  warn "duplicate git include.path entries found (${INCLUDE_COUNT}); normalizing to one"
  run git config --global --unset-all include.path "$REPO_ROOT/gitconfig.shared"
  run git config --global --add include.path "$REPO_ROOT/gitconfig.shared"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would normalize git include.path to one entry"
  else
    ok "normalized git include.path to one entry"
  fi
fi
if [ ! -x "$HOME/.tmux/plugins/tpm/tpm" ]; then
  run git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
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

log "summary"
printf '  login shell: %s\n' "$(current_login_shell)"
printf '  helix link : %s\n' "$(resolve_path "$HOME/.config/helix")"
printf '  tmux link  : %s\n' "$(resolve_path "$HOME/.tmux.conf")"
printf '  zsh link   : %s\n' "$(resolve_path "$HOME/.zsh.shared.zsh")"
printf '  mise toolset (repo):\n'
if [ "$DRY_RUN" = "1" ]; then
  warn "skipped 'mise current' in dry-run mode"
else
  if MISE_CURRENT_OUTPUT="$(mise current 2>&1)"; then
    printf '%s\n' "$MISE_CURRENT_OUTPUT" | sed 's/^/    /'
  else
    warn "failed to read 'mise current'; run: mise trust \"$REPO_ROOT/mise.toml\" && mise install"
    printf '%s\n' "$MISE_CURRENT_OUTPUT" | sed 's/^/    /'
  fi
fi

ok "setup completed"
