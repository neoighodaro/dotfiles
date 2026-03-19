#!/bin/bash

if [ -f /tmp/claude-busy ]; then
  sketchybar --set $NAME icon="󱙺" icon.color=0xffFEA871 drawing=on
else
  sketchybar --set $NAME drawing=off
fi
