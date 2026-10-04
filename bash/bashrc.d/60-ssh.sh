# SSH terminal compatibility.
#
# kitty sets TERM=xterm-kitty. ssh forwards TERM verbatim, so a remote host
# without the xterm-kitty terminfo entry (every stock box, CTF target, jump
# host) falls back to broken cursor handling: readline redraws leave stale
# characters behind when you edit a recalled or pasted command line.
#
# Inside kitty, ssh goes through kitty's ssh kitten when it is available: it
# copies the xterm-kitty terminfo and shell integration to the remote (needs a
# POSIX sh and a writable $HOME there), so the remote cwd is reported back and
# new_tab_with_cwd / new_window_with_cwd reopen on the same host and directory.
# Nested hops work as long as the next box also has kitten (this file runs
# there too and picks it up).
#
# Non-interactive use (ssh host cmd | ..., redirects) and hosts without kitten
# fall back to plain ssh with TERM downgraded to xterm-256color, which always
# works and installs nothing.
#
#   sshp  - force the plain fallback (Windows targets, read-only $HOME).

if [[ "$TERM" == xterm-kitty ]]; then
    sshp() {
        TERM=xterm-256color command ssh "$@"
    }

    if command -v kitten >/dev/null 2>&1; then
        ssh() {
            if [[ -t 0 && -t 1 ]]; then
                kitten ssh "$@"
            else
                sshp "$@"
            fi
        }
    else
        ssh() { sshp "$@"; }
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
