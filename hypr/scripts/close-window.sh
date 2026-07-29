#!/usr/bin/sh

workspace_id=$(hyprctl activeworkspace -j | jq -r '.id')

# Save previous workspace before closing
prev=$(hyprctl workspaces -j | jq --argjson cur "$workspace_id" \
  '[.[] | select(.windows > 0 and .id != $cur)] | sort_by(.lasttime) | .[-1].id // empty')

hyprctl dispatch killactive
sleep 0.1

# Check if workspace is now empty
clients=$(hyprctl clients -j | jq --argjson id "$workspace_id" \
  '[.[] | select(.workspace.id == $id)] | length')

if [ "$clients" -eq 0 ]; then
  prev_windows=$(hyprctl workspaces -j | jq --argjson id "$prev" \
    '.[] | select(.id == $id) | .windows // 0')
  if [ -n "$prev" ] && [ "${prev_windows:-0}" -gt 0 ]; then
    hyprctl dispatch workspace "$prev"
  else
    next=$(hyprctl workspaces -j | jq --argjson cur "$workspace_id" \
      '[.[] | select(.windows > 0 and .id != $cur)] | sort_by(.id) | .[0].id // empty')
    [ -n "$next" ] && hyprctl dispatch workspace "$next"
  fi
fi
