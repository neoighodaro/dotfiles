#!/bin/bash

# Variables
# -------------------------------------------------------------------------------------------
LABEL_FONT="$SF_PRO_FONT:Bold:12.0"
LABEL_PADDING_LEFT=8
LABEL_PADDING_RIGHT=0
LABEL_OFFSET_Y=1.5

ICON_FONT="sketchybar-app-font:Regular:14.0"
ICON_PADDING_LEFT=0
ICON_PADDING_RIGHT=15
ICON_OFFSET_Y=-1

# Definition
# -------------------------------------------------------------------------------------------
sketchybar --add event aerospace_workspace_change

for m in $(aerospace list-monitors | awk '{print $1}'); do
  for i in $(aerospace list-workspaces --monitor $m); do
    sid=$i
    space=(
      space="$sid"
      icon="$sid"
      display=$m
      padding_left=2
      padding_right=2
      background.height=26

      icon.color=$AEROSPACE_TEXT_COLOR
      icon.highlight_color=$AEROSPACE_ACTIVE_TEXT_COLOR
      icon.padding_left=$LABEL_PADDING_LEFT
      icon.padding_right=$LABEL_PADDING_RIGHT
      icon.font="$LABEL_FONT"
      icon.y_offset=$LABEL_OFFSET_Y

      label.padding_right=$ICON_PADDING_RIGHT
      label.color=$AEROSPACE_TEXT_COLOR
      label.highlight_color=$AEROSPACE_ACTIVE_TEXT_COLOR
      label.font="$ICON_FONT"
      label.y_offset=$ICON_OFFSET_Y

      background.color=$AEROSPACE_BG_COLOR
    )

    sketchybar --add space space.$sid left                                  \
               --set space.$sid "${space[@]}" script="$PLUGIN_DIR/space.sh" \
               --subscribe space.$sid mouse.clicked

    apps=$(aerospace list-windows --workspace $sid | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

    icon_strip=""
    if [ "${apps}" != "" ]; then
      while read -r app
      do
        icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
      done <<< "${apps}"
    else
      icon_strip=" —"
    fi

    sketchybar --set space.$sid label="$icon_strip"
  done

  # Hide empty AeroSpace spaces
  for i in $(aerospace list-workspaces --monitor $m --empty); do
    sketchybar --set space.$i display=0
  done
done

space_creator=(
  icon=􀆊
  display=inactive
  padding_left=3
  icon.font="$NERD_FONT:Heavy:13.0"
  icon.color=$AEROSPACE_TEXT_COLOR
  icon.padding_right=10
  label.drawing=off
  background.height=26
)

sketchybar --add item space_creator left                  \
           --set space_creator "${space_creator[@]}"      \
                 script="$PLUGIN_DIR/space_windows.sh"    \
           --subscribe space_creator aerospace_workspace_change
