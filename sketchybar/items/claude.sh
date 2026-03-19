#!/bin/bash

# Variables
# ------------------------------------------------------------------------------
UPDATE_FREQ=5

# Appearance
# ------------------------------------------------------------------------------
claude=(
  icon=󱙺
  icon.font="$NERD_FONT:Bold:16"
  icon.color=0xffFEA871
  label.drawing=off
  background.color=0x00000000
  background.height=24
  padding_left=2
  padding_right=0
  icon.padding_left=4
  icon.padding_right=4
  drawing=off
  script="$PLUGIN_DIR/claude.sh"
  update_freq=$UPDATE_FREQ
)

# Definition
# ------------------------------------------------------------------------------
sketchybar --add item claude left \
           --set claude "${claude[@]}"
