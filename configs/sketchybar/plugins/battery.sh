#!/bin/sh

SHOW_LABEL=false
SHOW_LABEL_THRESHOLD=30

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

if   [ "$PERCENTAGE" -ge 90 ]; then ICON="􀛨"   # battery.100
elif [ "$PERCENTAGE" -ge 60 ]; then ICON="􀺸"   # battery.75
elif [ "$PERCENTAGE" -ge 30 ]; then ICON="􀺶"   # battery.50
elif [ "$PERCENTAGE" -ge 16 ]; then ICON="􀛩"   # battery.25
else                                ICON="􀛪"   # battery.0  (≤15%)
fi

if [[ $PERCENTAGE -lt $SHOW_LABEL_THRESHOLD ]]; then
  SHOW_LABEL=true
fi

if [[ $CHARGING != "" ]]; then
  ICON="􀢋"
  SHOW_LABEL=true
fi

# The item invoking this script (name $NAME) will get its icon and label updated with the current battery status
if [[ "$SHOW_LABEL" = true ]]; then
    sketchybar --set $NAME icon="$ICON" label="${PERCENTAGE}%"
else
    sketchybar --set $NAME icon="$ICON" label.drawing=off icon.padding_right=10
fi
