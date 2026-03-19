#!/usr/bin/env bash

dot_mill_version() {
  printf '%s\n' "1.1.2"
}

dot_mill_bootstrap_url() {
  local mill_version="${1:-$(dot_mill_version)}"
  printf '%s\n' "https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/${mill_version}/mill-dist-${mill_version}-mill.sh"
}

setup_install_or_refresh_metals() {
  local cs_bin="$1"
  local metals_path="$2"

  if [ "$UPDATE_PACKAGES" = "1" ] || [ ! -e "$metals_path" ]; then
    run "$cs_bin" install --install-dir "$HOME/.local/bin" metals
    if [ "$UPDATE_PACKAGES" = "1" ] && [ -e "$metals_path" ]; then
      ok "metals refreshed via coursier: $cs_bin"
    else
      ok "metals installed via coursier: $cs_bin"
    fi
  else
    ok "metals launcher already present: $metals_path"
  fi
}

setup_install_or_refresh_mill() {
  local mill_version="$1"
  local mill_url="$2"
  local mill_path="$3"

  if [ "$UPDATE_PACKAGES" = "1" ] || [ ! -e "$mill_path" ]; then
    run curl -L "$mill_url" -o "$mill_path"
    run chmod +x "$mill_path"
    if [ "$UPDATE_PACKAGES" = "1" ] && [ -e "$mill_path" ]; then
      ok "mill ${mill_version} refreshed via direct download"
    else
      ok "mill ${mill_version} installed via direct download"
    fi
  else
    ok "mill bootstrap already present: $mill_path"
  fi
}

setup_optional_scala_apps() {
  local cs_bin=""
  local mill_version=""
  local mill_url=""
  local metals_path="$HOME/.local/bin/metals"
  local mill_path="$HOME/.local/bin/mill"

  if ! cs_bin="$(resolve_working_coursier_bin)"; then
    err "unable to resolve a working coursier launcher for metals and mill install"
    return 1
  fi

  # resolve_working_coursier_bin runs in command substitution (subshell),
  # so PATH updates done there are not visible here.
  if [ "$cs_bin" = "$(dot_coursier_jvm_launcher_path)" ]; then
    if ! ensure_cmd_on_path java; then
      err "java runtime is unavailable on PATH; required for JVM coursier launcher"
      return 1
    fi
  fi

  setup_install_or_refresh_metals "$cs_bin" "$metals_path" || return 1

  mill_version="$(dot_mill_version)"
  mill_url="$(dot_mill_bootstrap_url "$mill_version")"
  setup_install_or_refresh_mill "$mill_version" "$mill_url" "$mill_path" || return 1
}
