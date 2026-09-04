# Interactive shell options.

# Keep LINES/COLUMNS correct after each command.
shopt -s checkwinsize

# ** matches across directories.
shopt -s globstar

# Fix minor typos in cd arguments.
shopt -s cdspell dirspell 2>/dev/null

# Make less handle non-text input (Debian family ships lesspipe as a script,
# Fedora as lesspipe.sh).
if [[ -x /usr/bin/lesspipe ]]; then
    eval "$(SHELL=/bin/sh lesspipe)"
elif [[ -x /usr/bin/lesspipe.sh ]]; then
    export LESSOPEN="|/usr/bin/lesspipe.sh %s"
fi

export EDITOR="${EDITOR:-vim}"
export LESS="-R"

# Colourise man pages. groff emits bold/underline; less renders them as plain
# text unless these termcap slots are overridden with real SGR sequences.
export LESS_TERMCAP_mb=$'\e[1;31m'   # start blink       -> red
export LESS_TERMCAP_md=$'\e[1;36m'   # start bold        -> cyan (headings)
export LESS_TERMCAP_me=$'\e[0m'      # end all modes
export LESS_TERMCAP_so=$'\e[1;33;40m' # start standout   -> yellow on black
export LESS_TERMCAP_se=$'\e[0m'      # end standout
export LESS_TERMCAP_us=$'\e[4;32m'   # start underline   -> green (arguments)
export LESS_TERMCAP_ue=$'\e[0m'      # end underline
export GROFF_NO_SGR=1                # make groff emit the codes less expects
