#!/bin/bash

# Variables
# -------------------------------------------------------------------------------------------
UPDATE_FREQ=30
LABEL_FONT_SIZE=11.0

# Appearance
# -------------------------------------------------------------------------------------------
calendar=(
    icon=􀧞
    label.font="$SF_PRO_FONT:Bold:$LABEL_FONT_SIZE"
)

# Definition
# -------------------------------------------------------------------------------------------
sketchybar --add item calendar right                           \
           --set calendar "${calendar[@]}"                     \
                          update_freq=$UPDATE_FREQ             \
                          script="$PLUGIN_DIR/calendar.sh"
