#!/usr/bin/env bash

ensure_required_clipboard_backend() {
  local policy=""
  local clipboard_cmd=""
  local uname_s=""
  local prefer_wayland=0
  policy="$(dot_required_clipboard_policy_label)"
  uname_s="$(dot_host_uname_s)"

  if [ "$policy" = "none" ]; then
    warn "clipboard backend policy is not defined for OS: $uname_s"
    return 0
  fi

  if clipboard_cmd="$(dot_find_available_clipboard_cmd 2>/dev/null)"; then
    ok "clipboard backend ready: $clipboard_cmd"
    return 0
  fi

  case "$uname_s" in
    Darwin)
      err "required clipboard command is unavailable on macOS: pbcopy"
      return 1
      ;;
    Linux)
      if dot_host_is_wsl; then
        err "required clipboard command is unavailable on WSL: clip.exe"
        return 1
      fi

      warn "installing Linux clipboard backend (policy: $policy)"
      if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        prefer_wayland=1
      fi

      if [ "$prefer_wayland" = "1" ]; then
        if ! install_system_package wl-clipboard wl-clipboard "wl-copy (Wayland clipboard backend)"; then
          warn "failed to install wl-clipboard; trying xclip"
          if ! install_system_package xclip xclip "xclip (X11 clipboard backend)"; then
            warn "failed to install xclip; trying xsel"
            install_system_package xsel xsel "xsel (X11 clipboard backend)" || return 1
          fi
        fi
      else
        if ! install_system_package xclip xclip "xclip (X11 clipboard backend)"; then
          warn "failed to install xclip; trying xsel"
          if ! install_system_package xsel xsel "xsel (X11 clipboard backend)"; then
            warn "failed to install xsel; trying wl-clipboard"
            install_system_package wl-clipboard wl-clipboard "wl-copy (Wayland clipboard backend)" || return 1
          fi
        fi
      fi

      if clipboard_cmd="$(dot_find_available_clipboard_cmd 2>/dev/null)"; then
        ok "clipboard backend installed: $clipboard_cmd"
        return 0
      fi
      err "clipboard backend install completed but command is unavailable (expected one of: $policy)"
      return 1
      ;;
    *)
      warn "unsupported OS for clipboard auto-install: $uname_s (policy: $policy)"
      return 0
      ;;
  esac
}
