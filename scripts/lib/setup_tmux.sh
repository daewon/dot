#!/usr/bin/env bash

print_tmux_backend_hint() {
  local tmux_tool=""
  tmux_tool="$(dot_preferred_tmux_tool)"
  warn "legacy tmux backend detected (source build path)"
  cat <<EOF
    prefer prebuilt backend:
      mise install $tmux_tool
      mise use -g $tmux_tool
EOF
}

dot_preferred_tmux_tool() {
  local tmux_version=""
  local tool=""
  tmux_version="$(dot_tmux_version_from_required)"
  for tool in "${DOT_REQUIRED_MISE_TOOLS[@]}"; do
    case "$tool" in
      github:tmux/tmux-builds@*)
        printf '%s\n' "$tool"
        return 0
        ;;
    esac
  done
  printf '%s\n' "github:tmux/tmux-builds@$tmux_version"
}

dot_tmux_version_from_required() {
  local tool=""
  if tool="$(dot_required_tmux_tool 2>/dev/null)"; then
    printf '%s\n' "${tool##*@}"
    return 0
  fi
  printf '%s\n' "3.6a"
}

dot_fallback_tmux_tool() {
  local preferred_tmux_tool=""
  local tmux_version=""
  preferred_tmux_tool="$(dot_preferred_tmux_tool)"
  tmux_version="$(dot_tmux_version_from_required)"
  case "$preferred_tmux_tool" in
    github:tmux/tmux-builds@*)
      printf '%s\n' "asdf:tmux@${preferred_tmux_tool##*@}"
      ;;
    asdf:tmux@*)
      printf '%s\n' "github:tmux/tmux-builds@${preferred_tmux_tool##*@}"
      ;;
    *)
      printf '%s\n' "asdf:tmux@$tmux_version"
      ;;
  esac
}

dot_detect_tmux_backend_from_path() {
  local tmux_path="$1"
  case "$tmux_path" in
    */github-tmux-tmux-builds/*|*/installs/tmux/*)
      printf '%s\n' "prebuilt"
      ;;
    */asdf-tmux/*)
      printf '%s\n' "source"
      ;;
    *)
      printf '%s\n' "unknown"
      ;;
  esac
}

dot_required_tmux_tool() {
  local tool=""
  for tool in "${DOT_REQUIRED_MISE_TOOLS[@]}"; do
    case "$tool" in
      github:tmux/tmux-builds@*|asdf:tmux@*)
        printf '%s\n' "$tool"
        return 0
        ;;
    esac
  done
  return 1
}

dot_tmux_backend_from_tool() {
  local tmux_tool="${1:-}"
  case "$tmux_tool" in
    github:tmux/tmux-builds@*)
      printf '%s\n' "prebuilt"
      ;;
    asdf:tmux@*)
      printf '%s\n' "source"
      ;;
    *)
      printf '%s\n' "unknown"
      ;;
  esac
}

dot_required_tmux_backend() {
  local tmux_tool=""
  if ! tmux_tool="$(dot_required_tmux_tool 2>/dev/null)"; then
    printf '%s\n' "unknown"
    return 1
  fi
  dot_tmux_backend_from_tool "$tmux_tool"
}

dot_required_tmux_uses_source_backend() {
  [ "$(dot_required_tmux_backend)" = "source" ]
}

dot_tmux_remove_tool_for_backend() {
  local backend="$1"
  case "$backend" in
    prebuilt)
      printf '%s\n' "github:tmux/tmux-builds"
      ;;
    source)
      printf '%s\n' "asdf:tmux"
      ;;
    *)
      return 1
      ;;
  esac
}

dot_tmux_fallback_tool_for_backend() {
  local backend="$1"
  case "$backend" in
    prebuilt)
      dot_fallback_tmux_tool
      ;;
    source)
      dot_preferred_tmux_tool
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_tmux_source_build_prerequisites() {
  local need_toolchain=0
  local need_pkg_config=0
  local need_ncurses=0

  if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
    need_toolchain=1
  fi
  if ! command -v make >/dev/null 2>&1; then
    need_toolchain=1
  fi
  if ! command -v pkg-config >/dev/null 2>&1; then
    need_pkg_config=1
  fi
  if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists ncurses 2>/dev/null; then
    :
  elif [ -e /usr/include/ncurses.h ] || [ -e /usr/include/ncurses/ncurses.h ]; then
    :
  else
    need_ncurses=1
  fi

  if [ "$need_toolchain" = "0" ] && [ "$need_pkg_config" = "0" ] && [ "$need_ncurses" = "0" ]; then
    ok "tmux source-build prerequisites already present"
    return 0
  fi

  warn "installing tmux source-build prerequisites"

  if command -v apt-get >/dev/null 2>&1; then
    if [ "$need_toolchain" = "1" ]; then
      install_system_package build-essential build-essential "tmux build toolchain" || return 1
    fi
    if [ "$need_pkg_config" = "1" ]; then
      install_system_package pkg-config pkg-config "pkg-config for tmux build" || return 1
    fi
    if [ "$need_ncurses" = "1" ]; then
      if ! install_system_package libncurses-dev ncurses "ncurses headers for tmux build"; then
        install_system_package ncurses-dev ncurses "ncurses headers for tmux build" || return 1
      fi
    fi
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    if [ "$need_pkg_config" = "1" ]; then
      run brew install pkg-config
    fi
    if [ "$need_ncurses" = "1" ]; then
      run brew install ncurses
    fi
    if [ "$need_toolchain" = "1" ]; then
      warn "compiler toolchain is missing; install Xcode CLT manually: xcode-select --install"
      return 1
    fi
    return 0
  fi

  err "tmux source-build prerequisites missing: compiler toolchain, pkg-config, ncurses headers"
  return 1
}

resolve_tmux_bin_or_fail() {
  local phase="$1"
  local tmux_bin=""

  if ! ensure_cmd_on_path tmux; then
    err "required command not found after ${phase}: tmux"
    return 1
  fi
  if ! tmux_bin="$(dot_find_cmd tmux 2>/dev/null)"; then
    err "required command not found after ${phase}: tmux"
    return 1
  fi

  printf '%s\n' "$tmux_bin"
}

check_tmux_binary_health() {
  local tmux_bin="$1"
  local success_message="$2"
  local failure_message="$3"
  local failure_level="${4:-warn}"
  local failure_head_lines="${5:-2}"
  local check_output=""

  check_output="$(mktemp)"
  if "$tmux_bin" -V >"$check_output" 2>&1; then
    ok "${success_message}: $(head -n 1 "$check_output")"
    rm -f "$check_output"
    return 0
  fi

  case "$failure_level" in
    err)
      err "${failure_message}: $tmux_bin"
      head -n "$failure_head_lines" "$check_output" | sed 's/^/    /' >&2
      ;;
    *)
      warn "${failure_message}: $tmux_bin"
      head -n "$failure_head_lines" "$check_output" | sed 's/^/    /'
      ;;
  esac
  rm -f "$check_output"
  return 1
}

ensure_working_tmux_binary_or_fallback() {
  local tmux_bin=""
  local active_backend=""
  local required_backend=""
  local fallback_backend=""
  local fallback_tool=""
  local remove_tool=""

  if [ "$DRY_RUN" = "1" ]; then
    ok "tmux health check skipped in dry-run mode"
    return 0
  fi

  if ! tmux_bin="$(resolve_tmux_bin_or_fail "install")"; then
    return 1
  fi

  if check_tmux_binary_health "$tmux_bin" "tmux ready" "tmux failed health check"; then
    return 0
  fi

  active_backend="$(dot_detect_tmux_backend_from_path "$tmux_bin")"
  fallback_backend="$active_backend"
  case "$active_backend" in
    prebuilt|source)
      :
      ;;
    *)
      required_backend="$(dot_required_tmux_backend || true)"
      warn "unable to infer tmux backend from path; using required backend policy: ${required_backend:-unknown}"
      fallback_backend="$required_backend"
      ;;
  esac

  if ! fallback_tool="$(dot_tmux_fallback_tool_for_backend "$fallback_backend" 2>/dev/null)"; then
    err "unable to determine tmux fallback backend (path=$tmux_bin, active=${active_backend:-unknown}, required=${required_backend:-unknown})"
    return 1
  fi
  if ! remove_tool="$(dot_tmux_remove_tool_for_backend "$fallback_backend" 2>/dev/null)"; then
    err "unable to resolve tmux remove tool for backend: ${fallback_backend:-unknown}"
    return 1
  fi

  case "$fallback_tool" in
    asdf:tmux@*)
      ensure_tmux_source_build_prerequisites
      ;;
  esac

  warn "switching tmux backend to fallback: $fallback_tool"
  run_mise_use_global "$fallback_tool"
  run mise use -g --remove "$remove_tool" || true

  if ! tmux_bin="$(resolve_tmux_bin_or_fail "tmux fallback")"; then
    return 1
  fi

  if check_tmux_binary_health "$tmux_bin" "tmux fallback ready" "tmux is still unusable after fallback" "err" 4; then
    return 0
  fi
  return 1
}
