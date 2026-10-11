#!/bin/bash
# lock.sh — Lance hyprlock avec fond pixel wave NieR
# Hyprland Lua bind: hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.config/hypr/lock.sh"), { release = true })

BG="$HOME/.config/hypr/lockbg.png"
SCRIPT="$HOME/.config/hypr/gen-lockbg.py"

# Generate the pixel wave background
# (si le script existe et que python3 est dispo)
if command -v python3 &>/dev/null && [ -f "$SCRIPT" ]; then
    python3 "$SCRIPT" "$BG" &
    sleep 0.15   # give the script time to start
fi

# Lancer hyprlock
# hyprlock handles keyboard focus automatically on open
exec hyprlock
