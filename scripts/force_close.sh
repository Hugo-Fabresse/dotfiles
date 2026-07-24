#!/bin/bash
# force_close.sh — Force close apps that ignore killactive (Steam, Discord, etc.)

# Apps that minimize to tray instead of closing
FORCE_KILL_CLASSES="steam|discord|Discord"

# Get active window info
window_json=$(hyprctl activewindow -j)
class=$(echo "$window_json" | jq -r '.class')
pid=$(echo "$window_json" | jq -r '.pid')

if echo "$class" | grep -qiE "$FORCE_KILL_CLASSES"; then
    # Kill the entire process tree for tray-hiding apps
    kill "$pid" 2>/dev/null
else
    # Normal close for everything else
    hyprctl dispatch killactive
fi
