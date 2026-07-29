#!/bin/bash
# Track mouse clicks using a temporary file timestamp
STATE_FILE="/tmp/mmb_click_time"
NOW=$(date +%s%N)

if [ -f "$STATE_FILE" ]; then
    LAST=$(cat "$STATE_FILE")
    DIFF=$(( (NOW - LAST) / 1000000 )) # Convert nanoseconds to milliseconds
    
    # If the second click happens within 300ms, kill the window
    if [ $DIFF -lt 300 ]; then
        hyprctl dispatch killactive
        rm "$STATE_FILE"
        exit 0
    fi
fi

echo "$NOW" > "$STATE_FILE"
