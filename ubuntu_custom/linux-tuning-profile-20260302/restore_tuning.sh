#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '\n[1/6] Restore GNOME dconf values\n'
if command -v dconf >/dev/null 2>&1; then
  dconf load /org/gnome/shell/ < "$BASE_DIR/dconf/gnome-shell.ini"
  dconf load /org/gnome/desktop/interface/ < "$BASE_DIR/dconf/desktop-interface.ini"
  dconf load /org/gnome/terminal/ < "$BASE_DIR/dconf/gnome-terminal.ini"
else
  echo "dconf not found. Install it first." >&2
  exit 1
fi

printf '\n[2/6] Restore dash-to-panel extension files\n'
mkdir -p "$HOME/.local/share/gnome-shell/extensions"
if [ -f "$BASE_DIR/dash-to-panel-v72.tar.gz" ]; then
  tar -xzf "$BASE_DIR/dash-to-panel-v72.tar.gz" -C "$HOME/.local/share/gnome-shell/extensions"
else
  echo "dash-to-panel-v72.tar.gz missing. Skip file restore."
fi

printf '\n[3/6] Set extension enable/disable state\n'
if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions enable dash-to-panel@jderose9.github.com || true
  gnome-extensions disable ubuntu-dock@ubuntu.com || true
fi

printf '\n[4/6] Restore Firefox profile selection and tuning user.js\n'
mkdir -p "$HOME/.mozilla/firefox" "$HOME/.config/mozilla/firefox/clean.default-release"
cp "$BASE_DIR/firefox/profiles.ini" "$HOME/.mozilla/firefox/profiles.ini"
cp "$BASE_DIR/firefox/installs.ini" "$HOME/.mozilla/firefox/installs.ini"
cp "$BASE_DIR/firefox/user.js" "$HOME/.mozilla/firefox/clean.default-release/user.js"
cp "$BASE_DIR/firefox/user.js" "$HOME/.config/mozilla/firefox/clean.default-release/user.js"

printf '\n[5/6] Optional AppArmor rule restore (requires sudo)\n'
if [ -f "$BASE_DIR/apparmor/usr.bin.firefox.local.conf" ]; then
  echo "sudo install -D -m 0644 \"$BASE_DIR/apparmor/usr.bin.firefox.local.conf\" /etc/apparmor.d/local/usr.bin.firefox"
  echo "sudo apparmor_parser -r /etc/apparmor.d/usr.bin.firefox"
fi

printf '\n[6/6] Done\n'
echo "Logout/login (or reboot) once to fully apply GNOME shell changes."
