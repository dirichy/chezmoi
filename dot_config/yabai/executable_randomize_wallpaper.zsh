#!/usr/bin/env zsh
set -e

setopt extendedglob
setopt nullglob

source_dir="${WALLPAPER_SOURCE_DIR:-$HOME/Pictures/wallpaper}"
link_dir="${WALLPAPER_LINK_DIR:-$HOME/wallpaper}"
count="${WALLPAPER_LINK_COUNT:-9}"

if [[ ! -d "$source_dir" ]]; then
    printf 'wallpaper source directory does not exist: %s\n' "$source_dir" >&2
    exit 0
fi

wallpapers=(
    "$source_dir"/(#i)*.(jpg|jpeg|png|webp|bmp)(N.)
)

if (( ${#wallpapers} == 0 )); then
    printf 'no wallpapers found in: %s\n' "$source_dir" >&2
    exit 0
fi

mkdir -p "$link_dir"

# Fisher-Yates shuffle.
for ((i = ${#wallpapers}; i > 1; i--)); do
    j=$(( RANDOM % i + 1 ))
    tmp="${wallpapers[i]}"
    wallpapers[i]="${wallpapers[j]}"
    wallpapers[j]="$tmp"
done

for ((i = 1; i <= count; i++)); do
    wallpaper="${wallpapers[((i - 1) % ${#wallpapers} + 1)]}"

    yabai -m space --focus $i
    wallpaper set $wallpaper
done
