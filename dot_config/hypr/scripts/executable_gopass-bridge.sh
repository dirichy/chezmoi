#!/usr/bin/env bash

item="$(gopass ls --flat | wofi -d)"
[ -z "$item" ] && exit 0

user="$(gopass show "$item" user)"
secret="$(gopass show --password "$item")"

sleep 0.5

wtype "$user"
wtype -k Tab

printf '%s' "$secret" | wl-copy

sleep 30

clipboard="$(wl-paste 2>/dev/null)"

if [[ "$clipboard" == "$secret" ]]; then
  wl-copy --clear
fi
