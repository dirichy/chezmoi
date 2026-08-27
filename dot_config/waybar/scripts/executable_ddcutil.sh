#!/usr/bin/env bash

set -u

DISPLAY_NUM=${WAYBAR_DDCUTIL_DISPLAY:-1}
STEP=${WAYBAR_BRIGHTNESS_STEP:-5}
STATE_DIR=${XDG_RUNTIME_DIR:-/tmp}
STATE_FILE="$STATE_DIR/waybar_brightness.tmp"
BACKEND_FILE="$STATE_DIR/waybar_brightness_backend.tmp"
SIGNAL=9

notify_waybar() {
	pkill -RTMIN+"$SIGNAL" waybar 2>/dev/null || true
}

is_number() {
	[[ ${1:-} =~ ^[0-9]+$ ]]
}

clamp() {
	local value=$1

	((value < 0)) && value=0
	((value > 100)) && value=100
	echo "$value"
}

ddc_get() {
	ddcutil --display "$DISPLAY_NUM" getvcp 10 -t 2>/dev/null | awk '{print $4}'
}

ddc_available() {
	command -v ddcutil >/dev/null || return 1
	is_number "$(ddc_get)"
}

brightnessctl_available() {
	command -v brightnessctl >/dev/null || return 1
	[[ -d /sys/class/backlight ]] || return 1
	find /sys/class/backlight -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .
}

detect_backend() {
	if ddc_available; then
		echo ddc
	elif brightnessctl_available; then
		echo brightnessctl
	else
		echo none
	fi
}

backend() {
	local selected

	if [[ -f $BACKEND_FILE ]]; then
		selected=$(cat "$BACKEND_FILE")
		case "$selected" in
			ddc | brightnessctl | none)
				echo "$selected"
				return
				;;
		esac
	fi

	selected=$(detect_backend)
	echo "$selected" > "$BACKEND_FILE"
	echo "$selected"
}

get_state() {
	local value

	if [[ -f $STATE_FILE ]]; then
		value=$(cat "$STATE_FILE")
		is_number "$value" && {
			clamp "$value"
			return
		}
	fi

	value=$(ddc_get)
	is_number "$value" || value=50
	value=$(clamp "$value")
	echo "$value" > "$STATE_FILE"
	echo "$value"
}

get_brightness() {
	local value

	case "$(backend)" in
		ddc) get_state ;;
		brightnessctl) brightnessctl -m | awk -F',' '{gsub("%", "", $4); print $4}' ;;
		*) echo "--" ;;
	esac
}

set_ddc() {
	local value=$1

	echo "$value" > "$STATE_FILE"
	pkill -f "ddcutil.*setvcp 10" 2>/dev/null || true
	(ddcutil --display "$DISPLAY_NUM" setvcp 10 "$value" >/dev/null 2>&1) &
}

set_brightness() {
	local action=$1
	local current value

	case "$(backend)" in
		ddc)
			current=$(get_state)
			case "$action" in
				up) value=$((current + STEP)) ;;
				down) value=$((current - STEP)) ;;
				min) value=0 ;;
				max) value=100 ;;
			esac
			set_ddc "$(clamp "$value")"
			;;
		brightnessctl)
			case "$action" in
				up) brightnessctl -n set "$STEP%+" >/dev/null ;;
				down) brightnessctl -n set "$STEP%-" >/dev/null ;;
				min) brightnessctl -n set 0% >/dev/null ;;
				max) brightnessctl -n set 100% >/dev/null ;;
			esac
			;;
		none)
			notify-send -t 1000 "Brightness" "No supported brightness backend" 2>/dev/null || true
			;;
	esac

	notify_waybar
}

case "${1:-get}" in
	get) get_brightness ;;
	up | down | min | max) set_brightness "$1" ;;
	backend) backend ;;
	refresh-backend) rm -f "$BACKEND_FILE"; backend ;;
	*) echo "usage: $0 [get|up|down|min|max|backend]" >&2; exit 1 ;;
esac
