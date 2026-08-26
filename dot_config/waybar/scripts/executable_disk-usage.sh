#!/usr/bin/env bash

# Show duf and keep the terminal open until q, Esc, or Enter.

set -euo pipefail

duf

printf '\nPress q, Esc, or Enter to close'
while IFS= read -rsn1 key; do
	case $key in
		q|Q|"") exit 0 ;;
		$'\e') exit 0 ;;
	esac
done
