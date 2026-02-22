#!/usr/bin/env bash
set -Eeuo pipefail

wrap_mode=0
if [[ "${1:-}" == "--wrap" ]]; then
  wrap_mode=1
  shift
fi

cols="${DIFFT_PAGER_WIDTH:-${COLUMNS:-}}"
if ! [[ "$cols" =~ ^[0-9]+$ ]]; then
  if command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
  fi
fi
if ! [[ "$cols" =~ ^[0-9]+$ ]] || [[ "$cols" -lt 40 ]]; then
  cols=120
fi

sep="$(printf '━%.0s' $(seq 1 "$cols"))"

print_with_boundaries() {
  awk -v sep="$sep" '
    BEGIN { seen = 0 }
    function hr() { print sep }
    {
      # difftastic header line contains " --- " after path/language.
      if (index($0, " --- ") > 0) {
        hr()
        seen = 1
      }
      print
    }
    END {
      if (seen) hr()
    }
  '
}

if [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
  if [[ "$wrap_mode" -eq 1 ]]; then
    print_with_boundaries | less -RFX -+S
  else
    print_with_boundaries | less -RFXS
  fi
else
  print_with_boundaries
fi
