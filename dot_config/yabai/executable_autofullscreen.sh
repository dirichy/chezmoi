#!/usr/bin/env bash
if [ -z "$YABAI_WINDOW_ID" ]; then
  YABAI_WINDOW_ID=$1
fi

YABAI_CURRENT_SPACE=$(
  /opt/homebrew/bin/yabai -m query --windows --window "$YABAI_WINDOW_ID" \
    | jq -r 'select(.app=="mpv") | .space'
)

if [ -n "$YABAI_CURRENT_SPACE" ]; then
  YABAI_NEW_SPACE_INDEX=$(
    /opt/homebrew/bin/yabai -m query --spaces \
      | jq 'length + 1'
  )
  /opt/homebrew/bin/yabai -m window --toggle native-fullscreen
  /opt/homebrew/bin/yabai -m query --spaces --space | jq -e '.index > 9' &&
  /opt/homebrew/bin/yabai -m space \
    "$YABAI_NEW_SPACE_INDEX" \
    --label "fullscreen$YABAI_CURRENT_SPACE"
fi
