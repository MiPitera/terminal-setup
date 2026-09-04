#!/usr/bin/env bash
# Distribution detection and package-manager abstraction.
# Sourced by install.sh. Supported: Ubuntu, Debian, Kali, Fedora.

DISTRO_ID=""
DISTRO_LIKE=""
DISTRO_NAME=""
DISTRO_FAMILY=""   # debian | fedora
PKG_INSTALL=""
PKG_UPDATE=""

detect_distro() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-}"
        DISTRO_LIKE="${ID_LIKE:-}"
        DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    else
        die "/etc/os-release not found - cannot identify distribution"
    fi

    case "$DISTRO_ID" in
        ubuntu|debian|kali|linuxmint|pop|raspbian)
            DISTRO_FAMILY="debian" ;;
        fedora|rhel|centos|rocky|almalinux)
            DISTRO_FAMILY="fedora" ;;
        *)
            # Fall back to ID_LIKE for derivatives we do not name explicitly.
            case " $DISTRO_LIKE " in
                *" debian "*|*" ubuntu "*) DISTRO_FAMILY="debian" ;;
                *" fedora "*|*" rhel "*)   DISTRO_FAMILY="fedora" ;;
                *) DISTRO_FAMILY="" ;;
            esac
            ;;
    esac

    case "$DISTRO_FAMILY" in
        debian)
            PKG_UPDATE="apt-get update -qq"
            PKG_INSTALL="apt-get install -y --no-install-recommends"
            ;;
        fedora)
            PKG_UPDATE="true"
            PKG_INSTALL="dnf install -y"
            command -v dnf5 >/dev/null 2>&1 && PKG_INSTALL="dnf5 install -y"
            ;;
        *)
            warn "Unsupported distribution: ${DISTRO_NAME:-unknown}"
            warn "Config files will still be installed; package installation is skipped."
            ;;
    esac
}

# Package names differ between families. Print the resolved list for this host.
resolve_packages() {
    local pkgs=()
    case "$DISTRO_FAMILY" in
        debian)
            pkgs=(kitty git bash-completion fontconfig curl unzip ca-certificates)
            ;;
        fedora)
            pkgs=(kitty git bash-completion fontconfig curl unzip ca-certificates)
            ;;
    esac
    printf '%s\n' "${pkgs[@]}"
}

# Where each distribution ships the git prompt helper (__git_ps1).
git_prompt_candidates() {
    cat <<'PATHS'
/usr/lib/git-core/git-sh-prompt
/usr/share/git-core/contrib/completion/git-prompt.sh
/usr/share/git/completion/git-prompt.sh
/etc/bash_completion.d/git-prompt
/usr/local/share/git-core/contrib/completion/git-prompt.sh
PATHS
}
