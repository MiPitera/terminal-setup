# History behaviour.

# Ignore duplicates and commands starting with a space.
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT='%F %T '

# Append rather than overwrite, so parallel shells do not clobber each other.
shopt -s histappend
