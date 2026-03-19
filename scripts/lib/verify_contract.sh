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

assert_yes_no_default_parse_equals() {
  local raw_value="$1"
  local default_value="$2"
  local expected_value="$3"
  local actual_value=""

  if ! actual_value="$(dot_parse_yes_no_default_to_bool_01 "$raw_value" "$default_value")"; then
    err "yes/no parse failed: raw=$raw_value default=$default_value"
    return 1
  fi
  if [ "$actual_value" != "$expected_value" ]; then
    err "yes/no parse mismatch: raw=$raw_value default=$default_value actual=$actual_value expected=$expected_value"
    return 1
  fi

  ok "yes/no parse matched: raw=$raw_value default=$default_value -> $expected_value"
}

update_origin_repo_files() {
  local bare_repo="$1"
  local commit_message="$2"
  shift 2
  local worktree=""
  local rel_path=""
  local content=""

  worktree="$(mktemp -d "$CONTRACT_TMP/origin-work.XXXXXX")"
  git clone -q "$bare_repo" "$worktree"
  git -C "$worktree" config user.email "dot-verify@example.com"
  git -C "$worktree" config user.name "dot verify"

  while [ "$#" -gt 0 ]; do
    rel_path="$1"
    content="$2"
    shift 2
    mkdir -p "$(dirname "$worktree/$rel_path")"
    printf '%s\n' "$content" >"$worktree/$rel_path"
  done

  git -C "$worktree" add .
  git -C "$worktree" commit -q -m "$commit_message"
  git -C "$worktree" push -q origin HEAD:main
  git --git-dir="$bare_repo" symbolic-ref HEAD refs/heads/main
  rm -rf "$worktree"
}

make_managed_origin_repo() {
  local bare_repo="$1"
  shift
  local worktree=""
  local rel_path=""
  local content=""

  mkdir -p "$(dirname "$bare_repo")"
  git init --bare -q "$bare_repo"
  worktree="$(mktemp -d "$CONTRACT_TMP/origin-seed.XXXXXX")"
  git init -q "$worktree"
  git -C "$worktree" config user.email "dot-verify@example.com"
  git -C "$worktree" config user.name "dot verify"

  while [ "$#" -gt 0 ]; do
    rel_path="$1"
    content="$2"
    shift 2
    mkdir -p "$(dirname "$worktree/$rel_path")"
    printf '%s\n' "$content" >"$worktree/$rel_path"
  done

  git -C "$worktree" add .
  git -C "$worktree" commit -q -m "seed"
  git -C "$worktree" branch -M main
  git -C "$worktree" remote add origin "$bare_repo"
  git -C "$worktree" push -q -u origin main
  git --git-dir="$bare_repo" symbolic-ref HEAD refs/heads/main
  rm -rf "$worktree"
}

make_managed_clone_fixture() {
  local clone_path="$1"
  local clone_url="$2"
  local required_path="${3:-}"

  mkdir -p "$clone_path"
  git init -q "$clone_path"
  git -C "$clone_path" remote add origin "$clone_url"
  if [ -n "$required_path" ]; then
    mkdir -p "$(dirname "$clone_path/$required_path")"
    : >"$clone_path/$required_path"
  fi
}

assert_setup_update_refresh_dry_run_log_contract() {
  local logfile="$1"
  local home_dir="$2"

  [ -f "$logfile" ] || { err "update dry-run log missing: $logfile"; return 1; }

  grep -Fq "managed package refresh enabled (UPDATE_PACKAGES=1)" "$logfile" \
    || { err "update dry-run log missing UPDATE_PACKAGES marker"; return 1; }
  grep -Fq "[dry-run] git -C $home_dir/.zprezto pull --ff-only" "$logfile" \
    || { err "update dry-run log missing prezto refresh command"; return 1; }
  grep -Fq "[dry-run] git -C $home_dir/.zprezto submodule sync --recursive" "$logfile" \
    || { err "update dry-run log missing prezto submodule sync command"; return 1; }
  grep -Fq "[dry-run] git -C $home_dir/.zprezto submodule update --init --recursive" "$logfile" \
    || { err "update dry-run log missing prezto submodule update command"; return 1; }
  grep -Fq "[dry-run] git -C $home_dir/.tmux/plugins/tpm pull --ff-only" "$logfile" \
    || { err "update dry-run log missing tmux tpm refresh command"; return 1; }
  grep -Fq "prezto would be refreshed" "$logfile" \
    || { err "update dry-run log missing prezto refresh result"; return 1; }
  grep -Fq "tmux tpm would be refreshed" "$logfile" \
    || { err "update dry-run log missing tmux tpm refresh result"; return 1; }
  if grep -Fq "[error]" "$logfile"; then
    err "update dry-run log contains [error] lines: $logfile"
    return 1
  fi

  ok "update dry-run refresh contract passed"
}

write_fake_mise_fixture() {
  local dst="$1"

  cat >"$dst" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_dir="${DOT_FAKE_LOG_DIR:?}"
printf '%s\n' "$*" >>"$log_dir/mise.log"

case "${1:-}" in
  use)
    exit 0
    ;;
  current)
    printf 'node 24.13.1 (fixture)\n'
    printf 'tmux 3.6a (fixture)\n'
    exit 0
    ;;
  which)
    if [ -n "${2:-}" ]; then
      command -v "$2"
      exit $?
    fi
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$dst"
}

write_fake_cs_fixture() {
  local dst="$1"

  cat >"$dst" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_dir="${DOT_FAKE_LOG_DIR:?}"
printf '%s\n' "$*" >>"$log_dir/cs.log"

if [ "${1:-}" = "--help" ]; then
  exit 0
fi

if [ "${1:-}" = "install" ]; then
  install_dir=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --install-dir)
        install_dir="$2"
        shift 2
        ;;
      metals)
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
  mkdir -p "$install_dir"
  cat >"$install_dir/metals" <<'EOS'
#!/usr/bin/env bash
echo "metals refreshed by fixture"
EOS
  chmod +x "$install_dir/metals"
  exit 0
fi

exit 0
EOF
  chmod +x "$dst"
}

write_fake_curl_fixture() {
  local dst="$1"

  cat >"$dst" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_dir="${DOT_FAKE_LOG_DIR:?}"
printf '%s\n' "$*" >>"$log_dir/curl.log"

output=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      output="$2"
      shift 2
      ;;
    -L|-f|-s|-S)
      shift
      ;;
    *)
      shift
      ;;
  esac
done

mkdir -p "$(dirname "$output")"
cat >"$output" <<'EOS'
#!/usr/bin/env bash
echo "mill refreshed by fixture"
EOS
chmod +x "$output"
EOF
  chmod +x "$dst"
}

write_fake_tmux_fixture() {
  local dst="$1"

  cat >"$dst" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-V" ]; then
  printf 'tmux 3.6a\n'
fi
EOF
  chmod +x "$dst"
}

write_fake_xclip_fixture() {
  local dst="$1"

  cat >"$dst" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
EOF
  chmod +x "$dst"
}

assert_git_clone_matches_origin_head() {
  local clone_path="$1"
  local bare_repo="$2"
  local label="$3"
  local clone_head=""
  local origin_head=""

  clone_head="$(git -C "$clone_path" rev-parse HEAD)"
  origin_head="$(git --git-dir="$bare_repo" rev-parse refs/heads/main)"
  if [ "$clone_head" != "$origin_head" ]; then
    err "$label head mismatch after refresh: clone=$clone_head origin=$origin_head"
    return 1
  fi

  ok "$label refresh head matched origin"
}

assert_setup_update_refresh_live_log_contract() {
  local logfile="$1"

  [ -f "$logfile" ] || { err "update live log missing: $logfile"; return 1; }

  grep -Fq "prezto refreshed" "$logfile" \
    || { err "update live log missing prezto refresh result"; return 1; }
  grep -Fq "tmux tpm refreshed" "$logfile" \
    || { err "update live log missing tmux tpm refresh result"; return 1; }
  grep -Fq "vim runtime refreshed" "$logfile" \
    || { err "update live log missing vim runtime refresh result"; return 1; }
  grep -Fq "metals refreshed via coursier:" "$logfile" \
    || { err "update live log missing metals refresh result"; return 1; }
  grep -Fq "mill 1.1.2 refreshed via direct download" "$logfile" \
    || { err "update live log missing mill refresh result"; return 1; }
  grep -Fq "vim plugins updated" "$logfile" \
    || { err "update live log missing vim plugin update result"; return 1; }
  if grep -Fq "[error]" "$logfile"; then
    err "update live log contains [error] lines: $logfile"
    return 1
  fi

  ok "update live refresh contract passed"
}

run_setup_update_refresh_live_contract() {
  local repo_root="$1"
  local home_dir="$CONTRACT_TMP/home-update-live"
  local state_home="$CONTRACT_TMP/state-update-live"
  local fake_bin="$CONTRACT_TMP/fake-bin"
  local fake_log_dir="$CONTRACT_TMP/fake-log"
  local remote_root="$CONTRACT_TMP/remotes"
  local prezto_origin="$remote_root/sorin-ionescu/prezto.git"
  local tpm_origin="$remote_root/tmux-plugins/tpm.git"
  local vim_origin="$remote_root/amix/vimrc.git"

  mkdir -p "$home_dir/.tmux/plugins" "$home_dir/.local/bin" "$state_home" "$fake_bin" "$fake_log_dir"

  write_fake_mise_fixture "$fake_bin/mise"
  write_fake_cs_fixture "$fake_bin/cs"
  write_fake_curl_fixture "$fake_bin/curl"
  write_fake_tmux_fixture "$fake_bin/tmux"
  write_fake_xclip_fixture "$fake_bin/xclip"

  make_managed_origin_repo \
    "$prezto_origin" \
    "init.zsh" "# prezto seed" \
    "runcoms/zlogin" "# zlogin seed" \
    "runcoms/zlogout" "# zlogout seed" \
    "runcoms/zprofile" "# zprofile seed" \
    "runcoms/zshenv" "# zshenv seed"
  make_managed_origin_repo \
    "$tpm_origin" \
    "tpm" "#!/usr/bin/env bash"
  make_managed_origin_repo \
    "$vim_origin" \
    "vimrcs/basic.vim" "\" basic" \
    "vimrcs/filetypes.vim" "\" filetypes" \
    "vimrcs/plugins_config.vim" "\" plugins" \
    "vimrcs/extended.vim" "\" extended" \
    "update_plugins.py" "print('fixture vim plugins updated')"

  git clone -q "$prezto_origin" "$home_dir/.zprezto"
  git clone -q "$tpm_origin" "$home_dir/.tmux/plugins/tpm"
  git clone -q "$vim_origin" "$home_dir/.vim_runtime"

  cat >"$home_dir/.local/bin/metals" <<'EOF'
#!/usr/bin/env bash
echo "stale metals"
EOF
  chmod +x "$home_dir/.local/bin/metals"
  cat >"$home_dir/.local/bin/mill" <<'EOF'
#!/usr/bin/env bash
echo "stale mill"
EOF
  chmod +x "$home_dir/.local/bin/mill"

  update_origin_repo_files \
    "$prezto_origin" \
    "refresh prezto" \
    "init.zsh" "# prezto refreshed" \
    "runcoms/zlogin" "# zlogin refreshed" \
    "runcoms/zlogout" "# zlogout refreshed" \
    "runcoms/zprofile" "# zprofile refreshed" \
    "runcoms/zshenv" "# zshenv refreshed"
  update_origin_repo_files \
    "$tpm_origin" \
    "refresh tpm" \
    "tpm" "#!/usr/bin/env bash"$'\n'"echo refreshed"
  update_origin_repo_files \
    "$vim_origin" \
    "refresh vim runtime" \
    "vimrcs/basic.vim" "\" basic refreshed" \
    "vimrcs/filetypes.vim" "\" filetypes refreshed" \
    "vimrcs/plugins_config.vim" "\" plugins refreshed" \
    "vimrcs/extended.vim" "\" extended refreshed" \
    "update_plugins.py" "print('fixture vim plugins refreshed')"

  run_with_log \
    "setup-update-refresh-live" \
    env HOME="$home_dir" \
      XDG_STATE_HOME="$state_home" \
      PATH="$fake_bin:/usr/bin:/bin" \
      DOT_FAKE_LOG_DIR="$fake_log_dir" \
      INSTALL_OPTIONAL_TOOLS=1 \
      INSTALL_TMUX_PLUGINS=0 \
      SET_DEFAULT_SHELL=0 \
      UPDATE_PACKAGES=1 \
      "$repo_root/setup.sh"

  assert_setup_update_refresh_live_log_contract "$LOG_DIR/setup-update-refresh-live.log"
  assert_git_clone_matches_origin_head "$home_dir/.zprezto" "$prezto_origin" "prezto"
  assert_git_clone_matches_origin_head "$home_dir/.tmux/plugins/tpm" "$tpm_origin" "tmux tpm"
  assert_git_clone_matches_origin_head "$home_dir/.vim_runtime" "$vim_origin" "vim runtime"
  grep -Fq "metals refreshed by fixture" "$home_dir/.local/bin/metals" \
    || { err "metals launcher was not refreshed in live update fixture"; return 1; }
  grep -Fq "mill refreshed by fixture" "$home_dir/.local/bin/mill" \
    || { err "mill launcher was not refreshed in live update fixture"; return 1; }
  grep -Fq "install --install-dir $home_dir/.local/bin metals" "$fake_log_dir/cs.log" \
    || { err "coursier install command was not observed in live update fixture"; return 1; }
  grep -Fq "$home_dir/.local/bin/mill" "$fake_log_dir/curl.log" \
    || { err "mill download command was not observed in live update fixture"; return 1; }
  ok "update live fixture refreshed managed clones and wrappers"
}

run_setup_update_refresh_contract() {
  local repo_root="$1"
  local home_dir="$CONTRACT_TMP/home-update-refresh"

  mkdir -p "$home_dir/.tmux/plugins"
  make_managed_clone_fixture \
    "$home_dir/.zprezto" \
    "https://github.com/sorin-ionescu/prezto.git" \
    "init.zsh"
  make_managed_clone_fixture \
    "$home_dir/.tmux/plugins/tpm" \
    "https://github.com/tmux-plugins/tpm" \
    "tpm"

  run_with_log \
    "setup-update-refresh-dry-run" \
    env HOME="$home_dir" \
      INSTALL_OPTIONAL_TOOLS=0 \
      INSTALL_TMUX_PLUGINS=0 \
      SET_DEFAULT_SHELL=0 \
      UPDATE_PACKAGES=1 \
      "$repo_root/setup.sh" --dry-run
  assert_setup_update_refresh_dry_run_log_contract \
    "$LOG_DIR/setup-update-refresh-dry-run.log" \
    "$home_dir"
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
  run_setup_update_refresh_contract "$current_repo_root"
  run_setup_update_refresh_live_contract "$current_repo_root"
  run_expect_failure \
    "setup-invalid-bool-flag" 2 "INSTALL_OPTIONAL_TOOLS must be 0 or 1" \
    env INSTALL_OPTIONAL_TOOLS=2 "$current_repo_root/setup.sh" --dry-run
  run_expect_failure \
    "setup-invalid-update-flag" 2 "UPDATE_PACKAGES must be 0 or 1" \
    env UPDATE_PACKAGES=2 "$current_repo_root/setup.sh" --dry-run
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
  assert_tool_id_parse_equals "rust[profile=default,components=rust-src,rustfmt,clippy]@1.94.0" "rust"
  assert_tool_id_parse_equals "rust-analyzer@2026-03-02" "rust-analyzer"
  assert_tool_id_parse_equals "watchexec@2.5.0" "watchexec"
  assert_yes_no_default_parse_equals "" 0 "0"
  assert_yes_no_default_parse_equals "" 1 "1"
  assert_yes_no_default_parse_equals "yes" 0 "1"
  assert_yes_no_default_parse_equals "no" 1 "0"
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
