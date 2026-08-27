#!/usr/bin/env bash

set -uo pipefail

json_escape() {
	local value=${1-}
	value=${value//\\/\\\\}
	value=${value//\"/\\\"}
	value=${value//$'\n'/\\n}
	printf '%s' "$value"
}

add_alert() {
	local text=$1
	local detail=$2
	alerts+=("$text")
	details+=("$detail")
}

cpu_usage() {
	local idle_prev total_prev idle_curr total_curr idle_delta total_delta usage
	read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
	idle_prev=$(( idle + iowait ))
	total_prev=$(( user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice ))
	sleep 0.2
	read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
	idle_curr=$(( idle + iowait ))
	total_curr=$(( user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice ))
	idle_delta=$(( idle_curr - idle_prev ))
	total_delta=$(( total_curr - total_prev ))
	if (( total_delta <= 0 )); then
		printf '0'
		return
	fi
	usage=$(( (100 * (total_delta - idle_delta)) / total_delta ))
	printf '%s' "$usage"
}

memory_usage() {
	local total available
	total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
	available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
	if [[ -z ${total:-} || -z ${available:-} || $total -le 0 ]]; then
		printf '0'
		return
	fi
	printf '%s' $(( (total - available) * 100 / total ))
}

temperature() {
	local temp_file=/sys/class/thermal/thermal_zone1/temp
	if [[ ! -r $temp_file ]]; then
		printf '0'
		return
	fi
	printf '%s' $(( $(<"$temp_file") / 1000 ))
}

disk_usage() {
	local target source fstype size used avail usep majmin percent max_used
	declare -A seen_mounts=()
	max_used=0
	while read -r target source fstype size used avail usep majmin; do
		[[ $source == /dev/* ]] || continue
		[[ -n ${seen_mounts[$majmin]+x} ]] && continue
		[[ $fstype == vfat || $fstype == swap ]] && continue
		case $target in
			/boot|/boot/*|/efi|/efi/*|/winboot|/winboot/*|/run|/run/*|/tmp|/tmp/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*) continue ;;
		esac
		percent=${usep%\%}
		[[ $percent =~ ^[0-9]+$ ]] || continue
		(( percent > max_used )) && max_used=$percent
		seen_mounts[$majmin]=1
	done < <(findmnt -rn -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,USE%,MAJ:MIN 2>/dev/null)
	printf '%s' "$max_used"
}

gpu_status() {
	local line util temp mem_used mem_total mem_percent
	if ! command -v nvidia-smi >/dev/null 2>&1; then
		return
	fi
	line=$(timeout 2s nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n 1) || return
	[[ -n $line ]] || return
	line=${line//, /,}
	IFS=',' read -r util temp mem_used mem_total <<<"$line"
	mem_percent=0
	if [[ $mem_used =~ ^[0-9]+$ && $mem_total =~ ^[0-9]+$ ]] && (( mem_total > 0 )); then
		mem_percent=$(( mem_used * 100 / mem_total ))
	fi
	if [[ $temp =~ ^[0-9]+$ ]] && (( temp >= 90 )); then
		add_alert "󰢮 ${temp}°C" "GPU temperature: ${temp}°C"
	elif [[ $util =~ ^[0-9]+$ ]] && (( util >= 90 )); then
		add_alert "󰢮 ${util}%" "GPU usage: ${util}%"
	elif (( mem_percent >= 95 )); then
		add_alert "󰢮 ${mem_percent}%" "GPU memory: ${mem_percent}%"
	fi
}

alerts=()
details=()

cpu=$(cpu_usage)
mem=$(memory_usage)
temp=$(temperature)
disk=$(disk_usage)

(( cpu >= 90 )) && add_alert "󰍛 ${cpu}%" "CPU: ${cpu}%"
(( mem >= 92 )) && add_alert "󰘚 ${mem}%" "Memory: ${mem}%"
(( temp >= 90 )) && add_alert "󱃂 ${temp}°C" "Temperature: ${temp}°C"
(( disk >= 90 )) && add_alert " ${disk}%" "Disk: ${disk}%"
gpu_status

if (( ${#alerts[@]} == 0 )); then
	printf '{"text":"","class":"disabled","tooltip":""}\n'
	exit 0
fi

text=$(IFS=' '; printf '%s' "${alerts[*]}")
tooltip=$(IFS=$'\n'; printf '%s' "${details[*]}")
printf '{"text":"%s","class":"critical","tooltip":"%s"}\n' "$(json_escape "$text")" "$(json_escape "$tooltip")"
