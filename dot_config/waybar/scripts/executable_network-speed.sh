#!/usr/bin/env bash

set -uo pipefail

state_dir=${XDG_RUNTIME_DIR:-/tmp}
if [[ ! -w $state_dir ]]; then
	state_dir=/tmp
fi
state_file="$state_dir/waybar-network-speed.state"

json_escape() {
	local value=${1-}
	value=${value//\\/\\\\}
	value=${value//\"/\\\"}
	value=${value//$'\n'/\\n}
	printf '%s' "$value"
}

format_speed() {
	local bytes=${1:-0}
	local value
	if (( bytes >= 1073741824 )); then
		value=$(awk -v b="$bytes" 'BEGIN { printf "%.1fG", b / 1073741824 }')
	elif (( bytes >= 1048576 )); then
		value=$(awk -v b="$bytes" 'BEGIN { printf "%.1fM", b / 1048576 }')
	elif (( bytes >= 1024 )); then
		value=$(awk -v b="$bytes" 'BEGIN { printf "%.0fK", b / 1024 }')
	else
		value="${bytes}B"
	fi
	printf '%-5s' "$value"
}

iface=$(ip route show default 2>/dev/null | awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }')
if [[ -z ${iface:-} ]]; then
	for candidate in /sys/class/net/*; do
		candidate=${candidate##*/}
		case $candidate in
			lo|tailscale*) continue ;;
		esac
		[[ -r /sys/class/net/$candidate/operstate ]] || continue
		[[ $(<"/sys/class/net/$candidate/operstate") == up ]] || continue
		if [[ -r /sys/class/net/$candidate/statistics/rx_bytes && -r /sys/class/net/$candidate/statistics/tx_bytes ]]; then
			iface=$candidate
			break
		fi
	done
fi
if [[ -z ${iface:-} || ! -r /sys/class/net/$iface/statistics/rx_bytes || ! -r /sys/class/net/$iface/statistics/tx_bytes ]]; then
	printf '{"text":"","class":"disabled","tooltip":""}\n'
	exit 0
fi

now=$(date +%s)
rx=$(<"/sys/class/net/$iface/statistics/rx_bytes")
tx=$(<"/sys/class/net/$iface/statistics/tx_bytes")

prev_now=0
prev_rx=$rx
prev_tx=$tx
if [[ -r $state_file ]]; then
	read -r prev_now prev_rx prev_tx < "$state_file" || true
fi
printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state_file"

delta=$(( now - prev_now ))
if (( delta <= 0 )); then
	delta=1
fi

rx_rate=$(( (rx - prev_rx) / delta ))
tx_rate=$(( (tx - prev_tx) / delta ))
(( rx_rate < 0 )) && rx_rate=0
(( tx_rate < 0 )) && tx_rate=0

down=$(format_speed "$rx_rate")
up=$(format_speed "$tx_rate")
text=$(printf '↓%s\n↑%s' "$down" "$up")
tooltip=$(printf '%s\nDown: %s/s\nUp: %s/s' "$iface" "$down" "$up")

printf '{"text":"%s","tooltip":"%s"}\n' "$(json_escape "$text")" "$(json_escape "$tooltip")"
