# Unit-3 Berserk — minimal two-line prompt, pure fish (no external tools).
#
#   ╭─ ~/Projects/Unit-3-berserk · main ✗
#   ╰─❯ 
#
# Path / branch use the Berserk palette; the prompt sigil turns bright red
# when the previous command failed, gold otherwise.
function fish_prompt
    # Exit status of the previously executed command
    set -l last_status $status

    # ── Line 1: path + git summary ──
    set_color -o 8C1A16
    printf '╭─ '
    set_color normal
    set_color -o EBE3D1
    prompt_pwd
    set_color normal

    # Git branch with a dirty marker (only when inside a work tree)
    if command -sq git
        set -l branch (command git branch --show-current 2>/dev/null)
        if test -n "$branch"
            set -l dirty (command git status --porcelain 2>/dev/null | head -1)
            set_color A49C89
            printf ' · '
            set_color C5A253
            printf '%s' "$branch"
            if test -n "$dirty"
                set_color -o B42E28
                printf ' ✗'
            end
        end
    end
    set_color normal
    echo

    # ── Line 2: sigil ──
    if test $last_status -ne 0
        set_color -o B42E28
    else
        set_color -o C5A253
    end
    printf '╰─❯ '
    set_color normal
end