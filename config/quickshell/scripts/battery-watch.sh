#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="$runtime_dir/unit3-battery-watch.lock"
state_file="$runtime_dir/unit3-battery-watch.state"
poll_seconds="${UNIT3_BATTERY_POLL_SECONDS:-60}"

command -v notify-send >/dev/null 2>&1 || exit 0
command -v flock >/dev/null 2>&1 || exit 0

exec 9>"$lock_file"
flock -n 9 || exit 0

find_battery_dir() {
    local bat

    for bat in /sys/class/power_supply/BAT*; do
        if [[ -r "$bat/capacity" && -r "$bat/status" ]]; then
            printf '%s\n' "$bat"
            return 0
        fi
    done

    return 1
}

threshold_for_capacity() {
    local capacity="$1"

    if (( capacity <= 5 )); then
        printf '5\n'
    elif (( capacity <= 10 )); then
        printf '10\n'
    elif (( capacity <= 15 )); then
        printf '15\n'
    elif (( capacity <= 20 )); then
        printf '20\n'
    else
        printf '0\n'
    fi
}

read_last_threshold() {
    if [[ -r "$state_file" ]]; then
        cat "$state_file"
    else
        printf '0\n'
    fi
}

write_last_threshold() {
    printf '%s\n' "$1" > "$state_file"
}

send_battery_notification() {
    local threshold="$1"
    local capacity="$2"
    local urgency title body timeout icon

    case "$threshold" in
        20)
            urgency="normal"
            timeout="8000"
            icon="battery-caution"
            title="BATTERY ${capacity}%"
            body="Battery is getting low. Find a charger before the drama starts."
            ;;
        15)
            urgency="critical"
            timeout="10000"
            icon="battery-low"
            title="BATTERY ${capacity}% - WARNING"
            body="Seriously, plug in the charger now. This isn't decoration in the top bar."
            ;;
        10)
            urgency="critical"
            timeout="12000"
            icon="battery-empty"
            title="BATTERY ${capacity}% - CRITICAL"
            body="I told you earlier. Save your work, grab the charger, now."
            ;;
        5)
            urgency="critical"
            timeout="15000"
            icon="battery-empty"
            title="BATTERY ${capacity}% - FINAL WARNING"
            body="THIS IS AN EMERGENCY. PLUG IN THE CHARGER OR THE LAPTOP DIES IN YOUR HANDS."
            ;;
        *)
            return 0
            ;;
    esac

    notify-send -a "Unit-3 Battery" -u "$urgency" -t "$timeout" -i "$icon" "$title" "$body"
}

while true; do
    battery_dir="$(find_battery_dir || true)"

    if [[ -z "${battery_dir:-}" ]]; then
        sleep "$poll_seconds"
        continue
    fi

    capacity="$(<"$battery_dir/capacity")"
    status="$(<"$battery_dir/status")"

    if [[ ! "$capacity" =~ ^[0-9]+$ ]]; then
        sleep "$poll_seconds"
        continue
    fi

    if [[ "$status" != "Discharging" ]]; then
        write_last_threshold 0
        sleep "$poll_seconds"
        continue
    fi

    threshold="$(threshold_for_capacity "$capacity")"
    last_threshold="$(read_last_threshold)"

    if [[ ! "$last_threshold" =~ ^[0-9]+$ ]]; then
        last_threshold=0
    fi

    if (( threshold == 0 )); then
        write_last_threshold 0
    elif (( last_threshold == 0 || threshold < last_threshold )); then
        send_battery_notification "$threshold" "$capacity"
        write_last_threshold "$threshold"
    fi

    sleep "$poll_seconds"
done
