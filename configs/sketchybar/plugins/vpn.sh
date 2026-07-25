#!/bin/sh

source "$CONFIG_DIR/colors.sh"

# Show a shield only while a VPN is connected. `scutil --nc list` marks
# connected services (native IKEv2/IPSec and Network-Extension VPNs such as
# Twingate) with a line beginning "* (Connected)".
if scutil --nc list 2>/dev/null | grep -q '^\* (Connected)'; then
  sketchybar --set "$NAME" drawing=on icon.color="$TEXT_COLOR"
else
  sketchybar --set "$NAME" drawing=off
fi
