#!/usr/bin/env bash

run_contract_guardrails() {
  CONTRACT_TMP="$(mktemp -d "${TMPDIR:-/tmp}/dot-verify-contract.XXXXXX")"
  mkdir -p "$CONTRACT_TMP/state-unknown/dot"
  cat >"$CONTRACT_TMP/state-unknown/dot/setup-manifest.v1.tsv" <<EOF
version	1
repo_root	$REPO_ROOT
unknown_kind	/tmp/foo	bar
EOF
  mkdir -p "$CONTRACT_TMP/state-version/dot"
  cat >"$CONTRACT_TMP/state-version/dot/setup-manifest.v1.tsv" <<EOF
version	2
repo_root	$REPO_ROOT
EOF
  mkdir -p "$CONTRACT_TMP/state-malformed/dot"
  cat >"$CONTRACT_TMP/state-malformed/dot/setup-manifest.v1.tsv" <<EOF
version	1
repo_root	$REPO_ROOT
symlink	/tmp/foo
EOF
  run_expect_failure \
    "setup-invalid-bool-flag" 2 "INSTALL_OPTIONAL_TOOLS must be 0 or 1" \
    env INSTALL_OPTIONAL_TOOLS=2 "$REPO_ROOT/setup.sh" --dry-run
  run_expect_failure \
    "cleanup-invalid-bool-flag" 2 "REMOVE_GLOBAL_TOOLS must be 0 or 1" \
    env REMOVE_GLOBAL_TOOLS=2 "$REPO_ROOT/cleanup.sh" --dry-run
  run_expect_failure \
    "cleanup-malformed-manifest-row" 1 "invalid setup manifest row" \
    env XDG_STATE_HOME="$CONTRACT_TMP/state-malformed" "$REPO_ROOT/cleanup.sh" --dry-run
  run_expect_failure \
    "cleanup-unknown-manifest-kind" 1 "unknown setup manifest entry" \
    env XDG_STATE_HOME="$CONTRACT_TMP/state-unknown" "$REPO_ROOT/cleanup.sh" --dry-run
  run_with_log \
    "cleanup-manifest-version-fallback" \
    env XDG_STATE_HOME="$CONTRACT_TMP/state-version" "$REPO_ROOT/cleanup.sh" --dry-run
  grep -Fq "falling back to static cleanup targets" "$LOG_DIR/cleanup-manifest-version-fallback.log" \
    || { err "cleanup-manifest-version-fallback: expected fallback message"; return 1; }
  ok "cleanup-manifest-version-fallback: fallback path confirmed"
  cleanup_tmp_artifacts
  CONTRACT_TMP=""
}
