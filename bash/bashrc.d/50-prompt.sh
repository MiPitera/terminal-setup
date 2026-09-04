# Powerline-style prompt: [user] > [git branch] > [cwd] >
#
# Rendering depends on powerline separator glyphs (U+E0B0). Those come from a
# Nerd Font; install.sh installs the symbols font and maps the range in
# kitty.conf. On a plain VT (TERM=linux) or when the glyphs are unavailable,
# set TERMINAL_SETUP_POWERLINE=0 to fall back to ASCII separators.

# Auto-detect: real consoles and dumb terminals cannot render the glyphs.
if [[ -z "${TERMINAL_SETUP_POWERLINE:-}" ]]; then
    case "$TERM" in
        linux|dumb|vt*) TERMINAL_SETUP_POWERLINE=0 ;;
        *)              TERMINAL_SETUP_POWERLINE=1 ;;
    esac
fi

if [[ "$TERMINAL_SETUP_POWERLINE" == "1" ]]; then
    _tsp_sep=$'\uE0B0'
else
    _tsp_sep=''
fi

# git-prompt tuning (no-op when __git_ps1 is unavailable).
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=
GIT_PS1_SHOWUPSTREAM="auto"

build_prompt() {
    local exit_code=$?          # preserve for anything else in PROMPT_COMMAND
    local sep="$_tsp_sep"
    local reset='\[\e[0m\]'
    local branch=''

    if declare -F __git_ps1 >/dev/null 2>&1; then
        branch=$(__git_ps1 '%s' 2>/dev/null)
    fi

    # user - white on dark green
    PS1='\[\e[48;5;22;38;5;255m\] \u '

    # host - only when it is not obvious which machine this is
    if [[ -n "${SSH_CONNECTION:-}" || -n "${TERMINAL_SETUP_SHOW_HOST:-}" ]]; then
        PS1+='\[\e[48;5;23;38;5;22m\]'"$sep"
        PS1+='\[\e[38;5;255m\] \h '
        local _prev=23
    else
        local _prev=22
    fi

    if [[ -n $branch ]]; then
        # separator: fg = previous background, bg = next background
        PS1+='\[\e[48;5;28;38;5;'"$_prev"'m\]'"$sep"
        PS1+='\[\e[38;5;255m\] '"$branch"' '
        PS1+='\[\e[48;5;35;38;5;28m\]'"$sep"
    else
        PS1+='\[\e[48;5;35;38;5;'"$_prev"'m\]'"$sep"
    fi

    # path - dark text on lighter green
    PS1+='\[\e[38;5;235m\] \w '
    # close out: default background, trailing arrow in the last segment colour
    PS1+="$reset"'\[\e[38;5;35m\]'"$sep$reset"' '

    return $exit_code
}

PROMPT_COMMAND=build_prompt

# Set the terminal/tab title to user@host: cwd
case "$TERM" in
    xterm*|rxvt*|kitty*|alacritty*|screen*|tmux*)
        PS1_TITLE='\[\e]0;\u@\h: \w\a\]'
        PROMPT_COMMAND='build_prompt; PS1="${PS1_TITLE}${PS1}"'
        ;;
esac
