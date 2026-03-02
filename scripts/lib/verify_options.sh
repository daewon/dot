#!/usr/bin/env bash

verify_usage() {
  cat <<'EOF'
Usage: ./verify.sh [options]

Options:
  --profile NAME         Verification profile: fast | full | stress (default: full)
  --setup-only-loops N   Repeat setup(min profile) N times
  --cycle-loops N        Repeat cleanup->setup cycle N times
  --skip-default-setup   Skip default-profile setup verification
  --default-loops N      Repeat default-profile setup N times
  --no-restore           Skip final restore setup
  --help, -h             Show this help

Environment flags (same meaning as options):
  VERIFY_PROFILE=full
  SETUP_ONLY_LOOPS=<int>=profile default
  CYCLE_LOOPS=<int>=profile default
  RUN_DEFAULT_SETUP=0|1=profile default
  DEFAULT_SETUP_LOOPS=<int>=profile default
  RESTORE_AT_END=0|1=profile default
  VERIFY_CLIPBOARD_RUNTIME=0|1=run sclip runtime check (default: 0)
EOF
}

apply_profile_defaults() {
  case "$VERIFY_PROFILE" in
    fast)
      : "${SETUP_ONLY_LOOPS:=1}"
      : "${CYCLE_LOOPS:=1}"
      : "${RUN_DEFAULT_SETUP:=0}"
      : "${DEFAULT_SETUP_LOOPS:=0}"
      : "${RESTORE_AT_END:=1}"
      ;;
    full)
      : "${SETUP_ONLY_LOOPS:=2}"
      : "${CYCLE_LOOPS:=2}"
      : "${RUN_DEFAULT_SETUP:=1}"
      : "${DEFAULT_SETUP_LOOPS:=1}"
      : "${RESTORE_AT_END:=1}"
      ;;
    stress)
      : "${SETUP_ONLY_LOOPS:=4}"
      : "${CYCLE_LOOPS:=4}"
      : "${RUN_DEFAULT_SETUP:=1}"
      : "${DEFAULT_SETUP_LOOPS:=2}"
      : "${RESTORE_AT_END:=1}"
      ;;
    *)
      err "invalid profile: $VERIFY_PROFILE (expected: fast|full|stress)"
      exit 2
      ;;
  esac
}

parse_verify_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || { err "missing value for --profile"; exit 2; }
        VERIFY_PROFILE="$2"
        shift
        ;;
      --setup-only-loops)
        [ "$#" -ge 2 ] || { err "missing value for --setup-only-loops"; exit 2; }
        SETUP_ONLY_LOOPS="$2"
        shift
        ;;
      --cycle-loops)
        [ "$#" -ge 2 ] || { err "missing value for --cycle-loops"; exit 2; }
        CYCLE_LOOPS="$2"
        shift
        ;;
      --skip-default-setup)
        RUN_DEFAULT_SETUP=0
        ;;
      --default-loops)
        [ "$#" -ge 2 ] || { err "missing value for --default-loops"; exit 2; }
        DEFAULT_SETUP_LOOPS="$2"
        shift
        ;;
      --no-restore)
        RESTORE_AT_END=0
        ;;
      --help|-h)
        verify_usage
        exit 0
        ;;
      *)
        err "unknown option: $1"
        verify_usage
        exit 2
        ;;
    esac
    shift
  done
}

validate_verify_config() {
  apply_profile_defaults
  dot_validate_bool_flags_01 RUN_DEFAULT_SETUP RESTORE_AT_END VERIFY_CLIPBOARD_RUNTIME || exit 2
  dot_validate_nonneg_int_flags SETUP_ONLY_LOOPS CYCLE_LOOPS DEFAULT_SETUP_LOOPS || exit 2
}
