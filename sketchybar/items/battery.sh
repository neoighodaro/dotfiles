#!/bin/bash

# Variables
# -------------------------------------------------------------------------------------------
UPDATE_FREQ=120
LABEL_FONT_SIZE=11.0

# Appearance
# -------------------------------------------------------------------------------------------
battery=(
  icon.y_offset=1
  label.y_offset=-0.5
  label.font="$SF_PRO_FONT:Bold:$LABEL_FONT_SIZE"
)

# Definition
# -------------------------------------------------------------------------------------------
sketchybar --add item battery right \
           --set battery "${battery[@]}" update_freq=$UPDATE_FREQ \
                 script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change
