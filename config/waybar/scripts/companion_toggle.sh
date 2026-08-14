#!/usr/bin/env bash
set -u

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/unit3"
state_file="$state_dir/companion.state"

read_state() {
    if [[ -r "$state_file" ]] && [[ "$(<"$state_file")" == "off" ]]; then
        printf 'off\n'
    else
        printf 'on\n'
    fi
}

write_state() {
    local state="$1"
    local temporary

    mkdir -p "$state_dir"
    temporary="${state_file}.tmp.$$"
    printf '%s\n' "$state" > "$temporary"
    mv -f "$temporary" "$state_file"
}

update_quickshell() {
    local state="$1"
    local visible="false"

    [[ "$state" == "on" ]] && visible="true"
    qs ipc call companion setVisible "$visible" >/dev/null 2>&1 || true
}

refresh_waybar() {
    pkill -RTMIN+10 waybar 2>/dev/null || true
}

status_json() {
    if [[ "$(read_state)" == "on" ]]; then
        printf '{"text":"CMP ON","class":"active","tooltip":"Companion terlihat"}\n'
    else
        printf '{"text":"CMP --","class":"inactive","tooltip":"Companion disembunyikan"}\n'
    fi
}

set_state() {
    local state="$1"

    write_state "$state"
    update_quickshell "$state"
    refresh_waybar
}

case "${1:-status}" in
    toggle)
        if [[ "$(read_state)" == "on" ]]; then
            set_state off
        else
            set_state on
        fi
        status_json
        ;;
    on|off)
        set_state "$1"
        status_json
        ;;
    raw)
        read_state
        ;;
    status|*)
        status_json
        ;;
esac
