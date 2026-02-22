#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=scripts/lib/toolset.sh
source "$REPO_ROOT/scripts/lib/toolset.sh"
# shellcheck source=scripts/lib/scriptlib.sh
source "$REPO_ROOT/scripts/lib/scriptlib.sh"

TOTAL_STEPS=5
STEP=0
FAILED_STEP=0

DRY_RUN="${DRY_RUN:-0}"                         # 1 or 0
REMOVE_GLOBAL_TOOLS="${REMOVE_GLOBAL_TOOLS:-0}" # 1 or 0
FORCE_REMOVE_ZSHRC="${FORCE_REMOVE_ZSHRC:-0}"   # 1 or 0
MANIFEST_FILE="$(dot_setup_manifest_file)"
MANIFEST_DIR="$(dirname "$MANIFEST_FILE")"
MANIFEST_USED=0
MANIFEST_VERSION="1"

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

remove_existing_path_forced() {
  local path="$1"
  local label="${2:-$path}"
  if [ -e "$path" ] || [ -L "$path" ]; then
    run rm -rf "$path"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would remove $label (forced)"
    else
      ok "removed $label (forced)"
    fi
  else
    warn "already missing: $path"
  fi
}

remove_if_link_target() {
  local path="$1"
  local expected_target="$2"
  local label="$3"

  if [ -L "$path" ]; then
    if dot_is_link_target "$path" "$expected_target"; then
      run rm -f "$path"
      if [ "$DRY_RUN" = "1" ]; then
        ok "would remove $label"
      else
        ok "removed $label"
      fi
    else
      warn "kept $label (symlink target differs from expected managed target)"
    fi
  elif [ -e "$path" ]; then
    warn "kept $label (regular file/dir, not setup-managed symlink)"
  else
    warn "already missing: $path"
  fi
}

remove_if_managed_file_contains() {
  local path="$1"
  local marker="$2"
  local label="$3"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ ! -L "$path" ] && grep -Fq "$marker" "$path" 2>/dev/null; then
      run rm -rf "$path"
      if [ "$DRY_RUN" = "1" ]; then
        ok "would remove $label (managed)"
      else
        ok "removed $label (managed)"
      fi
    else
      warn "kept $label (not managed by setup marker)"
    fi
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
      if [ "$DRY_RUN" = "1" ]; then
        ok "would remove $label"
      else
        ok "removed $label"
      fi
      return
    fi
  fi

  warn "kept $label (not a managed clone: $path)"
}

manifest_repo_matches() {
  local manifest_repo=""
  local manifest_version=""
  [ -f "$MANIFEST_FILE" ] || return 1
  manifest_version="$(awk -F '\t' '$1=="version" { print $2; exit }' "$MANIFEST_FILE" 2>/dev/null || true)"
  if [ -z "$manifest_version" ]; then
    warn "setup manifest missing version header: $MANIFEST_FILE"
    return 1
  fi
  if [ "$manifest_version" != "$MANIFEST_VERSION" ]; then
    warn "setup manifest version mismatch (manifest=$manifest_version, expected=$MANIFEST_VERSION)"
    return 1
  fi
  manifest_repo="$(awk -F '\t' '$1=="repo_root" { print $2; exit }' "$MANIFEST_FILE" 2>/dev/null || true)"
  if [ -z "$manifest_repo" ]; then
    warn "setup manifest missing repo_root header: $MANIFEST_FILE"
    return 1
  fi
  if [ "$manifest_repo" != "$REPO_ROOT" ]; then
    warn "setup manifest repo mismatch (manifest=$manifest_repo, current=$REPO_ROOT)"
    return 1
  fi
  return 0
}

manifest_validate_schema() {
  local kind=""
  local path=""
  local meta=""
  local extra=""
  local line_no=0
  while IFS=$'\t' read -r kind path meta extra; do
    line_no=$((line_no + 1))
    case "$kind" in
      "")
        ;;
      version|repo_root)
        if [ -z "$path" ] || [ -n "$meta" ] || [ -n "$extra" ]; then
          err "invalid setup manifest row at line $line_no for '$kind'"
          return 1
        fi
        ;;
      symlink|managed_file_contains|git_clone_origin)
        if [ -z "$path" ] || [ -z "$meta" ] || [ -n "$extra" ]; then
          err "invalid setup manifest row at line $line_no for '$kind'"
          return 1
        fi
        ;;
      git_include_path)
        if [ -z "$path" ] || [ -n "$meta" ] || [ -n "$extra" ]; then
          err "invalid setup manifest row at line $line_no for '$kind'"
          return 1
        fi
        ;;
      *)
        err "unknown setup manifest entry: $kind"
        return 1
        ;;
    esac
  done <"$MANIFEST_FILE"
}

remove_static_managed_artifacts() {
  while IFS=$'\t' read -r managed_link managed_target; do
    remove_if_link_target "$managed_link" "$managed_target" "$managed_link"
  done < <(dot_print_repo_symlink_entries "$REPO_ROOT")
  while IFS=$'\t' read -r runcom_link runcom_target; do
    remove_if_link_target "$runcom_link" "$runcom_target" "$runcom_link"
  done < <(dot_print_prezto_runcom_symlink_entries "$HOME")
  if [ "$FORCE_REMOVE_ZSHRC" = "1" ]; then
    remove_existing_path_forced "$HOME/.zshrc"
  else
    remove_if_managed_file_contains "$HOME/.zshrc" "dot-setup managed zshrc" "$HOME/.zshrc"
  fi
}

remove_from_manifest() {
  local kind=""
  local path=""
  local meta=""
  while IFS=$'\t' read -r kind path meta; do
    case "$kind" in
      ""|version|repo_root)
        ;;
      symlink)
        remove_if_link_target "$path" "$meta" "$path"
        ;;
      managed_file_contains)
        if [ "$FORCE_REMOVE_ZSHRC" = "1" ] && [ "$path" = "$HOME/.zshrc" ]; then
          remove_existing_path_forced "$path"
        else
          remove_if_managed_file_contains "$path" "$meta" "$path"
        fi
        ;;
      git_clone_origin)
        remove_if_git_clone_origin "$path" "$meta" "$path"
        ;;
      git_include_path)
        # Removed in a dedicated step for consistency with previous cleanup behavior.
        ;;
      *)
        err "unknown setup manifest entry: $kind"
        return 1
        ;;
    esac
  done <"$MANIFEST_FILE"
}

remove_setup_manifest_if_used() {
  if [ "$MANIFEST_USED" != "1" ]; then
    return
  fi
  if [ -f "$MANIFEST_FILE" ]; then
    run rm -f "$MANIFEST_FILE"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would remove setup manifest: $MANIFEST_FILE"
    else
      ok "removed setup manifest: $MANIFEST_FILE"
    fi
  fi
  if [ "$DRY_RUN" = "0" ]; then
    rmdir "$MANIFEST_DIR" 2>/dev/null || true
  fi
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

for flag_name in DRY_RUN REMOVE_GLOBAL_TOOLS FORCE_REMOVE_ZSHRC; do
  dot_validate_bool_01 "$flag_name" "${!flag_name}" || exit 2
done

step "preflight"
if ! dot_require_cmd git; then
  err "required command not found: git"
  exit 1
fi
if [ "$REMOVE_GLOBAL_TOOLS" = "1" ] && ! dot_require_cmd mise; then
  err "required command not found: mise (for REMOVE_GLOBAL_TOOLS=1)"
  exit 1
fi
ok "repo: $REPO_ROOT"
if [ "$DRY_RUN" = "1" ]; then
  warn "dry-run mode enabled (no files/settings will be changed)"
fi

step "remove zsh/tmux/dotfile artifacts"
if manifest_repo_matches; then
  manifest_validate_schema
  remove_from_manifest
  MANIFEST_USED=1
else
  warn "setup manifest unavailable/mismatched; falling back to static cleanup targets"
  remove_static_managed_artifacts
fi

step "remove prezto and tmux plugin manager"
if [ "$MANIFEST_USED" = "1" ]; then
  ok "clone targets already handled by setup manifest entries"
else
  while IFS=$'\t' read -r clone_path clone_origin; do
    remove_if_git_clone_origin "$clone_path" "$clone_origin" "$clone_path"
  done < <(dot_print_managed_git_clones "$HOME")
fi

step "remove git include and optional global tool entries"
if git config --global --get-all include.path | grep -Fx "$REPO_ROOT/config/gitconfig.shared" >/dev/null; then
  run git config --global --unset-all include.path "$REPO_ROOT/config/gitconfig.shared"
  if [ "$DRY_RUN" = "1" ]; then
    ok "would remove git include.path: $REPO_ROOT/config/gitconfig.shared"
  else
    ok "removed git include.path: $REPO_ROOT/config/gitconfig.shared"
  fi
else
  warn "git include.path already absent: $REPO_ROOT/config/gitconfig.shared"
fi

if [ "$REMOVE_GLOBAL_TOOLS" = "1" ]; then
  # mise --remove is more reliable when applied per-tool.
  for tool in "${DOT_REQUIRED_MISE_TOOLS[@]}" "${DOT_OPTIONAL_MISE_TOOLS[@]}"; do
    run mise use -g --remove "$(dot_strip_tool_version "$tool")" || true
  done
  if [ "$DRY_RUN" = "1" ]; then
    ok "would remove global mise tool entries added by setup"
  else
    ok "removed global mise tool entries added by setup"
  fi
else
  warn "skipped global tool entry removal (REMOVE_GLOBAL_TOOLS=0)"
fi
remove_setup_manifest_if_used

step "summary"
printf '  login shell: %s\n' "$(dot_current_login_shell)"
for p in \
  "$HOME/.zprezto" \
  "$HOME/.tmux/plugins/tpm" \
  "$HOME/.config/helix" \
  "$HOME/.config/lazygit" \
  "$HOME/.tmux.conf" \
  "$HOME/.zsh.shared.zsh" \
  "$HOME/.local/bin/dot-difft" \
  "$HOME/.local/bin/dot-difft-pager" \
  "$HOME/.local/bin/dot-lazygit-theme" \
  "$HOME/.zshrc" \
  "$MANIFEST_FILE"; do
  if [ -e "$p" ] || [ -L "$p" ]; then
    printf '  remains: %s\n' "$p"
  else
    printf '  removed: %s\n' "$p"
  fi
done

ok "cleanup completed"
