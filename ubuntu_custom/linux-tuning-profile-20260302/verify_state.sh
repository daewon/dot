#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

ok() {
  printf '[OK] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  FAILED=1
}

warn() {
  printf '[WARN] %s\n' "$1"
}

check_file_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_cmd_contains() {
  local cmd="$1"
  local needle="$2"
  local label="$3"
  local out
  if ! out="$(bash -lc "$cmd" 2>/dev/null)"; then
    fail "$label (command failed)"
    return
  fi
  if printf '%s' "$out" | grep -Fq "$needle"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "== Verify GNOME extension state =="
check_cmd_contains \
  "gsettings get org.gnome.shell enabled-extensions" \
  "dash-to-panel@jderose9.github.com" \
  "dash-to-panel is enabled"
check_cmd_contains \
  "gsettings get org.gnome.shell disabled-extensions" \
  "ubuntu-dock@ubuntu.com" \
  "ubuntu-dock is disabled"

echo
echo "== Verify dash-to-panel tuning =="
check_cmd_contains \
  "dconf read /org/gnome/shell/extensions/dash-to-panel/panel-position" \
  "'BOTTOM'" \
  "dash-to-panel panel-position=BOTTOM"
check_cmd_contains \
  "dconf read /org/gnome/shell/extensions/dash-to-panel/panel-size" \
  "30" \
  "dash-to-panel panel-size=30"
check_cmd_contains \
  "dconf read /org/gnome/shell/extensions/dash-to-panel/appicon-margin" \
  "4" \
  "dash-to-panel appicon-margin=4"
check_cmd_contains \
  "dconf read /org/gnome/shell/extensions/dash-to-panel/appicon-padding" \
  "2" \
  "dash-to-panel appicon-padding=2"

echo
echo "== Verify terminal tuning =="
check_cmd_contains \
  "dconf read /org/gnome/terminal/legacy/headerbar" \
  "false" \
  "gnome-terminal headerbar=false"
check_cmd_contains \
  "dconf read /org/gnome/terminal/legacy/default-show-menubar" \
  "false" \
  "gnome-terminal default-show-menubar=false"
check_cmd_contains \
  "dconf dump /org/gnome/terminal/" \
  "font='Cascadia Mono 12'" \
  "gnome-terminal font is Cascadia Mono 12"

echo
echo "== Verify Firefox profile + prefs =="
check_file_contains \
  "$HOME/.mozilla/firefox/profiles.ini" \
  "Path=clean.default-release" \
  "profiles.ini points to clean.default-release"
check_file_contains \
  "$HOME/.mozilla/firefox/installs.ini" \
  "Default=clean.default-release" \
  "installs.ini default is clean.default-release"

FF_USER_JS="$HOME/.mozilla/firefox/clean.default-release/user.js"
check_file_contains \
  "$FF_USER_JS" \
  "user_pref(\"browser.compactmode.show\", true);" \
  "Firefox compact mode pref exists"
check_file_contains \
  "$FF_USER_JS" \
  "user_pref(\"browser.uidensity\", 1);" \
  "Firefox uidensity=1 exists"
check_file_contains \
  "$FF_USER_JS" \
  "user_pref(\"media.av1.enabled\", false);" \
  "Firefox AV1 disabled pref exists"

echo
echo "== Verify Firefox binary source =="
check_cmd_contains \
  "readlink -f \$(which firefox)" \
  "/usr/lib/firefox/firefox.sh" \
  "firefox binary resolves to apt path"

echo
echo "== Verify bundle self-consistency =="
check_file_contains \
  "$BASE_DIR/REPORT.md" \
  "linux-tuning-profile-20260302" \
  "report points to current bundle path"
check_file_contains \
  "$BASE_DIR/AGENT_HANDOFF.md" \
  "복구 중심" \
  "agent handoff file exists"

if [ -f "/etc/apparmor.d/local/usr.bin.firefox" ]; then
  check_file_contains \
    "/etc/apparmor.d/local/usr.bin.firefox" \
    "wayland-proxy-" \
    "apparmor local rule includes wayland-proxy"
else
  warn "system file /etc/apparmor.d/local/usr.bin.firefox not found (run sudo restore step)"
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "One or more checks failed."
  exit 1
fi
