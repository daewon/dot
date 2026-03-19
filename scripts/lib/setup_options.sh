#!/usr/bin/env bash

setup_usage() {
  cat <<'EOF'
Usage: ./setup.sh [--dry-run|-n] [--update-packages]

Options:
  --dry-run, -n         Show what would run without applying changes
  --update-packages     Refresh managed package/assets during setup
  --help, -h            Show this help

Env flags:
  INSTALL_OPTIONAL_TOOLS=0|1   Install optional tools
                               (Python/Scala/TypeScript/Rust/watch/codex + metals + vim runtime)
                               (default: prompt on interactive TTY, otherwise 0)
  INSTALL_TMUX_PLUGINS=0|1     Install tmux plugins with TPM (default: 1)
  SET_DEFAULT_SHELL=0|1        Try switching login shell to zsh
                               (default: prompt on interactive TTY [Y/n], otherwise 0)
  UPDATE_PACKAGES=0|1          Refresh managed git clones and non-mise app wrappers
                               (default: 0)
EOF
}

parse_setup_args() {
  # DRY_RUN is a shared setup state variable consumed by scripts/setup.sh.
  # shellcheck disable=SC2034
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run|-n) DRY_RUN=1 ;;
      --update-packages) UPDATE_PACKAGES=1 ;;
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
  dot_resolve_bool_option_01 \
    INSTALL_OPTIONAL_TOOLS \
    "[setup] Install optional tools (Python/Scala/TypeScript/Rust+Helix LSP/formatter/watch/codex + metals launcher + vim runtime)? [y/N]: " \
    0 \
    0 \
    "no"
}

resolve_set_default_shell() {
  dot_resolve_bool_option_01 \
    SET_DEFAULT_SHELL \
    "[setup] Switch default login shell to zsh? [Y/n]: " \
    1 \
    0 \
    "yes"
}
