# Keep the terminal line discipline sane across raw-mode tools.
#
# socat file:/dev/tty,raw,echo=0, impacket-psexec, nc-based reverse shells and
# anything else that drops the tty into raw mode is supposed to restore it on
# exit. When the connection dies or the tool is killed it does not: -onlcr
# survives, so a newline stops returning the carriage and every later prompt
# starts further right, output stair-steps, pasted lines redraw over stale
# characters. The shell is fine - only the line discipline is broken.
#
# Snapshot the discipline on the first prompt, compare on every later one, and
# restore whenever a command left it altered.
#
#   TERMINAL_SETUP_TTY_GUARD=0   disable entirely
#   ttysave                      adopt the current settings as the new baseline
#   fixterm                      full reset when the screen itself is corrupt

if [[ $- == *i* && -t 0 && "${TERMINAL_SETUP_TTY_GUARD:-1}" != "0" ]] \
   && command -v stty >/dev/null 2>&1; then

    _ts_tty_state=""

    _ts_tty_guard() {
        local now
        now=$(stty -g 2>/dev/null) || return 0
        if [[ -z "$_ts_tty_state" ]]; then
            _ts_tty_state="$now"
        elif [[ "$now" != "$_ts_tty_state" ]]; then
            stty "$_ts_tty_state" 2>/dev/null
        fi
    }

    # Re-baseline after deliberately changing settings (stty -ixon, etc).
    ttysave() {
        _ts_tty_state="$(stty -g 2>/dev/null)"
    }

    # Append rather than replace: 50-prompt.sh already owns PROMPT_COMMAND.
    if [[ -n "${PROMPT_COMMAND:-}" ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND%;}; _ts_tty_guard"
    else
        PROMPT_COMMAND="_ts_tty_guard"
    fi
fi
