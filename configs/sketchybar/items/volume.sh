#!/bin/bash

# Variables
# -------------------------------------------------------------------------------------------
UPDATE_FREQ=120
LABEL_FONT_SIZE=11.0

# Appearance
# -------------------------------------------------------------------------------------------
volume=(
  icon.padding_right=12
  icon.font.size=12
  icon.y_offset=1
  label.padding_left=0
)

# Definition
# -------------------------------------------------------------------------------------------
sketchybar --add item volume right                                       \
           --set volume "${volume[@]}" script="$PLUGIN_DIR/volume.sh"   \
           --subscribe volume volume_change
