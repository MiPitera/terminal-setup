# SSH terminal compatibility.
#
# kitty sets TERM=xterm-kitty. ssh forwards TERM verbatim, so a remote host
# without the xterm-kitty terminfo entry (every stock box, CTF target, jump
# host) falls back to broken cursor handling: readline redraws leave stale
# characters behind when you edit a recalled or pasted command line.
#
# Two escape hatches:
#   ssh   - downgrade TERM to xterm-256color; always works, no remote install.
#   kssh  - kitty's own ssh kitten; copies the terminfo to the remote and
#           keeps kitty-specific features, but needs a writable $HOME there.

if [[ "$TERM" == xterm-kitty ]]; then
    ssh() {
        TERM=xterm-256color command ssh "$@"
    }

    if command -v kitten >/dev/null 2>&1; then
        kssh() {
            kitten ssh "$@"
        }
    fi
fi

# Repair a session that is already misbehaving (reverse shell, su, tmux
# started before TERM was fixed).
fixterm() {
    export TERM=xterm-256color
    stty sane
    tput reset 2>/dev/null || reset
    # Adopt the freshly sane discipline as the guard's baseline (61-tty-guard.sh).
    declare -F ttysave >/dev/null 2>&1 && ttysave
}

# Print a paste-ready snippet for a remote shell that scrolls the input line
# horizontally - a line rendered as "<...>" with the start cut off - instead of
# wrapping it onto the next row.
#
# Cause: the remote has no terminfo entry for its $TERM (a reverse shell
# inherits an empty or bogus one). Readline then cannot read the autowrap (am)
# capability and falls back to horizontal scrolling; "bind 'set
# horizontal-scroll-mode off'" does not override that, only a resolvable TERM
# does. A reverse shell also never negotiates geometry the way ssh does, so
# pin the rows and columns from this terminal at the same time.
ptyfix() {
    local cols rows
    cols=$(tput cols 2>/dev/null); [[ -n "$cols" ]] || cols=80
    rows=$(tput lines 2>/dev/null); [[ -n "$rows" ]] || rows=24
    printf 'for t in xterm-256color xterm vt100; do infocmp "$t" >/dev/null 2>&1 && { export TERM="$t"; break; }; done; stty rows %s cols %s\n' \
        "$rows" "$cols"
}
