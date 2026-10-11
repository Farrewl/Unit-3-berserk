#!/bin/bash
# lock.sh — Launches hyprlock with the NieR pixel wave background
# Hyprland Lua bind: hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.config/hypr/lock.sh"), { release = true })

BG="$HOME/.config/hypr/lockbg.png"
SCRIPT="$HOME/.config/hypr/gen-lockbg.py"

# Generate the pixel wave background
# (if the script exists and python3 is available)
if command -v python3 &>/dev/null && [ -f "$SCRIPT" ]; then
    python3 "$SCRIPT" "$BG" &
    sleep 0.15   # give the script time to start
fi

# Launch hyprlock
# hyprlock handles keyboard focus automatically on open
exec hyprlock
