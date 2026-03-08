#!/usr/bin/env bash

# Vérifie si wofi est déjà lancé
if pgrep -x "wofi" > /dev/null; then
    # Kill le wofi en cours
    pkill -x "wofi"
else
    # Lance wofi
    wofi --show drun &
fi

