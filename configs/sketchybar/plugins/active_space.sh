#!/bin/sh

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  sketchybar --set active_space icon="$AEROSPACE_FOCUSED_WORKSPACE"
fi
