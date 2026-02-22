#!/usr/bin/env bash
set -Eeuo pipefail

resolve_script_path() {
  local src="$1"
  local dir=""
  while [[ -L "$src" ]]; do
    dir="$(cd "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    [[ "$src" != /* ]] && src="$dir/$src"
  done
  printf '%s\n' "$src"
}

SCRIPT_PATH="$(resolve_script_path "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
THEMES_DIR="$REPO_ROOT/config/lazygit/themes"
TARGET_CONFIG="$REPO_ROOT/config/lazygit/config.yml"
STATE_FILE="$REPO_ROOT/config/lazygit/.current_theme"

usage() {
  cat <<'EOF'
Usage:
  dot-lazygit-theme list
  dot-lazygit-theme set <theme-name>
  dot-lazygit-theme next
  dot-lazygit-theme prev
  dot-lazygit-theme current

Examples:
  dot-lazygit-theme list
  dot-lazygit-theme set dracula
  dot-lazygit-theme next
EOF
}

themes() {
  find "$THEMES_DIR" -maxdepth 1 -type f -name '*.yml' -printf '%f\n' \
    | sed 's/\.yml$//' | sort
}

detect_theme_from_config() {
  local theme_name=""
  if [[ ! -f "$TARGET_CONFIG" ]]; then
    return 1
  fi
  while IFS= read -r theme_name; do
    if cmp -s "$TARGET_CONFIG" "$THEMES_DIR/${theme_name}.yml"; then
      printf '%s\n' "$theme_name"
      return 0
    fi
  done < <(themes)
  return 1
}

current_theme() {
  local cur=""
  if [[ -f "$STATE_FILE" ]]; then
    cur="$(sed -n '1p' "$STATE_FILE")"
    if [[ -n "$cur" ]] && [[ -f "$THEMES_DIR/${cur}.yml" ]]; then
      printf '%s\n' "$cur"
      return
    fi
  fi
  if cur="$(detect_theme_from_config)"; then
    printf '%s\n' "$cur"
    return
  fi
  cur="$(themes | sed -n '1p')"
  if [[ -n "$cur" ]]; then
    printf '%s\n' "$cur"
    return
  fi
  printf '%s\n' "ayu_evolve"
}

set_theme() {
  local theme_name="$1"
  local src="$THEMES_DIR/${theme_name}.yml"

  if [[ ! -f "$src" ]]; then
    printf '[error] unknown theme: %s\n' "$theme_name" >&2
    printf 'available themes:\n' >&2
    themes | sed 's/^/  - /' >&2
    exit 2
  fi

  cp "$src" "$TARGET_CONFIG"
  printf '%s\n' "$theme_name" > "$STATE_FILE"
  printf '[ok] applied theme: %s\n' "$theme_name"
}

rotate_theme() {
  local direction="$1"
  mapfile -t all_themes < <(themes)

  if [[ "${#all_themes[@]}" -eq 0 ]]; then
    printf '[error] no theme files found in %s\n' "$THEMES_DIR" >&2
    exit 1
  fi

  local cur
  cur="$(current_theme)"
  local idx=-1
  for i in "${!all_themes[@]}"; do
    if [[ "${all_themes[$i]}" == "$cur" ]]; then
      idx="$i"
      break
    fi
  done
  if [[ "$idx" -lt 0 ]]; then
    idx=0
  fi

  local next_idx
  if [[ "$direction" == "next" ]]; then
    next_idx=$(( (idx + 1) % ${#all_themes[@]} ))
  else
    next_idx=$(( (idx - 1 + ${#all_themes[@]}) % ${#all_themes[@]} ))
  fi

  set_theme "${all_themes[$next_idx]}"
}

list_themes() {
  local cur
  cur="$(current_theme)"
  while IFS= read -r t; do
    if [[ "$t" == "$cur" ]]; then
      printf '* %s\n' "$t"
    else
      printf '  %s\n' "$t"
    fi
  done < <(themes)
}

cmd="${1:-list}"
case "$cmd" in
  list)
    list_themes
    ;;
  set)
    if [[ $# -lt 2 ]]; then
      usage
      exit 2
    fi
    set_theme "$2"
    ;;
  next)
    rotate_theme next
    ;;
  prev)
    rotate_theme prev
    ;;
  current)
    printf '%s\n' "$(current_theme)"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
