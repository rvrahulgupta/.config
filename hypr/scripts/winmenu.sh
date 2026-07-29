#!/usr/bin/env bash
# Unified window-menu + snap handler for Hyprland
# Usage: winmenu.sh <action>
# Actions: close maximize minimize restore float pin snap-left snap-right

set -euo pipefail

need_jq() {
    command -v jq >/dev/null 2>&1 || { echo "jq not installed. Run: sudo pacman -S jq" >&2; exit 1; }
}

# Returns 4 space-separated values: top right bottom left
# Handles three known hyprctl reporting shapes:
#   {"int": 5}                     -> uniform int, all 4 sides = 5
#   {"custom": "5,5,5,5"}          -> comma-separated
#   {"custom": "0 0 0 0"}          -> space-separated (confirmed on this system)
get_gaps_trbl() {
    local opt="$1"
    local raw has_int custom
    raw=$(hyprctl getoption "$opt" -j)
    has_int=$(echo "$raw" | jq 'has("int")')

    if [ "$has_int" == "true" ]; then
        local v
        v=$(echo "$raw" | jq -r '.int')
        [[ "$v" =~ ^[0-9]+$ ]] || v=5
        echo "$v $v $v $v"
        return
    fi

    custom=$(echo "$raw" | jq -r '.custom' | tr ',' ' ')
    # collapse any double spaces, trim
    custom=$(echo "$custom" | xargs)

    local -a vals
    read -ra vals <<< "$custom"

    case "${#vals[@]}" in
        4) echo "${vals[0]} ${vals[1]} ${vals[2]} ${vals[3]}" ;;
        1) echo "${vals[0]} ${vals[0]} ${vals[0]} ${vals[0]}" ;;
        *) echo "5 5 5 5" ;;  # unrecognized shape, safe fallback
    esac
}

# Single-value gap (used for gaps_in between the two split windows) —
# same parsing, just takes the first value since gaps_in between two
# floating-snap windows only needs one number, not 4 directions.
get_gap_single() {
    local opt="$1"
    local raw
    read -r first _ <<< "$(get_gaps_trbl "$opt")"
    echo "$first"
}

action="${1:-}"

case "$action" in

    close)
        hyprctl dispatch killactive
        ;;

    maximize)
        hyprctl dispatch fullscreen 1
        ;;

    restore)
        # In Windows, Restore un-maximizes if maximized. Since Hyprland's
        # fullscreen dispatcher self-toggles, calling it again does that.
        hyprctl dispatch fullscreen 1
        ;;

    minimize)
        # Genuinely hides the window: moves it to a special workspace
        # WITHOUT switching your current view to that workspace.
        hyprctl dispatch movetoworkspacesilent special:minimized
        ;;

    move)
        hyprctl dispatch movewindow
        ;;

    resize)
        hyprctl dispatch resizeactive
        ;;

    snap-left|snap-right)
        need_jq

        win=$(hyprctl activewindow -j)
        is_floating=$(echo "$win" | jq -r '.floating')
        [ "$is_floating" == "false" ] && hyprctl dispatch togglefloating

        mon=$(hyprctl monitors -j | jq '.[] | select(.focused==true)')

        mx=$(echo "$mon" | jq '.x')
        my=$(echo "$mon" | jq '.y')
        mw=$(echo "$mon" | jq '(.width / .scale) | floor')
        mh=$(echo "$mon" | jq '(.height / .scale) | floor')

        res_left=$(echo "$mon" | jq '.reserved[0]')
        res_right=$(echo "$mon" | jq '.reserved[1]')
        res_top=$(echo "$mon" | jq '.reserved[2]')
        res_bottom=$(echo "$mon" | jq '.reserved[3]')

        ux=$((mx + res_left))
        uy=$((my + res_top))
        uw=$((mw - res_left - res_right))
        uh=$((mh - res_top - res_bottom))

        # gaps_out: top right bottom left
        read -r go_top go_right go_bottom go_left <<< "$(get_gaps_trbl "general:gaps_out")"
        gaps_in=$(get_gap_single "general:gaps_in")
        border=$(get_gap_single "general:border_size")

        [[ "$gaps_in" =~ ^[0-9]+$ ]] || gaps_in=5
        [[ "$border" =~ ^[0-9]+$ ]]  || border=2

        avail_w=$((uw - go_left - go_right - gaps_in))
        half_w=$(((avail_w / 2) - border))
        win_h=$((uh - go_top - go_bottom - (border * 2)))

        left_x=$((ux + go_left))
        right_x=$((ux + go_left + half_w + (border * 2) + gaps_in))
        win_y=$((uy + go_top))

        hyprctl dispatch resizeactive exact "$half_w" "$win_h"

        if [ "$action" == "snap-left" ]; then
            hyprctl dispatch moveactive exact "$left_x" "$win_y"
        else
            hyprctl dispatch moveactive exact "$right_x" "$win_y"
        fi
        ;;

    *)
        echo "Unknown or missing action: $action" >&2
        echo "Valid: close maximize minimize restore float pin snap-left snap-right" >&2
        exit 1
        ;;
esac
