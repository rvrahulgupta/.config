#!/usr/bin/sh

list=$(hyprctl clients -j | jq -r '.[] | select(.title != "") | "\(.title) | (\(.workspace.id)) | \(.address)"')
if [ -n "$list" ]; then
  sorted_list=$(echo "$list" | sort -t'(' -k2,2n)
  selection=$(printf '%s\n' "$sorted_list" | wofi --dmenu -i -p "Select Window")
  if [ -n "$selection" ]; then
    address=$(printf '%s' "$selection" | awk '{print $NF}')
    if [ -n "$address" ]; then
      hyprctl dispatch focuswindow address:"$address"
    fi
  fi
fi
