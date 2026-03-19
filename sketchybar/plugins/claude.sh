#!/bin/bash

if [ -f /tmp/claude-busy ]; then
  sketchybar --set $NAME drawing=on
else
  sketchybar --set $NAME drawing=off
fi
