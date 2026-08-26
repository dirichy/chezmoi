#!/usr/bin/env bash

# Open nvtop when available, otherwise show nvidia-smi and wait for a key.

set -euo pipefail

if command -v nvtop >/dev/null 2>&1; then
	exec nvtop
fi

if command -v nvidia-smi >/dev/null 2>&1; then
	nvidia-smi || true
else
	printf 'nvidia-smi is not installed\n'
fi

printf '\nPress q, Esc, or Enter to close'
while IFS= read -rsn1 key; do
	case $key in
		q|Q|"") exit 0 ;;
		$'\e') exit 0 ;;
	esac
done
