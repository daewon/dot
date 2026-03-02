#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  RESOLVED_PATH="$(readlink -f "$SCRIPT_PATH" 2>/dev/null || true)"
  if [ -n "$RESOLVED_PATH" ]; then
    SCRIPT_PATH="$RESOLVED_PATH"
  fi
fi
if [ "$SCRIPT_PATH" = "${BASH_SOURCE[0]}" ] && command -v realpath >/dev/null 2>&1; then
  RESOLVED_PATH="$(realpath "$SCRIPT_PATH" 2>/dev/null || true)"
  if [ -n "$RESOLVED_PATH" ]; then
    SCRIPT_PATH="$RESOLVED_PATH"
  fi
fi
if [ "$SCRIPT_PATH" = "${BASH_SOURCE[0]}" ] && [ -L "$SCRIPT_PATH" ] && command -v readlink >/dev/null 2>&1; then
  LINK_TARGET="$(readlink "$SCRIPT_PATH" 2>/dev/null || true)"
  if [ -n "$LINK_TARGET" ]; then
    case "$LINK_TARGET" in
      /*) SCRIPT_PATH="$LINK_TARGET" ;;
      *) SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" && cd "$(dirname "$LINK_TARGET")" && pwd)/$(basename "$LINK_TARGET")" ;;
    esac
  fi
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# shellcheck source=scripts/lib/scriptlib.sh
source "$SCRIPT_DIR/lib/scriptlib.sh"

usage() {
  cat <<'EOF'
Usage: sclip < stdin

Copy stdin to the system clipboard with an OS-appropriate backend.
EOF
}

detect_backend() {
  dot_select_clipboard_runtime_backend
}

copy_from_stdin() {
  local backend="$1"
  case "$backend" in
    reattach-pbcopy)
      reattach-to-user-namespace pbcopy
      ;;
    pbcopy)
      pbcopy
      ;;
    clip.exe)
      clip.exe
      ;;
    wl-copy)
      wl-copy
      ;;
    xclip)
      xclip -in -selection clipboard
      ;;
    xsel)
      xsel --clipboard --input
      ;;
    tmux-load-buffer)
      tmux load-buffer -w -
      ;;
    *)
      printf '[sclip] unknown backend: %s\n' "$backend" >&2
      return 1
      ;;
  esac
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -gt 0 ]; then
  printf '[sclip] unexpected arguments\n' >&2
  usage >&2
  exit 2
fi

if [ -t 0 ]; then
  printf '[sclip] stdin is required (example: printf \"hello\" | sclip)\n' >&2
  exit 2
fi

if ! backend="$(detect_backend)"; then
  printf '[sclip] no clipboard backend found. check display session or run inside tmux with OSC52 support\n' >&2
  exit 1
fi

copy_from_stdin "$backend"
