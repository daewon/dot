#!/usr/bin/env bash

manifest_add_entry() {
  local kind="$1"
  local path="$2"
  local meta="${3:-}"
  if [ -n "$meta" ]; then
    MANIFEST_ENTRIES+=("$kind"$'\t'"$path"$'\t'"$meta")
  else
    MANIFEST_ENTRIES+=("$kind"$'\t'"$path")
  fi
}

write_setup_manifest() {
  local tmp=""
  local line=""

  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry-run] write %s\n' "$MANIFEST_FILE"
    ok "would update setup manifest"
    return
  fi

  mkdir -p "$MANIFEST_DIR"
  tmp="${MANIFEST_FILE}.tmp.$$"
  {
    printf 'version\t%s\n' "$MANIFEST_VERSION"
    printf 'repo_root\t%s\n' "$REPO_ROOT"
    for line in "${MANIFEST_ENTRIES[@]}"; do
      printf '%s\n' "$line"
    done
  } >"$tmp"
  mv "$tmp" "$MANIFEST_FILE"
  ok "setup manifest updated: $MANIFEST_FILE"
}

backup_if_unmanaged_path() {
  local path="$1"
  local expected_target="$2"
  local ts="$3"

  if [ -L "$path" ]; then
    if dot_is_link_target "$path" "$expected_target"; then
      return
    fi
    backup_path "$path" "$ts"
    return
  fi

  if [ -e "$path" ]; then
    backup_path "$path" "$ts"
  fi
}

backup_path() {
  local path="$1"
  local ts="${2:-$TS}"

  if [ -e "$path" ] || [ -L "$path" ]; then
    run mv "$path" "${path}.bak.${ts}"
    if [ "$DRY_RUN" = "1" ]; then
      ok "would back up $path -> ${path}.bak.${ts}"
    else
      ok "backed up $path -> ${path}.bak.${ts}"
    fi
  fi
}

ensure_managed_clone() {
  local clone_path="$1"
  local clone_url="$2"
  local origin_snippet="$3"
  local label="$4"
  local recursive="$5"
  local required_path="${6:-}"
  local origin=""
  local needs_clone=1

  if [ -d "$clone_path/.git" ]; then
    origin="$(git -C "$clone_path" remote get-url origin 2>/dev/null || true)"
    if printf '%s' "$origin" | grep -Fq "$origin_snippet"; then
      if [ -n "$required_path" ] && [ ! -e "$clone_path/$required_path" ]; then
        warn "$label looks incomplete ($required_path missing); backing up before re-clone"
        backup_path "$clone_path"
      else
        ok "$label already present"
        needs_clone=0
      fi
    else
      warn "$label origin mismatch: ${origin:-unknown}; backing up before re-clone"
      backup_path "$clone_path"
    fi
  elif [ -e "$clone_path" ] || [ -L "$clone_path" ]; then
    warn "$label path exists but is not a managed clone; backing up before clone"
    backup_path "$clone_path"
  fi

  if [ "$needs_clone" = "1" ]; then
    run mkdir -p "$(dirname "$clone_path")"
    if [ "$recursive" = "1" ]; then
      run git clone --recursive "$clone_url" "$clone_path"
    else
      run git clone "$clone_url" "$clone_path"
    fi
    if [ "$DRY_RUN" = "1" ]; then
      ok "would clone $label"
    else
      ok "$label cloned"
    fi
  fi
}

normalize_git_host_credential_helpers() {
  local host=""
  local key=""
  local origin=""
  local origin_file=""
  local removed=""

  for host in "${DOT_GH_CREDENTIAL_HOSTS[@]}"; do
    key="credential.${host}.helper"
    removed=0

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

      # Keep include-managed host helpers in shared config; remove only direct global overrides.
      if [ "$origin_file" = "$GIT_SHARED_INCLUDE_PATH" ]; then
        continue
      fi

      if git config --file "$origin_file" --get-all "$key" >/dev/null 2>&1; then
        run git config --file "$origin_file" --unset-all "$key"
        removed=1
      fi
    done < <(git config --global --show-origin --get-all "$key" 2>/dev/null || true)

    if [ "$removed" = "1" ]; then
      if [ "$DRY_RUN" = "1" ]; then
        ok "would remove stale direct global credential helper: $host"
      else
        ok "removed stale direct global credential helper: $host"
      fi
    else
      ok "global credential helper already clean: $host"
    fi
  done
}
