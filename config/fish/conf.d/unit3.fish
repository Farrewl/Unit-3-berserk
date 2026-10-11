# Unit-3 Berserk — fish tuning (lightweight, zero external dependencies)
#
# All colours are hex values from the kitty Berserk palette so fish matches
# the rest of the terminal exactly. No third-party plugins are used.

# ── No startup banner ──
set -g fish_greeting ""

# ── Berserk palette for fish ──
# fg      #EBE3D1  cream / ink
# fg2     #B3A88C
# fg3     #857B66  dim parchment gray
# accent  #8C1A16  blood red (dark)
# bright  #B42E28  bright blood red
# gold    #C5A253

set -g fish_color_normal          EBE3D1
set -g fish_color_command         C5A253   # commands in gold
set -g fish_color_param           EBE3D1   # arguments in cream
set -g fish_color_option          857B66   # --flags dimmed
set -g fish_color_quote           857B66
set -g fish_color_redirection     C5A253
set -g fish_color_end             857B66
set -g fish_color_error           B42E28
set -g fish_color_operator        C5A253
set -g fish_color_escape          8C1A16
set -g fish_color_comment         857B66
set -g fish_color_valid_path      --underline

# Inline autosuggestions: brighten from the kitty default so they no longer
# blend into the background (#14100B). Brblack would map to #1D1913 - invisible.
set -g fish_color_autosuggestion  A49C89

# Tab-completion popup
set -g fish_color_selection       --background=14100B --foreground=C5A253
set -g fish_color_search_match    --background=8C1A16 --foreground=EBE3D1
set -g fish_color_cancel          --reverse