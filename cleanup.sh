#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

TOTAL_STEPS=5
STEP=0
FAILED_STEP=0

DRY_RUN="${DRY_RUN:-0}"                         # 1 or 0
REMOVE_GLOBAL_TOOLS="${REMOVE_GLOBAL_TOOLS:-0}" # 1 or 0
FORCE_REMOVE_ZSHRC="${FORCE_REMOVE_ZSHRC:-0}"   # 1 or 0

log() { printf '[cleanup] %s\n' "$*"; }
step() {
  STEP=$((STEP + 1))
  printf '\n[%d/%d] %s\n' "$STEP" "$TOTAL_STEPS" "$*"
}
ok() { printf '  [ok] %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
err() { printf '  [error] %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: ./cleanup.sh [--dry-run|-n]

Options:
  --dry-run, -n  Show what would be removed without applying changes
  --help, -h     Show this help

Env flags:
  REMOVE_GLOBAL_TOOLS=0|1  Remove global mise tool entries added by setup (default: 0)
  FORCE_REMOVE_ZSHRC=0|1   Remove ~/.zshrc even if not managed by setup (default: 0)
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

remove_if_link_target() {
  local path="$1"
  local expected_target="$2"
  local label="$3"

  if [ -L "$path" ]; then
    if is_link_target "$path" "$expected_target"; then
      run rm -f "$path"
      [ "$DRY_RUN" = "1" ] && ok "would remove $label" || ok "removed $label"
    else
      warn "kept $label (symlink target differs from expected managed target)"
    fi
  elif [ -e "$path" ]; then
    warn "kept $label (regular file/dir, not setup-managed symlink)"
  else
    warn "already missing: $path"
  fi
}

remove_if_git_clone_origin() {
  local path="$1"
  local expected_url_snippet="$2"
  local label="$3"
  local origin=""

  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    warn "already missing: $path"
    return
  fi

  if [ -d "$path/.git" ]; then
    origin="$(git -C "$path" remote get-url origin 2>/dev/null || true)"
    if printf '%s' "$origin" | grep -Fq "$expected_url_snippet"; then
      run rm -rf "$path"
      [ "$DRY_RUN" = "1" ] && ok "would remove $label" || ok "removed $label"
      return
    fi
  fi

  warn "kept $label (not a managed clone: $path)"
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
if ! command -v git >/dev/null 2>&1; then
  err "required command not found: git"
  exit 1
fi
if [ "$REMOVE_GLOBAL_TOOLS" = "1" ] && ! command -v mise >/dev/null 2>&1; then
  err "required command not found: mise (for REMOVE_GLOBAL_TOOLS=1)"
  exit 1
fi
ok "repo: $REPO_ROOT"
if [ "$DRY_RUN" = "1" ]; then
  warn "dry-run mode enabled (no files/settings will be changed)"
fi

step "remove zsh/tmux/dotfile artifacts"
remove_if_link_target "$HOME/.config/helix" "$REPO_ROOT/helix" "$HOME/.config/helix"
remove_if_link_target "$HOME/.tmux.conf" "$REPO_ROOT/tmux.conf.user" "$HOME/.tmux.conf"
remove_if_link_target "$HOME/.zsh.shared.zsh" "$REPO_ROOT/zsh.shared.zsh" "$HOME/.zsh.shared.zsh"
for rc in zshenv zprofile zpreztorc zlogin zlogout; do
  remove_if_link_target "$HOME/.$rc" "$HOME/.zprezto/runcoms/$rc" "$HOME/.$rc"
done

if [ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
  if [ "$FORCE_REMOVE_ZSHRC" = "1" ]; then
    run rm -rf "$HOME/.zshrc"
    [ "$DRY_RUN" = "1" ] && ok "would remove ~/.zshrc (forced)" || ok "removed ~/.zshrc (forced)"
  elif [ ! -L "$HOME/.zshrc" ] && grep -Fq "dot-setup managed zshrc" "$HOME/.zshrc" 2>/dev/null; then
    run rm -rf "$HOME/.zshrc"
    [ "$DRY_RUN" = "1" ] && ok "would remove ~/.zshrc (managed)" || ok "removed ~/.zshrc (managed)"
  else
    warn "kept ~/.zshrc (not managed by setup wrapper). set FORCE_REMOVE_ZSHRC=1 to remove."
  fi
else
  warn "already missing: $HOME/.zshrc"
fi

step "remove prezto and tmux plugin manager"
remove_if_git_clone_origin "$HOME/.zprezto" "sorin-ionescu/prezto" "$HOME/.zprezto"
remove_if_git_clone_origin "$HOME/.tmux/plugins/tpm" "tmux-plugins/tpm" "$HOME/.tmux/plugins/tpm"

step "remove git include and optional global tool entries"
if git config --global --get-all include.path | grep -Fx "$REPO_ROOT/gitconfig.shared" >/dev/null; then
  run git config --global --unset-all include.path "$REPO_ROOT/gitconfig.shared"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would remove git include.path: $REPO_ROOT/gitconfig.shared"
  else
    ok "removed git include.path: $REPO_ROOT/gitconfig.shared"
  fi
else
  warn "git include.path already absent: $REPO_ROOT/gitconfig.shared"
fi

if [ "$REMOVE_GLOBAL_TOOLS" = "1" ]; then
  # mise --remove is more reliable when applied per-tool.
  for tool in \
    black ruff marksman yazi \
    npm:pyright npm:vscode-langservers-extracted npm:yaml-language-server \
    npm:prettier npm:typescript-language-server npm:typescript npm:dmux; do
    run mise use -g --remove "$tool" || true
  done
  if [ "$DRY_RUN" = "1" ]; then
    ok "would remove global mise tool entries added by setup"
  else
    ok "removed global mise tool entries added by setup"
  fi
else
  warn "skipped global tool entry removal (REMOVE_GLOBAL_TOOLS=0)"
fi

step "summary"
printf '  login shell: %s\n' "$(current_login_shell)"
for p in \
  "$HOME/.zprezto" \
  "$HOME/.tmux/plugins/tpm" \
  "$HOME/.config/helix" \
  "$HOME/.tmux.conf" \
  "$HOME/.zsh.shared.zsh" \
  "$HOME/.zshrc"; do
  if [ -e "$p" ] || [ -L "$p" ]; then
    printf '  remains: %s\n' "$p"
  else
    printf '  removed: %s\n' "$p"
  fi
done

ok "cleanup completed"
