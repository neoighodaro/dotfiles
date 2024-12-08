#!/bin/bash

# Variables
# -------------------------------------------------------------------------------------------
UPDATE_FREQ=1500
# LABEL_FONT_SIZE=11.0

# Appearance
# -------------------------------------------------------------------------------------------
weather=(
  icon=󰖐
  scroll_texts=true
  label.y_offset=-0.5
  label.font="$SF_PRO_FONT:Bold:$LABEL_FONT_SIZE"
  label.max_chars=15
  icon.color=$WHITE
  icon.font="$SF_PRO_FONT:Bold:15"
  icon.y_offset=1
  icon.padding_right=0
)

# Definition
# -------------------------------------------------------------------------------------------
sketchybar --add item weather right \
           --set weather "${weather[@]}" script="$PLUGIN_DIR/weather.sh" update_freq=$UPDATE_FREQ \
           --subscribe weather mouse.clicked
