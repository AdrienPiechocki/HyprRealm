#!/usr/bin/env bash

set -e

# Directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths
SOURCE="$SCRIPT_DIR/config/"
HYPR_DIR="$HOME/.config/hypr"
DEST="$HYPR_DIR/hyprrealm/"
HYPR_CONF="$HYPR_DIR/hyprland.conf"
SOURCE_LINE="source = ~/.config/hypr/hyprrealm/hyprrealm.conf"

# Check source directory
if [ ! -d "$SOURCE" ]; then
  echo "Error: source directory '$SOURCE' does not exist."
  exit 1
fi

# Create destination directory if needed
mkdir -p "$DEST"

# Sync hyprrealm directory
rsync -av --delete "$SOURCE" "$DEST"

echo "Synchronization completed: $SOURCE -> $DEST"

# Create hyprland.conf if it does not exist
touch "$HYPR_CONF"

# Add source line if not already present
if ! grep -Fxq "$SOURCE_LINE" "$HYPR_CONF"; then
  echo "" >> "$HYPR_CONF"
  echo "$SOURCE_LINE" >> "$HYPR_CONF"
  echo "Source line added to hyprland.conf"
else
  echo "Source line already present in hyprland.conf"
fi

