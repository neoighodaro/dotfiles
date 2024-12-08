#!/bin/bash

# Variables
# ------------------------------------------------------------------------------
ICON_FONT_SIZE=13
LABEL_FONT_SIZE=12
LABEL_FONT="Hack Nerd Font:Bold:$LABEL_FONT_SIZE"

# Appearance
# ------------------------------------------------------------------------------
front_app=(
    background.color=$ACCENT_COLOR
    icon.color=$BAR_COLOR
    icon.font="sketchybar-app-font:Regular:$ICON_FONT_SIZE"
    label.color=$BAR_COLOR
    label.font="$LABEL_FONT"
    label.y_offset=0.5
    icon.padding_right=0
    script="$PLUGIN_DIR/front_app.sh"
)

# Script
# ------------------------------------------------------------------------------
sketchybar --add item front_app left                         \
           --set front_app "${front_app[@]}"                 \
           --subscribe front_app front_app_switched
