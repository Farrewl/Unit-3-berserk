#!/usr/bin/env bash
# ── Unit-3 Now-Playing toggle ──
# Bound to SUPER+Enter. Opens/closes the MPRIS "Now Playing" panel.
#
# The panel is a remote control only — it can't play anything by itself.
# So: if no MPRIS player is active and YouTube Music isn't running yet,
# start YouTube Music first, then toggle the panel.

if ! pgrep -x youtube-music >/dev/null 2>&1; then
    # Only auto-start when nothing else is controllable via MPRIS.
    if ! playerctl -l 2>/dev/null | grep -q .; then
        command -v youtube-music >/dev/null 2>&1 && \
            setsid youtube-music >/dev/null 2>&1 &
    fi
fi

echo t >> /tmp/qs-toggle
