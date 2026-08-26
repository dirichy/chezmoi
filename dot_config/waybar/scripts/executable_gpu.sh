#!/usr/bin/env bash

# Emit Waybar JSON for NVIDIA GPU utilization.

set -uo pipefail

icon="󰢮"

json_escape() {
	local value=${1-}
	value=${value//\\/\\\\}
	value=${value//\"/\\\"}
	value=${value//$'\n'/\\n}
	printf '%s' "$value"
}

print_status() {
	local text=$1
	local class=$2
	local tooltip=$3

	printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
		"$(json_escape "$text")" \
		"$(json_escape "$class")" \
		"$(json_escape "$tooltip")"
}

if ! command -v nvidia-smi >/dev/null 2>&1; then
	print_status "" "disabled" ""
	exit 0
fi

if command -v timeout >/dev/null 2>&1; then
	query_cmd=(timeout 2s nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,power.limit --format=csv,noheader,nounits)
else
	query_cmd=(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,power.limit --format=csv,noheader,nounits)
fi

if ! line=$("${query_cmd[@]}" 2>/dev/null | head -n 1); then
	print_status "$icon --" "disabled" "NVIDIA driver unavailable"
	exit 0
fi

if [[ -z $line ]]; then
	print_status "$icon --" "disabled" "No NVIDIA GPU found"
	exit 0
fi

line=${line//, /,}
IFS=',' read -r name util temp mem_used mem_total power limit <<<"$line"

util=${util:-0}
temp=${temp:-0}
class=""

if [[ $temp =~ ^[0-9]+$ ]]; then
	if (( temp >= 90 )); then
		class="critical"
	elif (( temp >= 80 )); then
		class="warning"
	fi
fi

tooltip=$(printf '%s\nUsage: %s%%\nMemory: %s MiB / %s MiB\nTemperature: %s°C\nPower: %s W / %s W' \
	"${name:-GPU}" "${util:-?}" "${mem_used:-?}" "${mem_total:-?}" "${temp:-?}" "${power:-?}" "${limit:-?}")

print_status "$icon ${util:-?}%" "$class" "$tooltip"
