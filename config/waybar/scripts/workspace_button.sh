#!/usr/bin/env bash
set -u

valid_workspace_id() {
    [[ "${1:-}" =~ ^([1-9]|10)$ ]]
}

show_status() {
    local id="$1"
    local active_id workspaces

    active_id="$(hyprctl activeworkspace 2>/dev/null | awk '$1 == "workspace" && $2 == "ID" { print $3; exit }')"
    workspaces="$(hyprctl workspaces 2>/dev/null)"

    if ! awk -v target="$id" '
        $1 == "workspace" && $2 == "ID" && $3 == target { found = 1 }
        END { exit found ? 0 : 1 }
    ' <<<"$workspaces"; then
        printf '{"text":"","class":"hidden"}\n'
    elif [[ "$active_id" == "$id" ]]; then
        printf '{"text":"%s","class":"active"}\n' "$id"
    else
        printf '{"text":"%s","class":"inactive"}\n' "$id"
    fi
}

case "${1:-}" in
    status)
        valid_workspace_id "${2:-}" || exit 2
        show_status "$2"
        ;;
    activate)
        valid_workspace_id "${2:-}" || exit 2
        exec hyprctl dispatch "hl.dsp.focus({ workspace = $2 })"
        ;;
    previous)
        exec hyprctl dispatch 'hl.dsp.focus({ workspace = "e-1" })'
        ;;
    next)
        exec hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'
        ;;
    *)
        exit 2
        ;;
esac
