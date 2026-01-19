#!/bin/bash

# Kill previous instances
killall HyprRealm.x86_64

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_BIN="$SCRIPT_DIR/build/HyprRealm.x86_64"

# Number of screens
MONITORS=$(hyprctl monitors -j | jq '. | length')

# Save mouse position
read -r MOUSE_X MOUSE_Y < <(hyprctl cursorpos | tr -d ',')

# reset submap before launch
hyprctl dispatch submap reset

# One instance per screen
for i in $(seq 0 $((MONITORS - 1))); do
  echo "Launching on screen $i"
  hyprctl dispatch exec "[monitor $i]" "$WALLPAPER_BIN $i" &
done

# Restore mouse position
sleep 1 && hyprctl dispatch movecursor "$MOUSE_X" "$MOUSE_Y"
