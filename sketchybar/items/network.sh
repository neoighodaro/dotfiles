#!/bin/bash

# Variables
# -------------------------------------------------------------------------------------------
ANIMATE_SIN=5
ICON_FONT_SIZE=12.5

# Appearance
# -------------------------------------------------------------------------------------------
network=(
  icon.padding_right=9
  icon.font="$SF_PRO_FONT:Bold:$ICON_FONT_SIZE"
  label.drawing=off
)


# Definition
# -------------------------------------------------------------------------------------------
sketchybar --add item network right                        \
           --set network "${network[@]}"                  \
                     script="$PLUGIN_DIR/network.sh"      \
                     updates=on                           \
           --subscribe network wifi_change
