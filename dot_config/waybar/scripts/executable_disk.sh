#!/usr/bin/env bash

# Emit Waybar JSON for local disk usage. The bar shows the fullest disk,
# while the tooltip lists all local block-device mount points.

set -uo pipefail

json_escape() {
	local value=${1-}
	value=${value//\\/\\\\}
	value=${value//\"/\\\"}
	value=${value//$'\n'/\\n}
	printf '%s' "$value"
}

label_for_mount() {
	case $1 in
		/) printf '/' ;;
		/home) printf '' ;;
		*) basename "$1" ;;
	esac
}

skip_mount() {
	case $1 in
		/boot|/boot/*|/efi|/efi/*|/winboot|/winboot/*) return 0 ;;
		/run|/run/*|/tmp|/tmp/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*) return 0 ;;
	esac

	return 1
}

text=""
rows=""
class=""
max_used=0
max_label=""
count=0
declare -A seen_mounts=()

while read -r target source fstype size used avail usep majmin; do
	[[ $source == /dev/* ]] || continue
	[[ -n ${seen_mounts[$majmin]+x} ]] && continue
	[[ $fstype == vfat || $fstype == swap ]] && continue
	skip_mount "$target" && continue

	percent=${usep%\%}
	[[ $percent =~ ^[0-9]+$ ]] || continue

	label=$(label_for_mount "$target")
	rows+=$(printf '%s\t%s\t%s%%\t%s/%s\tfree %s' "$target" "$source" "$percent" "$used" "$size" "$avail")
	rows+=$'\n'
	if (( percent > max_used )); then
		max_used=$percent
		max_label=$label
	fi
	(( count++ ))
	seen_mounts[$majmin]=1
done < <(findmnt -rn -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,USE%,MAJ:MIN 2>/dev/null)

if (( count == 0 )); then
	printf '{"text":"--","class":"disabled","tooltip":"No local disks found"}\n'
	exit 0
fi

text="$max_label ${max_used}%"
if command -v column >/dev/null 2>&1; then
	tooltip=$(printf '%s' "$rows" | column -t -s $'\t')
else
	tooltip=${rows//$'\t'/  }
	tooltip=${tooltip%$'\n'}
fi

if (( max_used >= 90 )); then
	class="critical"
elif (( max_used >= 80 )); then
	class="warning"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
	"$(json_escape "$text")" \
	"$class" \
	"$(json_escape "$tooltip")"
