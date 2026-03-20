#!/bin/bash

update() {
  # 처음 시작에만 작동하기 위해서
  # 현재 forced, space_change 이벤트가 동시에 발생하고 있다.
  if [ "$SENDER" = "space_change" ]; then
    source "$CONFIG_DIR/colors.sh"

    COLOR=$BACKGROUND_2
    if [ "$SELECTED" = "true" ]; then
      COLOR=$GREY
    fi

    sketchybar --anim sin 5 --set space.$(aerospace list-workspaces --focused) \
                        icon.highlight=true \
                        label.highlight=true
  fi
}

set_space_label() {
  sketchybar --set $NAME icon="$@"
}

mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    # yabai -m space --destroy $SID
    echo ''
  else
    if [ "$MODIFIER" = "shift" ]; then
      SPACE_LABEL="$(osascript -e "return (text returned of (display dialog \"Give a name to space $NAME:\" default answer \"\" with icon note buttons {\"Cancel\", \"Continue\"} default button \"Continue\"))")"
      if [ $? -eq 0 ]; then
        if [ "$SPACE_LABEL" = "" ]; then
          set_space_label "${NAME:6}"
        else
          set_space_label "${NAME:6} ($SPACE_LABEL)"
        fi
      fi
    else
      aerospace workspace ${NAME#*.}
    fi
  fi
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked;;
  *) update;;
esac
