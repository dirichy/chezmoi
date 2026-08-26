#!/usr/bin/env bash

# Open the best available Tailscale terminal UI, with a CLI fallback.

set -euo pipefail

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
