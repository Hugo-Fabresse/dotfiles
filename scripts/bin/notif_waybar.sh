#!/bin/bash
count=$(dunstctl count history)
if [ "$count" -gt 0 ] 2>/dev/null; then
    echo "{\"text\": \"󰂚 $count\", \"tooltip\": \"$count notification(s)\", \"class\": \"has-notifs\"}"
else
    echo "{\"text\": \"󰂜\", \"tooltip\": \"no notifications\", \"class\": \"empty\"}"
fi
