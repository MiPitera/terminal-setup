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
