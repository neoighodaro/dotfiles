#!/bin/bash

# Variables
# -------------------------------------------------------------------------------------------
ICON_FONT_SIZE=12.5

# Appearance
# -------------------------------------------------------------------------------------------
# Hidden by default; the plugin toggles drawing on when a VPN is connected.
vpn=(
  icon=􁅏                                          # network.badge.shield.half.filled
  icon.font="$SF_PRO_FONT:Bold:$ICON_FONT_SIZE"
  icon.padding_right=9
  label.drawing=off
  drawing=off
)

# Definition
# -------------------------------------------------------------------------------------------
sketchybar --add item vpn right                    \
           --set vpn "${vpn[@]}"                    \
                     script="$PLUGIN_DIR/vpn.sh"    \
                     update_freq=10                 \
           --subscribe vpn system_woke wifi_change
