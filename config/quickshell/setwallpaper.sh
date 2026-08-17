#!/usr/bin/env bash
set -eu

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/unit3"
state_file="$state_dir/wallpaper.path"

save_wallpaper() {
    local wallpaper="$1"
    local temporary

    mkdir -p "$state_dir"
    temporary="${state_file}.tmp.$$"
    printf '%s\n' "$wallpaper" > "$temporary"
    mv -f "$temporary" "$state_file"
}

restore_wallpaper() {
    local wallpaper

    [[ -r "$state_file" ]] || exit 0
    wallpaper="$(<"$state_file")"
    [[ -f "$wallpaper" ]] || exit 0
    awww img "$wallpaper"
}

if [[ "${1:-}" == "restore" ]]; then
    restore_wallpaper
    exit 0
fi

wallpaper="${1:-}"
target="${2:-both}"

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    printf 'Usage: setwallpaper.sh <path> <monitor_name|both>\n' >&2
    exit 1
fi

save_wallpaper "$wallpaper"

if [[ "$target" == "both" || -z "$target" ]]; then
    awww img "$wallpaper"
else
    awww img --outputs "$target" "$wallpaper"
fi
