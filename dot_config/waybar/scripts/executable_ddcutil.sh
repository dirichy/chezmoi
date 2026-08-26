#!/bin/bash

DISPLAY_NUM=1
STEP=5
STATE_FILE="/tmp/waybar_brightness.tmp"

set_brightness_in_background() {
	pkill -f "ddcutil.*setvcp 10"
	(ddcutil --display "$DISPLAY_NUM" setvcp 10 "$1") &
}

if [ ! -f "$STATE_FILE" ]; then
	initial_brightness=$(ddcutil --display "$DISPLAY_NUM" getvcp 10 -t 2>/dev/null | awk '{print $4}')
	if ! [[ "$initial_brightness" =~ ^[0-9]+$ ]]; then
		initial_brightness=50
	fi
	echo "$initial_brightness" > "$STATE_FILE"
fi

current=$(cat "$STATE_FILE")
if ! [[ "$current" =~ ^[0-9]+$ ]]; then
	current=50
	echo "$current" > "$STATE_FILE"
fi

case "$1" in
	get)
		echo "$current"
		;;
	up)
		new_brightness=$((current + STEP > 100 ? 100 : current + STEP))
		if [ "$current" -ne "$new_brightness" ]; then
			echo "$new_brightness" > "$STATE_FILE"
			set_brightness_in_background "$new_brightness"
		fi
		pkill -RTMIN+9 waybar
		;;
	down)
		new_brightness=$((current - STEP < 0 ? 0 : current - STEP))
		if [ "$current" -ne "$new_brightness" ]; then
			echo "$new_brightness" > "$STATE_FILE"
			set_brightness_in_background "$new_brightness"
		fi
		pkill -RTMIN+9 waybar
		;;
	min)
		new_brightness=0
		if [ "$current" -ne "$new_brightness" ]; then
			echo "$new_brightness" > "$STATE_FILE"
			set_brightness_in_background "$new_brightness"
		fi
		pkill -RTMIN+9 waybar
		;;
	max)
		new_brightness=100
		if [ "$current" -ne "$new_brightness" ]; then
			echo "$new_brightness" > "$STATE_FILE"
			set_brightness_in_background "$new_brightness"
		fi
		pkill -RTMIN+9 waybar
		;;
esac
