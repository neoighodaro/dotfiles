#!/bin/sh

SHOW_LABEL=false
SHOW_LABEL_THRESHOLD=30

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ $PERCENTAGE = "" ]; then
  exit 0
fi

case ${PERCENTAGE} in
  9[0-9]|100) ICON="􀛨"
  ;;
  [6-8][0-9]) ICON="􀺸"
  ;;
  [3-5][0-9]) ICON="􀺶"
  ;;
  [1-2][0-9]) ICON="􀛩"
  ;;
  *) ICON="􀛪"
esac

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
