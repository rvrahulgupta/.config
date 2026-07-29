#!/bin/bash

# Exit if HDMI is connected — rotation not supported in mirror mode
hdmi_status=$(cat /sys/class/drm/card1-HDMI-A-1/status)
if [ "$hdmi_status" == "connected" ]; then
    notify-send "Monitor Rotate" "Rotation not available while HDMI is connected."
    exit 0
fi

# Get active monitor
current_monitor_name=$(hyprctl monitors -j | jq -r '.[].name' | head -1)

monitor_info=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$current_monitor_name\") | \"\(.width)x\(.height)@\(.refreshRate), \(.x)x\(.y), \(.scale)\"")

selected_direction=$(printf "top\nright\nbottom\nleft" | wofi --dmenu --prompt="Select edge:")

case "$selected_direction" in
    "top")    direction_id=0 ;;
    "right")  direction_id=1 ;;
    "bottom") direction_id=2 ;;
    "left")   direction_id=3 ;;
    *)        exit 0 ;;
esac

hyprctl keyword monitor "$current_monitor_name, $monitor_info, transform, $direction_id"
