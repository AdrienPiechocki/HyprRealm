#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_BIN="$SCRIPT_DIR/build/HyprRealm.x86_64"

# Number of screens
MONITORS=$(hyprctl monitors -j | jq '. | length')

# One instance per screen
for i in $(seq 0 $((MONITORS - 1)))
do
    echo "Launching on screen $i"
    hyprctl dispatch exec [monitor "$i"] "$WALLPAPER_BIN" "$i" &
done

