#!/usr/bin/env bash
# update_picker.sh — Pick packages to update via wofi
set -euo pipefail

pidof wofi && pkill wofi && exit 0

updates=$(checkupdates 2>/dev/null) || true

if [ -z "$updates" ]; then
    notify-send "Updates" "System is up to date"
    exit 0
fi

# wofi multi-select: Shift+Enter to select, Enter to confirm
selected=$(echo "$updates" | wofi --show dmenu --prompt "update (shift+enter = multi)" --style ~/.config/wofi/style.css --conf ~/.config/wofi/config) || exit 0

[ -z "$selected" ] && exit 0

# Extract package names (first column)
pkgs=$(echo "$selected" | awk '{print $1}')

kitty --class floating-term -e bash -c "sudo pacman -S $pkgs; echo; read -p 'Press enter to close'"
