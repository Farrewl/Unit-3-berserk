#!/usr/bin/env bash

set -eu

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/unit3"
state_file="$state_dir/visualizer.state"

read_state() {
    if [[ -r "$state_file" ]] && [[ "$(<"$state_file")" == "on" ]]; then
        printf 'on\n'
    else
        printf 'off\n'
    fi
}

write_state() {
    mkdir -p "$state_dir"
    printf '%s\n' "$1" > "$state_file"
}

sync_quickshell() {
    if [[ "$1" == "on" ]]; then
        qs ipc call visualizer setEnabled true >/dev/null 2>&1 || true
    else
        qs ipc call visualizer setEnabled false >/dev/null 2>&1 || true
    fi
}

case "${1:-toggle}" in
    raw)
        read_state
        ;;
    on|off)
        write_state "$1"
        sync_quickshell "$1"
        ;;
    toggle)
        if [[ "$(read_state)" == "on" ]]; then
            write_state off
            sync_quickshell off
        else
            write_state on
            sync_quickshell on
        fi
        ;;
    *)
        printf 'Usage: %s [raw|on|off|toggle]\n' "$0" >&2
        exit 2
        ;;
esac
