#!/usr/bin/env bash

set -u

remote=${KITTY_LEADER_IM_REMOTE:-fcitx5-remote}
state_dir="${XDG_RUNTIME_DIR:-/tmp}/kitty-leader-im-${UID:-$(id -u)}"
state_file="$state_dir/state"

has_remote() {
	command -v "$remote" >/dev/null 2>&1
}

ensure_state_dir() {
	mkdir -p "$state_dir" || exit 0
	chmod 700 "$state_dir" 2>/dev/null || true
}

current_state() {
	local output
	output=$("$remote" 2>/dev/null) || return
	printf '%s' "$output" | tr -d '[:space:]'
}

temp_ascii() {
	has_remote || exit 0
	ensure_state_dir

	if [ -f "$state_file" ]; then
		return
	fi

	local state
	state=$(current_state) || exit 0
	printf '%s\n' "$state" >"$state_file"

	if [ "$state" = "2" ]; then
		"$remote" -c >/dev/null 2>&1 || true
	fi
}

restore() {
	has_remote || exit 0

	local state
	if [ ! -f "$state_file" ] || ! IFS= read -r state <"$state_file"; then
		exit 0
	fi
	rm -f -- "$state_file"

	if [ "$state" = "2" ]; then
		"$remote" -o >/dev/null 2>&1 || true
	fi
}

case "${1:-}" in
	temp_ascii) temp_ascii ;;
	restore) restore ;;
	*) exit 2 ;;
esac
