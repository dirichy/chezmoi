#!/usr/bin/env bash

# Usage:
#   gpu.sh status  Emit Waybar JSON for NVIDIA GPU utilization.
#   gpu.sh usage   Open nvtop, or show nvidia-smi and wait for q, Esc, or Enter.

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

wait_for_close() {
	printf '\nPress q, Esc, or Enter to close'
	while IFS= read -rsn1 key; do
		case $key in
			q|Q|"") exit 0 ;;
			$'\e') exit 0 ;;
		esac
	done
}

usage() {
	if command -v nvtop >/dev/null 2>&1; then
		exec nvtop
	fi

	if command -v nvidia-smi >/dev/null 2>&1; then
		nvidia-smi || true
	else
		printf 'nvidia-smi is not installed\n'
	fi

	wait_for_close
}

status() {
	local line name util temp mem_used mem_total power limit class tooltip mem_percent
	local -a query_cmd

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
	mem_used=${mem_used:-0}
	mem_total=${mem_total:-0}
	mem_percent=0
	class=""

	if [[ $mem_used =~ ^[0-9]+$ && $mem_total =~ ^[0-9]+$ ]] && (( mem_total > 0 )); then
		mem_percent=$(( mem_used * 100 / mem_total ))
	fi

	if [[ $temp =~ ^[0-9]+$ ]] && (( temp >= 90 )); then
		class="critical"
	elif [[ $util =~ ^[0-9]+$ ]] && (( util >= 90 )); then
		class="critical"
	elif (( mem_percent >= 95 )); then
		class="critical"
	elif [[ $temp =~ ^[0-9]+$ ]] && (( temp >= 80 )); then
		class="warning"
	elif [[ $util =~ ^[0-9]+$ ]] && (( util >= 75 )); then
		class="warning"
	elif (( mem_percent >= 80 )); then
		class="warning"
	fi

	tooltip=$(printf '%s\nUsage: %s%%\nMemory: %s MiB / %s MiB (%s%%)\nTemperature: %s°C\nPower: %s W / %s W' \
		"${name:-GPU}" "${util:-?}" "${mem_used:-?}" "${mem_total:-?}" "$mem_percent" "${temp:-?}" "${power:-?}" "${limit:-?}")

	print_status "$icon ${util:-?}%" "$class" "$tooltip"
}

case "${1:-status}" in
	status) status ;;
	usage) usage ;;
	*) echo "usage: $0 [status|usage]" >&2; exit 1 ;;
esac
