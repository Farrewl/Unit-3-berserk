#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/unit3"
state_file="$state_dir/display.mode"
wallpaper_script="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/setwallpaper.sh"

monitor_data() {
    hyprctl -j monitors all 2>/dev/null | python3 -c '
import json
import sys

monitors = json.load(sys.stdin)
internal = next((m for m in monitors if m["name"].startswith("eDP")), None)
if internal is None and monitors:
    internal = monitors[0]

if internal is not None:
    print("internal|" + internal["name"])

for monitor in monitors:
    if internal is None or monitor["name"] != internal["name"]:
        print("external|" + monitor["name"])

mirrored = any(m.get("mirrorOf", "none") != "none" for m in monitors)
print("mode|" + ("mirror" if mirrored else "extend"))
'
}

load_monitors() {
    local kind value

    internal=""
    actual_mode="extend"
    externals=()

    while IFS='|' read -r kind value; do
        case "$kind" in
            internal) internal="$value" ;;
            external) externals+=("$value") ;;
            mode) actual_mode="$value" ;;
        esac
    done < <(monitor_data)
}

save_mode() {
    local mode="$1"
    local temporary

    mkdir -p "$state_dir"
    temporary="${state_file}.tmp.$$"
    printf '%s\n' "$mode" > "$temporary"
    mv -f "$temporary" "$state_file"
}

apply_mode() {
    local mode="$1"
    local output position mirror_field code

    load_monitors
    [[ -n "$internal" ]] || exit 0
    ((${#externals[@]} > 0)) || exit 0

    [[ "$internal" =~ ^[A-Za-z0-9._:-]+$ ]] || exit 1
    code="hl.monitor({ output = \"$internal\", mode = \"preferred\", position = \"0x0\", scale = 1 })"
    hyprctl eval "$code" >/dev/null

    for output in "${externals[@]}"; do
        [[ "$output" =~ ^[A-Za-z0-9._:-]+$ ]] || continue
        position="auto"
        mirror_field=', mirror = ""'
        if [[ "$mode" == "mirror" ]]; then
            position="0x0"
            mirror_field=", mirror = \"$internal\""
        fi
        code="hl.monitor({ output = \"$output\", mode = \"preferred\", position = \"$position\", scale = 1$mirror_field })"
        hyprctl eval "$code" >/dev/null
    done

    sleep 0.4
    [[ -x "$wallpaper_script" ]] && "$wallpaper_script" restore >/dev/null 2>&1 || true
}

status() {
    local names

    load_monitors
    if ((${#externals[@]} == 0)); then
        printf 'single|\n'
        return
    fi

    names="$(IFS=,; printf '%s' "${externals[*]}")"
    printf '%s|%s\n' "$actual_mode" "$names"
}

case "${1:-status}" in
    extend|mirror)
        load_monitors
        if ((${#externals[@]} == 0)); then
            notify-send "Display" "No external monitor connected" 2>/dev/null || true
            exit 0
        fi
        save_mode "$1"
        apply_mode "$1"
        ;;
    restore)
        mode="extend"
        if [[ -r "$state_file" ]]; then
            saved_mode="$(<"$state_file")"
            [[ "$saved_mode" == "mirror" ]] && mode="mirror"
        fi
        apply_mode "$mode"
        ;;
    status)
        status
        ;;
    *)
        printf 'Usage: display_mode.sh [status|extend|mirror|restore]\n' >&2
        exit 1
        ;;
esac
