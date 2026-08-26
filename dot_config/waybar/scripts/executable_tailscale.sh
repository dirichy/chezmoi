#!/usr/bin/env bash

# Usage:
#   tailscale.sh status  Emit Waybar JSON for Tailscale status.
#   tailscale.sh menu    Open the best available Tailscale terminal UI.

set -uo pipefail

icon="󰖂"

json_escape() {
	local value=${1-}
	value=${value//\\/\\\\}
	value=${value//\"/\\\"}
	value=${value//$'\n'/\\n}
	printf '%s' "$value"
}

print_status() {
	local class=$1
	local tooltip=$2

	printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
		"$icon" \
		"$(json_escape "$class")" \
		"$(json_escape "$tooltip")"
}

menu() {
	if command -v tsui >/dev/null 2>&1; then
		exec tsui
	fi

	if command -v tailtui >/dev/null 2>&1; then
		exec tailtui
	fi

	if command -v tailscale >/dev/null 2>&1; then
		tailscale status
	else
		printf 'tailscale is not installed\n'
	fi

	printf '\nInstall tsui or tailtui for an interactive Tailscale TUI.\n'
	printf 'Press Enter to close'
	read -r _
}

status() {
	local status state self

	if ! command -v tailscale >/dev/null 2>&1; then
		print_status "disabled" "Tailscale: unavailable"
		exit 0
	fi

	if ! command -v jq >/dev/null 2>&1; then
		print_status "disabled" "Tailscale: jq unavailable"
		exit 0
	fi

	if command -v timeout >/dev/null 2>&1; then
		status_cmd=(timeout 2s tailscale status --json)
	else
		status_cmd=(tailscale status --json)
	fi

	if ! status=$("${status_cmd[@]}" 2>/dev/null); then
		print_status "disconnected" "Tailscale: disconnected"
		exit 0
	fi

	state=$(jq -r '.BackendState // "Unknown"' <<<"$status")
	state=${state:-Unknown}

	if [[ $state == "Running" ]]; then
		self=$(jq -r '.Self.DNSName // empty' <<<"$status")
		self=${self%.}
		if [[ -n $self ]]; then
			print_status "connected" "Tailscale: $self"
		else
			print_status "connected" "Tailscale: Running"
		fi
	else
		print_status "disconnected" "Tailscale: $state"
	fi
}

case "${1:-status}" in
	status) status ;;
	menu) menu ;;
	*) echo "usage: $0 [status|menu]" >&2; exit 1 ;;
esac
