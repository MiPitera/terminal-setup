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
}
