#!/usr/bin/env bash
set -euo pipefail

printf '\n[1/4] Reset GNOME Shell extension tuning\n'
dconf reset -f /org/gnome/shell/extensions/dash-to-panel/

gsettings set org.gnome.shell disabled-extensions "[]"
gsettings set org.gnome.shell enabled-extensions "['ding@rastersoft.com', 'tiling-assistant@ubuntu.com', 'ubuntu-appindicators@ubuntu.com', 'ubuntu-dock@ubuntu.com']"

printf '\n[2/4] Reset interface and terminal tweaks\n'
dconf reset -f /org/gnome/desktop/interface/
dconf reset -f /org/gnome/terminal/

printf '\n[3/4] Reset Firefox local tuning file\n'
rm -f "$HOME/.mozilla/firefox/clean.default-release/user.js"
rm -f "$HOME/.config/mozilla/firefox/clean.default-release/user.js"

printf '\n[4/4] Done\n'
echo "Logout/login recommended."
