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
