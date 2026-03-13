#!/bin/bash
if pgrep -x wofi > /dev/null; then
    pkill wofi
else
    cliphist list | wofi --show dmenu | cliphist decode | wl-copy
fi
