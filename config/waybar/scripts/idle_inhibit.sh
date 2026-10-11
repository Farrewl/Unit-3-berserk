#!/usr/bin/env bash
set -euo pipefail

unit_name="unit3-idle-inhibit.service"

start_inhibit() {
    is_active && return 0

    systemd-run \
        --user \
        --unit="${unit_name%.service}" \
        --description="Unit-3 Waybar always-on idle inhibitor" \
        --collect \
        systemd-inhibit \
        --what=idle \
        --who=Unit-3 \
        --why="Waybar always-on toggle" \
        --mode=block \
        sleep infinity >/dev/null
}

stop_inhibit() {
    systemctl --user stop "$unit_name" >/dev/null 2>&1 || true
}

is_active() {
    systemctl --user is-active --quiet "$unit_name"
}

refresh_waybar() {
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

status_json() {
    if is_active; then
        printf '{"text":"AON ON","class":"active","tooltip":"Always on active: idle lock (3 min) held"}\n'
    else
        printf '{"text":"AON OFF","class":"inactive","tooltip":"Always on off: auto-lock active after 3 minutes"}\n'
    fi
}

case "${1:-status}" in
    toggle)
        if is_active; then
            stop_inhibit
        else
            start_inhibit
        fi
        refresh_waybar
        status_json
        ;;
    on)
        start_inhibit
        refresh_waybar
        status_json
        ;;
    off)
        stop_inhibit
        refresh_waybar
        status_json
        ;;
    status|*)
        status_json
        ;;
esac
