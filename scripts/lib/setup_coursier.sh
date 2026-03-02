#!/usr/bin/env bash

dot_coursier_jvm_launcher_url() {
  printf '%s\n' "https://github.com/coursier/launchers/raw/master/coursier"
}

dot_coursier_jvm_launcher_path() {
  printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/dot/coursier/coursier"
}

download_coursier_jvm_launcher() {
  local url="$1"
  local dst="$2"

  if command -v curl >/dev/null 2>&1; then
    run curl -fsSL "$url" -o "$dst"
    return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    run wget -qO "$dst" "$url"
    return 0
  fi
  err "failed to download JVM coursier launcher: neither curl nor wget is available"
  return 1
}

ensure_coursier_jvm_launcher() {
  local launcher_path=""
  local launcher_url=""
  local check_output=""

  launcher_path="$(dot_coursier_jvm_launcher_path)"
  launcher_url="$(dot_coursier_jvm_launcher_url)"

  if ! ensure_cmd_on_path java; then
    err "java runtime is unavailable on PATH; required for JVM coursier launcher"
    return 1
  fi

  if [ -x "$launcher_path" ]; then
    if [ "$DRY_RUN" = "1" ] || "$launcher_path" --help >/dev/null 2>&1; then
      printf '%s\n' "$launcher_path"
      return 0
    fi
    warn "cached JVM coursier launcher failed health check; re-downloading" >&2
  fi

  run mkdir -p "$(dirname "$launcher_path")"
  download_coursier_jvm_launcher "$launcher_url" "$launcher_path" || return 1
  run chmod +x "$launcher_path"

  if [ "$DRY_RUN" = "1" ]; then
    printf '%s\n' "$launcher_path"
    return 0
  fi

  check_output="$(mktemp)"
  if "$launcher_path" --help >"$check_output" 2>&1; then
    rm -f "$check_output"
    printf '%s\n' "$launcher_path"
    return 0
  fi

  err "downloaded JVM coursier launcher failed health check: $launcher_path"
  head -n 4 "$check_output" | sed 's/^/    /' >&2
  rm -f "$check_output"
  return 1
}

resolve_working_coursier_bin() {
  local cs_bin=""

  if cs_bin="$(dot_find_cmd cs 2>/dev/null)"; then
    if [ "$DRY_RUN" = "1" ] || "$cs_bin" --help >/dev/null 2>&1; then
      printf '%s\n' "$cs_bin"
      return 0
    fi
    warn "native coursier launcher failed health check; falling back to JVM launcher" >&2
  fi

  ensure_coursier_jvm_launcher
}
