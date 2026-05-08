#!/bin/bash
# Restore a minimized window from special:minimized
# Lists all windows on the special workspace via wofi, restores the selected one

if pgrep -x wofi > /dev/null; then
    pkill wofi
    exit 0
fi

# Get minimized windows (on special:minimized workspace)
windows=$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:minimized") | "\(.address) \(.class) — \(.title)"')

if [ -z "$windows" ]; then
    windows=""
fi

chosen=$(echo -n "$windows" | wofi --show dmenu --prompt "" --style ~/.config/wofi/style.css --conf ~/.config/wofi/config)

if [ -n "$chosen" ]; then
    addr=$(echo "$chosen" | awk '{print $1}')
    # Get the currently active workspace to restore the window there
    active_ws=$(hyprctl activeworkspace -j | jq -r '.id')
    hyprctl dispatch movetoworkspacesilent "$active_ws,address:$addr"
    hyprctl dispatch focuswindow "address:$addr"
fi
