#!/usr/bin/env bash
set -Eeuo pipefail

resolve_difft_bin() {
  if command -v difft >/dev/null 2>&1; then
    command -v difft
    return 0
  fi
  if command -v mise >/dev/null 2>&1; then
    mise which difft 2>/dev/null || true
    return 0
  fi
  return 1
}

# Match difft output width to the current terminal for consistent side-by-side layout.
cols="${COLUMNS:-}"
if ! [[ "$cols" =~ ^[0-9]+$ ]]; then
  if command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
  fi
fi
if ! [[ "$cols" =~ ^[0-9]+$ ]] || [[ "$cols" -lt 80 ]]; then
  cols=120
fi

difft_bin="$(resolve_difft_bin)"
if [[ -z "${difft_bin:-}" ]]; then
  echo "[error] difft not found. install with: mise use -g difftastic@latest" >&2
  exit 127
fi

exec "$difft_bin" \
  --display side-by-side-show-both \
  --color always \
  --background dark \
  --syntax-highlight on \
  --context 4 \
  --width "$cols" \
  "$@"
