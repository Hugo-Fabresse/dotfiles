#!/bin/bash
# ~/.config/hypr/toggle_waybar.sh

# Vérifie si Waybar tourne
if pgrep -x "waybar" > /dev/null; then
    # kill Waybar si actif
    pkill -x waybar
else
    # relance Waybar si non actif
    waybar -c ~/.local/share/hypr/waybar/config -s ~/.local/share/hypr/waybar/style.css
fi

