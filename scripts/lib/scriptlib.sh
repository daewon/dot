#!/usr/bin/env bash

dot_find_cmd() {
  local cmd="$1"
  local resolved=""

  resolved="$(command -v "$cmd" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    printf '%s\n' "$resolved"
    return 0
  fi

  if command -v mise >/dev/null 2>&1; then
    resolved="$(mise which "$cmd" 2>/dev/null || true)"
    if [ -n "$resolved" ]; then
      printf '%s\n' "$resolved"
      return 0
    fi
  fi

  return 1
}

dot_require_cmd() {
  local cmd="$1"
  dot_find_cmd "$cmd" >/dev/null 2>&1
}

dot_resolve_path() {
  local path="$1"
  local out=""
  if dot_require_cmd readlink; then
    out="$(readlink -f "$path" 2>/dev/null || true)"
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return
    fi
  fi
  if dot_require_cmd realpath; then
    out="$(realpath "$path" 2>/dev/null || true)"
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return
    fi
  fi
  if dot_require_cmd perl; then
    out="$(perl -MCwd=abs_path -e 'my $p=shift; my $r=abs_path($p); print defined($r) ? $r : "";' "$path" 2>/dev/null || true)"
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return
    fi
  fi
  printf 'missing'
}

dot_current_login_shell() {
  if dot_require_cmd getent; then
    getent passwd "$USER" | cut -d: -f7
    return
  fi
  if dot_require_cmd dscl; then
    dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}'
    return
  fi
  printf '%s' "${SHELL:-unknown}"
}

dot_is_link_target() {
  local link_path="$1"
  local expected_target="$2"
  local actual_target=""
  local resolved_link=""
  local resolved_expected=""

  [ -L "$link_path" ] || return 1
  actual_target="$(readlink "$link_path" 2>/dev/null || true)"
  if [ "$actual_target" = "$expected_target" ]; then
    return 0
  fi

  if [ -e "$expected_target" ]; then
    resolved_link="$(dot_resolve_path "$link_path")"
    resolved_expected="$(dot_resolve_path "$expected_target")"
    if [ -n "$resolved_link" ] && [ "$resolved_link" = "$resolved_expected" ]; then
      return 0
    fi
  fi
  return 1
}

dot_validate_bool_01() {
  local name="$1"
  local value="$2"
  case "$value" in
    0|1)
      return 0
      ;;
    *)
      printf '[error] %s must be 0 or 1 (got: %s)\n' "$name" "$value" >&2
      return 1
      ;;
  esac
}

dot_validate_bool_flags_01() {
  local flag_name=""
  local flag_value=""
  for flag_name in "$@"; do
    flag_value="${!flag_name-}"
    dot_validate_bool_01 "$flag_name" "$flag_value" || return 1
  done
}

dot_validate_nonneg_int() {
  local name="$1"
  local value="$2"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    return 0
  fi
  printf '[error] %s must be a non-negative integer (got: %s)\n' "$name" "$value" >&2
  return 1
}

dot_validate_nonneg_int_flags() {
  local flag_name=""
  local flag_value=""
  for flag_name in "$@"; do
    flag_value="${!flag_name-}"
    dot_validate_nonneg_int "$flag_name" "$flag_value" || return 1
  done
}

dot_is_interactive_tty() {
  [ -t 0 ] && [ -t 1 ]
}

dot_parse_yes_no_to_bool_01() {
  local value="${1:-}"
  case "$value" in
    [yY]|[yY][eE][sS])
      printf '1'
      return 0
      ;;
    [nN]|[nN][oO]|"")
      printf '0'
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
