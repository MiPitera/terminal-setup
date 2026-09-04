# Programmable completion. Paths differ per distribution, so probe each one.

if ! shopt -oq posix; then
    for _bc in \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion \
        /usr/local/etc/profile.d/bash_completion.sh
    do
        if [[ -r "$_bc" ]]; then
            . "$_bc"
            break
        fi
    done
    unset _bc
fi

# __git_ps1 lives in different packages/paths per distribution. Debian and Kali
# ship it inside git-core; Fedora ships it under contrib/completion.
if ! declare -F __git_ps1 >/dev/null 2>&1; then
    for _gp in \
        /usr/lib/git-core/git-sh-prompt \
        /usr/share/git-core/contrib/completion/git-prompt.sh \
        /usr/share/git/completion/git-prompt.sh \
        /etc/bash_completion.d/git-prompt \
        /usr/local/share/git-core/contrib/completion/git-prompt.sh
    do
        if [[ -r "$_gp" ]]; then
            . "$_gp"
            break
        fi
    done
    unset _gp
fi

# Readline colouring. Both default to off, which is why completion candidates
# render as flat white even though LS_COLORS is populated. Set here rather than
# in ~/.inputrc so the whole config stays inside the repo.
bind 'set colored-stats on'              # colour completions by file type
bind 'set colored-completion-prefix on'  # highlight the already-typed prefix
bind 'set completion-ignore-case on'     # Tab-complete regardless of case
bind 'set show-all-if-ambiguous on'      # one Tab lists candidates, not two
bind 'set menu-complete-display-prefix on'
