#!/usr/bin/env bash
shopt -s nullglob

emit_desktop_file() {
    local f="$1"
    local name="" exec="" cats="" nod="" hid="" desktop line

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            Name=*)       [ -z "$name" ] && name=${line#Name=} ;;
            Exec=*)       [ -z "$exec" ] && exec=${line#Exec=} ;;
            Categories=*) [ -z "$cats" ] && cats=${line#Categories=} ;;
            NoDisplay=*)  [ -z "$nod" ]  && nod=${line#NoDisplay=} ;;
            Hidden=*)     [ -z "$hid" ]  && hid=${line#Hidden=} ;;
        esac
    done < "$f"

    [ "$nod" = "true" ] && return
    [ "$hid" = "true" ] && return
    [ -z "$name" ]      && return
    [ -z "$exec" ]      && return

    while [[ "$exec" =~ (.*)[[:space:]]%[A-Za-z](.*) ]]; do
        exec="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    done

    desktop=${f##*/}
    desktop=${desktop%.desktop}
    echo "$name|$desktop|$cats|$exec"
}

declare -A seen=()
data_dirs=("${XDG_DATA_HOME:-$HOME/.local/share}")

IFS=':' read -r -a system_data_dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
data_dirs+=("${system_data_dirs[@]}")

for dir in "${data_dirs[@]}"; do
    app_dir="$dir/applications"
    [ -d "$app_dir" ] || continue

    for f in "$app_dir"/*.desktop; do
        desktop=${f##*/}
        [ -n "${seen[$desktop]:-}" ] && continue
        seen[$desktop]=1
        emit_desktop_file "$f"
    done
done | sort -u
