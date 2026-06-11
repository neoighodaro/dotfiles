#!/bin/sh

source "$CONFIG_DIR/colors.sh"

# Variables
# -------------------------------------------------------------------------------------------
# From SF Symbols
NET_WIFI=􀙇         # Wi-Fi connected
NET_HOTSPOT=􀉤      # iPhone Wi-Fi hotspot connected
NET_USB=􀟜          # iPhone USB hotspot connected
NET_THUNDERBOLT=􀒗  # Thunderbolt bridge connected
NET_DISCONNECTED=􀙇 # Network disconnected, but Wi-Fi turned on
NET_OFF=􀙈          # Network disconnected, Wi-Fi turned off
NET_ETHERNET=􁊒     # cable.coaxial — wired/Ethernet connected

ANIMATE_SIN=5
LABEL_FONT_SIZE=11.0

# Appearance
# -------------------------------------------------------------------------------------------
volume=(
  icon.padding_right=14
  label.padding_left=0
  label.font="$SF_PRO_FONT:Bold:$LABEL_FONT_SIZE"
)

# Setup
# -------------------------------------------------------------------------------------------
# When switching between devices, it's possible to get hit with multiple
# concurrent events, some of which may occur before `scutil` picks up the
# changes, resulting in race conditions.
sleep 1

# Get the current network service and device. The device carrying the default
# route is the one actually in use (Wi-Fi, Ethernet, tether, etc.).
services=$(networksetup -listnetworkserviceorder)
device=$(route -n get -inet default 2>/dev/null | awk '/interface:/{print $2; exit}')

# Try to find the service name for the active device
test -n "$device" && service=$(echo "$services" | sed -n "s/.*Hardware Port: \([^,]*\), Device: $device).*/\1/p")

color=$TEXT_COLOR
case $service in
  "iPhone USB")         icon=$NET_USB;;
  "Thunderbolt Bridge") icon=$NET_THUNDERBOLT;;
  Wi-Fi)
    ssid=$(ipconfig getsummary "$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')" | grep '  SSID : ' | awk -F ': ' '{print $2}')
    case $ssid in
      *iPhone*) icon=$NET_HOTSPOT;;
      "")       icon=$NET_DISCONNECTED; color=$TEXT_COLOR_DIM;;
      *)        icon=$NET_WIFI;;
    esac;;

  "")
    # No default route → nothing is connected. Reflect Wi-Fi power state.
    wifi_device=$(echo "$services" | sed -n "s/.*Hardware Port: Wi-Fi, Device: \([^\)]*\).*/\1/p")
    test -n "$wifi_device" && status=$(networksetup -getairportpower "$wifi_device" | awk '{print $NF}')
    icon=$(test "$status" = On && echo "$NET_DISCONNECTED" || echo "$NET_OFF")
    color=$TEXT_COLOR_DIM;;

  *)
    # Any other active service is a wired connection (Ethernet, USB LAN,
    # Thunderbolt Ethernet, USB-C dongle, …) → cable.coaxial SF Symbol.
    icon=$NET_ETHERNET;;
esac

# Script
# -------------------------------------------------------------------------------------------
sketchybar --animate sin "$ANIMATE_SIN" --set "$NAME" \
            icon="$icon" \
            icon.color="$color"
