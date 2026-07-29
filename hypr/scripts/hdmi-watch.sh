#!/bin/bash
HDMI_STATUS="/sys/class/drm/card1-HDMI-A-1/status"

last_state=""

while true; do
    state=$(cat "$HDMI_STATUS" 2>/dev/null)

    if [ "$state" != "$last_state" ]; then
        last_state="$state"
        sleep 2  # wait for Hyprland to register the monitor
        ~/.config/hypr/scripts/monitor-switch.sh "$state"
    fi

    sleep 2
done
