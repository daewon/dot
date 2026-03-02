#!/usr/bin/env bash

setup_usage() {
  cat <<'EOF'
Usage: ./setup.sh [--dry-run|-n]

Options:
  --dry-run, -n  Show what would run without applying changes
  --help, -h     Show this help

Env flags:
  INSTALL_OPTIONAL_TOOLS=0|1   Install optional tools
                               (Python/Scala/TypeScript/dmux/codex + metals + vim runtime)
                               (default: prompt on interactive TTY, otherwise 0)
  INSTALL_TMUX_PLUGINS=0|1     Install tmux plugins with TPM (default: 1)
  SET_DEFAULT_SHELL=0|1        Try switching login shell to zsh
                               (default: prompt on interactive TTY [Y/n], otherwise 0)
EOF
}

parse_setup_args() {
  # DRY_RUN is a shared setup state variable consumed by scripts/setup.sh.
  # shellcheck disable=SC2034
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run|-n) DRY_RUN=1 ;;
      --help|-h)
        setup_usage
        exit 0
        ;;
      *)
        err "unknown option: $1"
        setup_usage
        exit 2
        ;;
    esac
    shift
  done
}

resolve_install_optional_tools() {
  local reply=""
  local selected_value=""

  if [ -n "$INSTALL_OPTIONAL_TOOLS" ]; then
    return
  fi

  if dot_is_interactive_tty; then
    printf '\n[setup] Install optional tools (Python/Scala/TypeScript/dmux/codex + metals launcher + vim runtime)? [y/N]: '
    IFS= read -r reply || true
    if selected_value="$(dot_parse_yes_no_to_bool_01 "$reply")"; then
      INSTALL_OPTIONAL_TOOLS="$selected_value"
    else
      warn "invalid response '$reply'; defaulting to no"
      INSTALL_OPTIONAL_TOOLS=0
    fi
    ok "interactive selection: INSTALL_OPTIONAL_TOOLS=$INSTALL_OPTIONAL_TOOLS"
    return
  fi

  INSTALL_OPTIONAL_TOOLS=0
}

resolve_set_default_shell() {
  local reply=""
  local selected_value=""

  if [ -n "$SET_DEFAULT_SHELL" ]; then
    return
  fi

  if dot_is_interactive_tty; then
    printf '\n[setup] Switch default login shell to zsh? [Y/n]: '
    IFS= read -r reply || true
    case "$reply" in
      [yY]|[yY][eE][sS]|"")
        selected_value=1
        ;;
      [nN]|[nN][oO])
        selected_value=0
        ;;
      *)
        warn "invalid response '$reply'; defaulting to yes"
        selected_value=1
        ;;
    esac
    SET_DEFAULT_SHELL="$selected_value"
    ok "interactive selection: SET_DEFAULT_SHELL=$SET_DEFAULT_SHELL"
    return
  fi

  SET_DEFAULT_SHELL=0
}
