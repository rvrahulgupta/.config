#!/usr/bin/sh

# source: https://www.reddit.com/r/hyprland/comments/13ivh0c/comment/jkgk65k/

# Flags:
# r: region
# s: screen
# w: window
#
# c: clipboard
# f: file
# i: interactive
#
# p: pixel

notif_timeout=3000
case "$1" in
  rc)
    grim -l 0 -g "$(slurp -b '#000000b0' -c '#00000000')" - | wl-copy
    if ! [ -z "$(wl-paste)" ]; then
      cat "$(wl-paste)"
      notify-send -t "$notif_timeout" -u low "Screenshot copied to clipboard."
    fi
    ;;

  rf)
    mkdir -p ~/Pictures/Screenshots
    filename=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
    grim -l 0 -g "$(slurp -b '#000000b0' -c '#00000000')" "$filename"
    notify-send -t "$notif_timeout" -u low "Screenshot saved." "$filename"
    ;;

  ri)
    grim -l 0 -g "$(slurp -b '#000000b0' -c '#00000000')" - | swappy -f -
    ;;

  sc)
    grim -l 0 - | wl-copy
    if ! [ -e "$(wl-paste)" ]; then
      notify-send -t "$notif_timeout" -u low "Screenshot copied to clipboard."
    fi
    ;;

  sf)
    mkdir -p ~/Pictures/Screenshots
    filename=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
    grim -l 0 "$filename"
    notify-send -t "$notif_timeout" -u low "Screenshot saved." "$filename"
    ;;

  si)
    grim -l 0 - | swappy -f -
    ;;

  wc)
    hyprshot -m window --clipboard-only --silent
    if [ -n "$(wl-paste)" ]; then
      cat "$(wl-paste)"
      notify-send -t "$notif_timeout" -u low "Screenshot copied to clipboard."
    fi
    ;;

  wf)
    filename=$(date +%Y-%m-%d_%H-%M-%S).png
    hyprshot -m window --output-folder "$HOME"/Pictures/Screenshots/ --filename "$filename" --silent
    sleep 0.1
    notify-send -t "$notif_timeout" -u low "Screenshot saved." "$filename"
    ;;

  p)
    maybe_color=$(hyprpicker -a)
    if echo "$maybe_color" | grep -q '#'; then
      stripped_msg="${maybe_color#*#}"
      color=$(echo "$stripped_msg" | cut -c 1-6)
      hex="#$color"
      wl-copy "$hex"
      if ! [ -z "$(wl-paste)" ]; then
        notify-send -t "$notif_timeout" -u low "$hex" "Copied to Clipboard."
      fi
    fi
    ;;

  *)
    echo "Usage: $0 [rc|rf|ri|sc|sf|si|wc|wf|p]"
    echo "Flags:"
    echo "	rc - region to clipboard"
    echo "	rf - region to file"
    echo "	ri - region interactive"
    echo "	sc - screen to clipboard"
    echo "	sf - screen to file"
    echo "	si - screen interactive"
    echo "  wc - window to clipboard"
    echo "  wf - window to file"
    echo "	p  - pick pixel colour"
    exit 1
    ;;
esac
