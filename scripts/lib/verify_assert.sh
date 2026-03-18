#!/usr/bin/env bash

count_matches() {
  local pattern="$1"
  local file="$2"
  local c=""

  c="$(grep -c "$pattern" "$file" 2>/dev/null || true)"
  printf '%s' "${c:-0}"
}

count_git_include() {
  dot_git_include_count "$GIT_SHARED_INCLUDE_PATH"
}

assert_github_credential_helper_contract() {
  local host=""
  local key=""
  local helper_values=""
  local origin=""
  local origin_file=""

  for host in "${DOT_GH_CREDENTIAL_HOSTS[@]}"; do
    key="credential.${host}.helper"
    helper_values="$(git config --get-all "$key" 2>/dev/null || true)"
    printf '%s\n' "$helper_values" | grep -Fqx "$DOT_GH_CREDENTIAL_HELPER" \
      || { err "missing include-managed gh credential helper for $host"; return 1; }

    while IFS=$'\t' read -r origin _; do
      [ -n "$origin" ] || continue
      case "$origin" in
        file:*)
          origin_file="${origin#file:}"
          ;;
        *)
          continue
          ;;
      esac
      if [ "$origin_file" != "$GIT_SHARED_INCLUDE_PATH" ]; then
        err "global config must not define $key directly (found in: $origin_file)"
        return 1
      fi
    done < <(git config --global --show-origin --get-all "$key" 2>/dev/null || true)
  done

  ok "git credential helper contract passed"
}

assert_helix_rust_setup() {
  local helix_languages="$HOME/.config/helix/languages.toml"
  local health_output=""
  local health_clean=""
  local ra_bin=""
  local rf_bin=""
  local hx_bin=""

  [ -f "$helix_languages" ] || { err "missing helix languages config: $helix_languages"; return 1; }
  grep -Fq 'name = "rust"' "$helix_languages" || { err "helix rust language block missing: $helix_languages"; return 1; }
  grep -Fq 'command = "rust-analyzer"' "$helix_languages" || { err "helix rust-analyzer command missing: $helix_languages"; return 1; }
  grep -Fq 'command = "rustfmt"' "$helix_languages" || { err "helix rust formatter missing: $helix_languages"; return 1; }

  ra_bin="$(dot_find_cmd rust-analyzer 2>/dev/null || true)"
  rf_bin="$(dot_find_cmd rustfmt 2>/dev/null || true)"
  hx_bin="$(dot_find_cmd hx 2>/dev/null || true)"

  [ -n "$ra_bin" ] || { err "rust-analyzer binary not found on PATH or via mise"; return 1; }
  [ -n "$rf_bin" ] || { err "rustfmt binary not found on PATH or via mise"; return 1; }
  [ -n "$hx_bin" ] || { err "hx binary not found on PATH or via mise"; return 1; }

  "$ra_bin" --version >/dev/null 2>&1 || { err "rust-analyzer is not runnable after setup"; return 1; }
  "$rf_bin" --version >/dev/null 2>&1 || { err "rustfmt is not runnable after setup"; return 1; }

  health_output="$(NO_COLOR=1 "$hx_bin" --health rust 2>/dev/null || true)"
  [ -n "$health_output" ] || { err "hx --health rust returned no output"; return 1; }
  health_clean="$(printf '%s\n' "$health_output" | sed -E 's/\x1b\[[0-9;]*m//g')"
  printf '%s\n' "$health_clean" | grep -Fq 'rust-analyzer:' || { err "helix rust health missing rust-analyzer entry"; return 1; }
  printf '%s\n' "$health_clean" | grep -Fq 'Configured formatter:' || { err "helix rust health missing formatter entry"; return 1; }
  if printf '%s\n' "$health_clean" | grep -Fq 'Configured formatter: None'; then
    err "helix rust formatter is not configured"
    return 1
  fi

  ok "helix rust health check passed"
}

tool_available() {
  local cmd="$1"

  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if command -v mise >/dev/null 2>&1 && mise which "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

assert_no_repo_local_mise_files() {
  local repo_root="${1:-$REPO_ROOT}"
  local path=""
  local filename=""
  local -a forbidden_files=(
    "mise.toml"
    ".mise.toml"
    ".tool-versions"
  )

  [ -d "$repo_root" ] || { err "repo root directory not found for local mise guard: $repo_root"; return 1; }

  for filename in "${forbidden_files[@]}"; do
    path="$repo_root/$filename"
    if [ -e "$path" ] || [ -L "$path" ]; then
      err "repo root must not contain local mise file: $path"
      err "this repo is global-policy-only; manage tools via scripts/lib/toolset.sh + setup.sh"
      return 1
    fi
  done

  ok "repo local mise file guard passed"
}

check_clipboard_runtime_if_enabled() {
  local clipboard_policy="$1"
  local sclip_bin=""
  local backend=""

  if [ "$VERIFY_CLIPBOARD_RUNTIME" != "1" ]; then
    return 0
  fi

  sclip_bin="$(dot_find_cmd sclip 2>/dev/null || true)"
  if [ -z "$sclip_bin" ] && [ -x "$HOME/.local/bin/sclip" ]; then
    sclip_bin="$HOME/.local/bin/sclip"
  fi
  if [ -z "$sclip_bin" ]; then
    err "clipboard runtime check enabled but sclip is unavailable on PATH"
    return 1
  fi

  if ! backend="$(dot_select_clipboard_runtime_backend 2>/dev/null)"; then
    warn "clipboard runtime check skipped: no active runtime backend context (policy=$clipboard_policy)"
    return 0
  fi

  if printf 'dot-verify-clipboard\n' | "$sclip_bin" >/dev/null 2>&1; then
    ok "clipboard runtime check passed via sclip (backend=$backend)"
    return 0
  fi

  err "clipboard runtime check failed via sclip (backend=$backend)"
  return 1
}

assert_setup_dry_run_log_contract() {
  local logfile="$1"
  local clipboard_policy=""

  [ -f "$logfile" ] || { err "setup dry-run log missing: $logfile"; return 1; }

  grep -Fq "dry-run mode enabled (no files or settings will be changed)" "$logfile" \
    || { err "setup dry-run log missing preflight dry-run marker"; return 1; }
  grep -Fq "[dry-run] mise use -g" "$logfile" \
    || { err "setup dry-run log missing simulated mise install command"; return 1; }
  if grep -Fq "[error]" "$logfile"; then
    err "setup dry-run log contains [error] lines: $logfile"
    return 1
  fi

  clipboard_policy="$(dot_required_clipboard_policy_label)"
  case "$clipboard_policy" in
    wl-copy\|xclip\|xsel)
      if dot_find_available_clipboard_cmd >/dev/null 2>&1; then
        ok "dry-run clipboard simulation check skipped (backend already available)"
      else
        if ! grep -Eiq '\[dry-run\].*(apt-get install -y|brew install).*(wl-clipboard|xclip|xsel)' "$logfile"; then
          err "setup dry-run log missing simulated clipboard install command (policy: $clipboard_policy)"
          return 1
        fi
        ok "dry-run clipboard simulation command check passed"
      fi
      ;;
    *)
      ok "dry-run clipboard simulation check skipped (policy: $clipboard_policy)"
      ;;
  esac

  ok "setup dry-run log contract passed"
}

count_backup_files() {
  local c=""

  c="$(find "$HOME" -maxdepth 3 \
    \( -name '.zshrc.bak.*' -o -name '.tmux.conf.bak.*' -o -name '.zsh.shared.zsh.bak.*' \
       -o -name '.zlogin.bak.*' -o -name '.zlogout.bak.*' -o -name '.zprofile.bak.*' \
       -o -name '.zshenv.bak.*' -o -name '.zpreztorc.bak.*' -o -name 'helix.bak.*' \
       -o -name 'lazygit.bak.*' -o -name 'dot-difft.bak.*' -o -name 'dot-difft-pager.bak.*' \
       -o -name 'dot-lazygit-theme.bak.*' -o -name 'sclip.bak.*' \) \
    2>/dev/null | wc -l || true)"
  c="$(printf '%s' "$c" | tr -d '[:space:]')"
  printf '%s' "${c:-0}"
}

assert_prezto_modules_present() {
  local zpreztorc_path="$HOME/.zpreztorc"
  local prezto_modules_dir="$HOME/.zprezto/modules"
  local module=""
  local configured=()
  local missing=()

  [ -f "$zpreztorc_path" ] || { err "missing zpreztorc: $zpreztorc_path"; return 1; }
  [ -d "$prezto_modules_dir" ] || { err "missing prezto modules dir: $prezto_modules_dir"; return 1; }

  mapfile -t configured < <(
    awk '
      /^[[:space:]]*zstyle[[:space:]]+.*prezto:load.*[[:space:]]+pmodule/ { in_block=1 }
      in_block {
        while (match($0, /'\''[^'\'']+'\''/)) {
          token = substr($0, RSTART + 1, RLENGTH - 2)
          if (token != ":prezto:load") {
            print token
          }
          $0 = substr($0, RSTART + RLENGTH)
        }
        if ($0 !~ /\\[[:space:]]*$/) {
          exit
        }
      }
    ' "$zpreztorc_path"
  )
  if [ "${#configured[@]}" -eq 0 ]; then
    err "no prezto modules parsed from: $zpreztorc_path"
    return 1
  fi
  for module in "${configured[@]}"; do
    if [ ! -d "$prezto_modules_dir/$module" ]; then
      missing+=("$module")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    err "prezto modules not found under $prezto_modules_dir: ${missing[*]}"
    return 1
  fi

  ok "prezto module check passed (${#configured[@]} modules)"
}

assert_setup_state() {
  local include_optional="${1:-0}"
  local include_count=""
  local resolved_link=""
  local manifest_line=""
  local link_path=""
  local link_target=""
  local clone_path=""
  local clone_origin=""
  local optional_file=""
  local optional_marker=""
  local cmd=""
  local clipboard_policy=""
  local clipboard_cmd=""

  include_count="$(count_git_include)"
  [ "$include_count" = "1" ] || { err "git include.path count expected 1, got: $include_count"; return 1; }
  assert_github_credential_helper_contract || return 1
  while IFS=$'\t' read -r link_path link_target; do
    resolved_link="$(dot_resolve_path "$link_path")"
    [ "$resolved_link" = "$link_target" ] || { err "symlink mismatch: $link_path -> $resolved_link (expected $link_target)"; return 1; }
  done < <(dot_print_repo_symlink_entries "$REPO_ROOT")
  while IFS=$'\t' read -r link_path link_target; do
    resolved_link="$(dot_resolve_path "$link_path")"
    [ "$resolved_link" = "$link_target" ] || { err "runcom symlink mismatch: $link_path -> $resolved_link (expected $link_target)"; return 1; }
  done < <(dot_print_prezto_runcom_symlink_entries "$HOME")
  assert_prezto_modules_present || return 1
  [ -f "$MANIFEST_FILE" ] || { err "setup manifest missing: $MANIFEST_FILE"; return 1; }
  manifest_line="version"$'\t'"$MANIFEST_VERSION"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest version mismatch"; return 1; }
  manifest_line="repo_root"$'\t'"$REPO_ROOT"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest repo_root mismatch"; return 1; }
  while IFS=$'\t' read -r link_path link_target; do
    manifest_line="symlink"$'\t'"$link_path"$'\t'"$link_target"
    grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing symlink entry: $link_path"; return 1; }
  done < <(dot_print_repo_symlink_entries "$REPO_ROOT")
  while IFS=$'\t' read -r link_path link_target; do
    manifest_line="symlink"$'\t'"$link_path"$'\t'"$link_target"
    grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing runcom entry: $link_path"; return 1; }
  done < <(dot_print_prezto_runcom_symlink_entries "$HOME")
  manifest_line="managed_file_contains"$'\t'"$HOME/.zshrc"$'\t'"dot-setup managed zshrc"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing zshrc marker entry"; return 1; }
  while IFS=$'\t' read -r clone_path clone_origin; do
    manifest_line="git_clone_origin"$'\t'"$clone_path"$'\t'"$clone_origin"
    grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing clone entry: $clone_path"; return 1; }
  done < <(dot_print_managed_git_clones "$HOME")
  manifest_line="git_include_path"$'\t'"$REPO_ROOT/config/gitconfig.shared"
  grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing git include entry"; return 1; }
  for cmd in "${DOT_REQUIRED_CLI_COMMANDS[@]}"; do
    tool_available "$cmd" || { err "command not found after setup: $cmd"; return 1; }
  done
  clipboard_policy="$(dot_required_clipboard_policy_label)"
  if [ "$clipboard_policy" != "none" ]; then
    if ! clipboard_cmd="$(dot_find_available_clipboard_cmd 2>/dev/null)"; then
      err "required clipboard command not found after setup (expected: $clipboard_policy)"
      return 1
    fi
    ok "clipboard command check passed: $clipboard_cmd"
    check_clipboard_runtime_if_enabled "$clipboard_policy" || return 1
  fi
  if [ "$include_optional" = "1" ]; then
    for cmd in "${DOT_OPTIONAL_CLI_COMMANDS[@]}"; do
      tool_available "$cmd" || { err "optional command not found after default setup: $cmd"; return 1; }
    done
    assert_helix_rust_setup || return 1
    while IFS=$'\t' read -r clone_path clone_origin; do
      manifest_line="git_clone_origin"$'\t'"$clone_path"$'\t'"$clone_origin"
      grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing optional clone entry: $clone_path"; return 1; }
    done < <(dot_print_optional_managed_git_clones "$HOME")
    while IFS=$'\t' read -r optional_file optional_marker; do
      manifest_line="managed_file_contains"$'\t'"$optional_file"$'\t'"$optional_marker"
      grep -Fqx "$manifest_line" "$MANIFEST_FILE" || { err "setup manifest missing optional managed file entry: $optional_file"; return 1; }
    done < <(dot_print_optional_managed_file_markers "$HOME")
  fi

  ok "state check passed (git include.path=1, links aligned, optional=${include_optional})"
}
