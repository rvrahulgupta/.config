#!/usr/bin/sh

workspace_id=$(hyprctl activeworkspace -j | jq -r '.id')
addresses=($(hyprctl clients -j | jq -r --arg wsid "$workspace_id" '.[] | select(.workspace.id == ($wsid | tonumber)) | .address'))

# Save previous workspace before closing
prev=$(hyprctl workspaces -j | jq --argjson cur "$workspace_id" \
  '[.[] | select(.windows > 0 and .id != $cur)] | sort_by(.lasttime) | .[-1].id // empty')

close_workspace() {
  for addr in "${addresses[@]}"; do
    hyprctl dispatch closewindow address:"$addr"
  done
  switch_to_best
}

force_close_workspace() {
  for addr in "${addresses[@]}"; do
    hyprctl dispatch killwindow address:"$addr"
  done
  switch_to_best
}

switch_to_best() {
  sleep 0.3
  # Check if prev workspace still has windows
  prev_windows=$(hyprctl workspaces -j | jq --argjson id "$prev" \
    '.[] | select(.id == $id) | .windows // 0')
  if [ -n "$prev" ] && [ "${prev_windows:-0}" -gt 0 ]; then
    hyprctl dispatch workspace "$prev"
  else
    next=$(hyprctl workspaces -j | jq --argjson cur "$workspace_id" \
      '[.[] | select(.windows > 0 and .id != $cur)] | sort_by(.id) | .[0].id // empty')
    [ -n "$next" ] && hyprctl dispatch workspace "$next"
  fi
}

case "$1" in
  "close")
    close_workspace
    ;;
  "kill")
    force_close_workspace
    ;;
  *)
    exit 0
    ;;
esac
