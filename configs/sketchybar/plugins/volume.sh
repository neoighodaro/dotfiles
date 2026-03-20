#!/bin/sh

SHOW_VOLUME_LABEL=false

if [ "$SENDER" = "volume_change" ]; then
  VOLUME=$INFO

  case $VOLUME in
    [6-9][0-9]|100) ICON="􀊩"
    ;;
    [3-5][0-9]) ICON="􀊥"
    ;;
    [1-9]|[1-2][0-9]) ICON="􀊡"
    ;;
    *) ICON="􀊣"
  esac

  if [ "$SHOW_VOLUME_LABEL" = true ]; then
      sketchybar --set $NAME icon="$ICON" label="$VOLUME%" icon.padding_right=10
  else
      sketchybar --set $NAME icon="$ICON" label.drawing=off label.padding_left=0
  fi
fi
