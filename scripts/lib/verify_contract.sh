#!/usr/bin/env bash

assert_tool_id_parse_equals() {
  local raw_tool="$1"
  local expected_id="$2"
  local actual_id=""

  actual_id="$(dot_strip_tool_version "$raw_tool")"
  if [ "$actual_id" != "$expected_id" ]; then
    err "tool id parse mismatch: raw=$raw_tool actual=$actual_id expected=$expected_id"
    return 1
  fi

  ok "tool id parse matched: $raw_tool -> $expected_id"
}

run_repo_local_mise_guard_success() {
  local name="$1"
  local repo_root="$2"
  local logfile="$LOG_DIR/${name}.log"

  if assert_no_repo_local_mise_files "$repo_root" >"$logfile" 2>&1; then
    ok "${name}: success"
    return 0
  fi

  err "${name}: failed (log: $logfile)"
  sed -n '1,160p' "$logfile" >&2 || true
  return 1
}

run_repo_local_mise_guard_expect_failure() {
  local name="$1"
  local repo_root="$2"
  local expected_path="$3"
  local logfile="$LOG_DIR/${name}.log"
  local rc=0

  if assert_no_repo_local_mise_files "$repo_root" >"$logfile" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  if [ "$rc" != "1" ]; then
    err "${name}: expected rc=1, got rc=${rc} (log: $logfile)"
    sed -n '1,160p' "$logfile" >&2 || true
    return 1
  fi
  if ! grep -Fq "repo root must not contain local mise file: $expected_path" "$logfile"; then
    err "${name}: expected forbidden path not found: $expected_path (log: $logfile)"
    sed -n '1,160p' "$logfile" >&2 || true
    return 1
  fi
  ok "${name}: expected failure observed (rc=${rc})"
}

run_contract_guardrails() {
  # shellcheck disable=SC2153  # REPO_ROOT is initialized by scripts/verify.sh before sourcing this file.
  local current_repo_root="$REPO_ROOT"

  CONTRACT_TMP="$(mktemp -d "${TMPDIR:-/tmp}/dot-verify-contract.XXXXXX")"
  mkdir -p "$CONTRACT_TMP/state-unknown/dot"
  cat >"$CONTRACT_TMP/state-unknown/dot/setup-manifest.v1.tsv" <<EOF
version	1
repo_root	$current_repo_root
unknown_kind	/tmp/foo	bar
EOF
  mkdir -p "$CONTRACT_TMP/state-version/dot"
  cat >"$CONTRACT_TMP/state-version/dot/setup-manifest.v1.tsv" <<EOF
version	2
repo_root	$current_repo_root
EOF
  mkdir -p "$CONTRACT_TMP/state-malformed/dot"
  cat >"$CONTRACT_TMP/state-malformed/dot/setup-manifest.v1.tsv" <<EOF
version	1
repo_root	$current_repo_root
symlink	/tmp/foo
EOF
  mkdir -p "$CONTRACT_TMP/repo-clean"
  mkdir -p "$CONTRACT_TMP/repo-mise-toml"
  : >"$CONTRACT_TMP/repo-mise-toml/mise.toml"
  mkdir -p "$CONTRACT_TMP/repo-dot-mise-toml"
  : >"$CONTRACT_TMP/repo-dot-mise-toml/.mise.toml"
  mkdir -p "$CONTRACT_TMP/repo-tool-versions"
  : >"$CONTRACT_TMP/repo-tool-versions/.tool-versions"
  run_expect_failure \
    "setup-invalid-bool-flag" 2 "INSTALL_OPTIONAL_TOOLS must be 0 or 1" \
    env INSTALL_OPTIONAL_TOOLS=2 "$current_repo_root/setup.sh" --dry-run
  run_expect_failure \
    "cleanup-invalid-bool-flag" 2 "REMOVE_GLOBAL_TOOLS must be 0 or 1" \
    env REMOVE_GLOBAL_TOOLS=2 "$current_repo_root/cleanup.sh" --dry-run
  run_expect_failure \
    "cleanup-malformed-manifest-row" 1 "invalid setup manifest row" \
    env XDG_STATE_HOME="$CONTRACT_TMP/state-malformed" "$current_repo_root/cleanup.sh" --dry-run
  run_expect_failure \
    "cleanup-unknown-manifest-kind" 1 "unknown setup manifest entry" \
    env XDG_STATE_HOME="$CONTRACT_TMP/state-unknown" "$current_repo_root/cleanup.sh" --dry-run
  run_with_log \
    "cleanup-manifest-version-fallback" \
    env XDG_STATE_HOME="$CONTRACT_TMP/state-version" "$current_repo_root/cleanup.sh" --dry-run
  grep -Fq "falling back to static cleanup targets" "$LOG_DIR/cleanup-manifest-version-fallback.log" \
    || { err "cleanup-manifest-version-fallback: expected fallback message"; return 1; }
  ok "cleanup-manifest-version-fallback: fallback path confirmed"
  assert_tool_id_parse_equals "npm:@openai/codex" "npm:@openai/codex"
  assert_tool_id_parse_equals "npm:@openai/codex@latest" "npm:@openai/codex"
  assert_tool_id_parse_equals "rust[profile=default,components=rust-src,rust-analyzer]@1.94.0" "rust"
  run_repo_local_mise_guard_success \
    "repo-local-mise-guard-clean" \
    "$CONTRACT_TMP/repo-clean"
  run_repo_local_mise_guard_expect_failure \
    "repo-local-mise-guard-mise-toml" \
    "$CONTRACT_TMP/repo-mise-toml" \
    "$CONTRACT_TMP/repo-mise-toml/mise.toml"
  run_repo_local_mise_guard_expect_failure \
    "repo-local-mise-guard-dot-mise-toml" \
    "$CONTRACT_TMP/repo-dot-mise-toml" \
    "$CONTRACT_TMP/repo-dot-mise-toml/.mise.toml"
  run_repo_local_mise_guard_expect_failure \
    "repo-local-mise-guard-tool-versions" \
    "$CONTRACT_TMP/repo-tool-versions" \
    "$CONTRACT_TMP/repo-tool-versions/.tool-versions"
  cleanup_tmp_artifacts
  CONTRACT_TMP=""
}
