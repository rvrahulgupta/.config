#!/bin/bash
export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ 2>/dev/null | grep -v lock | head -1)

if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo "No Hyprland instance found" && exit 1
fi

if [ "$1" == "connected" ]; then
    # Set HDMI as mirror of eDP-1 at 1.5x scale
    hyprctl keyword monitor "eDP-1, 1920x1080@60, 0x0, 1.5"
    sleep 1
    hyprctl keyword monitor "HDMI-A-1, 1920x1080@60, 0x0, 1.5, mirror, eDP-1"
else
    # Back to laptop only at 1x scale
    hyprctl keyword monitor "HDMI-A-1, disable"
    sleep 1
    hyprctl keyword monitor "eDP-1, 1920x1080@60, 0x0, 1"
fi
