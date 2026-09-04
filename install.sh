#!/usr/bin/env bash
#
# terminal-setup installer
#
# Installs the bash configuration and the kitty configuration (including the
# colour theme and the fonts the prompt needs) on Ubuntu, Debian, Kali and
# Fedora. Safe to re-run: existing files are backed up before anything is
# replaced.
#
#   ./install.sh                 # packages + fonts + configs, via symlinks
#   ./install.sh --no-packages   # configs only, no root needed
#   ./install.sh --copy          # copy files instead of symlinking
#   ./install.sh --dry-run       # print what would happen
#   ./install.sh --uninstall     # restore the most recent backups
#
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/distro.sh
source "$REPO_DIR/lib/distro.sh"

# ---------------------------------------------------------------- options ---
DO_PACKAGES=1
DO_FONTS=1
DO_BASH=1
DO_KITTY=1
LINK_MODE="symlink"       # symlink | copy
KITTY_THEME="Espresso"
DRY_RUN=0
UNINSTALL=0

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_SUFFIX=".terminal-setup-backup"
FONT_DIR="$HOME/.local/share/fonts/terminal-setup"
COPY_TARGET="$HOME/.config/terminal-setup"

# ---------------------------------------------------------------- output ----
if [[ -t 1 ]]; then
    C_RED=$'\e[31m'; C_YLW=$'\e[33m'; C_GRN=$'\e[32m'; C_BLU=$'\e[34m'; C_OFF=$'\e[0m'
else
    C_RED=''; C_YLW=''; C_GRN=''; C_BLU=''; C_OFF=''
fi
info() { printf '%s==>%s %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn() { printf '%s warn%s %s\n' "$C_YLW" "$C_OFF" "$*" >&2; }
die()  { printf '%serror%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }
run()  {
    if (( DRY_RUN )); then
        printf '       [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

usage() {
    cat <<'USAGE'
terminal-setup installer

Installs the bash configuration and the kitty configuration (theme + fonts)
on Ubuntu, Debian, Kali and Fedora. Safe to re-run: anything it replaces is
backed up first.

Usage: ./install.sh [options]

Options:
  --no-packages     Do not install distribution packages (no root required)
  --no-fonts        Do not download or install fonts
  --bash-only       Only install the bash configuration
  --kitty-only      Only install the kitty configuration
  --copy            Copy files instead of creating symlinks
  --theme NAME      kitty theme from kitty/themes (default: Espresso)
  --dry-run         Show the actions without performing them
  --uninstall       Restore the most recent backups and remove the symlinks
  -h, --help        This message
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-packages) DO_PACKAGES=0 ;;
        --no-fonts)    DO_FONTS=0 ;;
        --bash-only)   DO_KITTY=0; DO_PACKAGES=0 ;;
        --kitty-only)  DO_BASH=0 ;;
        --copy)        LINK_MODE="copy" ;;
        --theme)       KITTY_THEME="${2:?--theme needs a name}"; shift ;;
        --dry-run)     DRY_RUN=1 ;;
        --uninstall)   UNINSTALL=1 ;;
        -h|--help)     usage; exit 0 ;;
        *)             die "Unknown option: $1 (try --help)" ;;
    esac
    shift
done

# --------------------------------------------------------------- helpers ----

# Back up an existing path, unless it is already one of our symlinks.
backup_path() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0

    if [[ -L "$target" ]]; then
        local dest
        dest="$(readlink -f "$target" 2>/dev/null || true)"
        if [[ "$dest" == "$REPO_DIR"/* || "$dest" == "$COPY_TARGET"/* ]]; then
            return 0   # our own link from a previous run
        fi
    fi

    local backup="${target}${BACKUP_SUFFIX}.${STAMP}"
    info "Backing up $target -> $backup"
    run mv "$target" "$backup"
}

# Install SOURCE at DEST, honouring LINK_MODE.
install_file() {
    local src="$1" dest="$2"
    run mkdir -p "$(dirname "$dest")"
    backup_path "$dest"
    if [[ "$LINK_MODE" == "symlink" ]]; then
        run ln -sfn "$src" "$dest"
    else
        run cp -f "$src" "$dest"
    fi
    ok "$dest"
}

need_root() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    elif command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        return 1
    fi
    return 0
}

# ------------------------------------------------------------- uninstall ----
do_uninstall() {
    info "Uninstalling"
    local targets=(
        "$HOME/.bashrc"
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/kitty/theme.conf"
    )
    local t newest
    for t in "${targets[@]}"; do
        if [[ -L "$t" ]]; then
            local dest; dest="$(readlink -f "$t" 2>/dev/null || true)"
            if [[ "$dest" == "$REPO_DIR"/* || "$dest" == "$COPY_TARGET"/* ]]; then
                run rm -f "$t"
                ok "removed link $t"
            fi
        fi
        # Restore the newest backup, if there is one.
        newest="$(ls -1d "${t}${BACKUP_SUFFIX}."* 2>/dev/null | sort | tail -1 || true)"
        if [[ -n "$newest" ]]; then
            run mv "$newest" "$t"
            ok "restored $t from $(basename "$newest")"
        fi
    done
    info "Fonts in $FONT_DIR were left in place; remove them manually if unwanted."
    exit 0
}

# --------------------------------------------------------------- packages ---
install_packages() {
    local pkgs
    mapfile -t pkgs < <(resolve_packages)
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        warn "No package list for this distribution; skipping package install."
        return 0
    fi

    if ! need_root; then
        warn "Not root and sudo is unavailable; skipping package install."
        warn "Install manually: ${pkgs[*]}"
        return 0
    fi

    info "Installing packages (${DISTRO_NAME}): ${pkgs[*]}"
    # shellcheck disable=SC2086
    run $SUDO $PKG_UPDATE || warn "package index update failed; continuing"
    # shellcheck disable=SC2086
    if ! run $SUDO $PKG_INSTALL "${pkgs[@]}"; then
        warn "Package installation failed; continuing with the configuration."
        return 0
    fi
    ok "packages installed"
}

# ------------------------------------------------------------------ fonts ---
DM_MONO_BASE="https://raw.githubusercontent.com/google/fonts/main/ofl/dmmono"
DM_MONO_FILES=(
    DMMono-Regular.ttf
    DMMono-Italic.ttf
    DMMono-Medium.ttf
    DMMono-MediumItalic.ttf
    DMMono-Light.ttf
    DMMono-LightItalic.ttf
)
NERD_SYMBOLS_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip"

install_fonts() {
    if ! command -v curl >/dev/null 2>&1; then
        warn "curl not found; skipping font installation."
        return 0
    fi

    info "Installing fonts into $FONT_DIR"
    run mkdir -p "$FONT_DIR"

    local f
    for f in "${DM_MONO_FILES[@]}"; do
        if [[ -f "$FONT_DIR/$f" ]]; then
            ok "$f (already present)"
            continue
        fi
        if run curl -fsSL --retry 2 -o "$FONT_DIR/$f" "$DM_MONO_BASE/$f"; then
            ok "$f"
        else
            warn "could not download $f"
            run rm -f "$FONT_DIR/$f"
        fi
    done

    # Symbols-only Nerd Font supplies the powerline glyphs the prompt uses.
    if compgen -G "$FONT_DIR/SymbolsNerdFont*.ttf" >/dev/null; then
        ok "Symbols Nerd Font (already present)"
    elif ! command -v unzip >/dev/null 2>&1; then
        warn "unzip not found; skipping Symbols Nerd Font."
        warn "Without it the powerline separators in the prompt will not render."
    else
        local tmp; tmp="$(mktemp -d)"
        if run curl -fsSL --retry 2 -o "$tmp/symbols.zip" "$NERD_SYMBOLS_URL" \
           && run unzip -qo "$tmp/symbols.zip" -d "$FONT_DIR" '*.ttf'; then
            ok "Symbols Nerd Font"
        else
            warn "could not install Symbols Nerd Font (no network?); the prompt"
            warn "will still work - run with TERMINAL_SETUP_POWERLINE=0 for ASCII."
        fi
        run rm -rf "$tmp"
    fi

    if command -v fc-cache >/dev/null 2>&1; then
        run fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
        ok "font cache rebuilt"
    else
        warn "fc-cache not found; log out and back in for fonts to be picked up."
    fi
}

# ------------------------------------------------------------------- bash ---
install_bash() {
    info "Installing bash configuration"

    local src_root="$REPO_DIR"
    if [[ "$LINK_MODE" == "copy" ]]; then
        # Copy mode keeps a self-contained tree so the clone can be deleted.
        info "Copying modules to $COPY_TARGET"
        run mkdir -p "$COPY_TARGET"
        run cp -a "$REPO_DIR/bash" "$COPY_TARGET/"
        src_root="$COPY_TARGET"
    fi

    install_file "$src_root/bash/bashrc" "$HOME/.bashrc"

    # In copy mode ~/.bashrc is a real file, so it cannot resolve its own
    # location through a symlink; it falls back to ~/.config/terminal-setup,
    # which is exactly where the modules were copied. Verify that holds.
    if [[ "$LINK_MODE" == "copy" && $DRY_RUN -eq 0 && "$src_root" != "$COPY_TARGET" ]]; then
        warn "copy target $src_root is not the expected $COPY_TARGET"
    fi

    if [[ ! -e "$HOME/.bashrc.local" ]]; then
        run cp "$REPO_DIR/bash/bashrc.local.example" "$HOME/.bashrc.local"
        ok "$HOME/.bashrc.local (from template)"
    else
        ok "$HOME/.bashrc.local (kept)"
    fi

    # Fedora's ~/.bash_profile sources ~/.bashrc; Debian's ~/.profile does the
    # same. Make sure at least one of them exists so login shells pick it up.
    if [[ ! -e "$HOME/.bash_profile" && ! -e "$HOME/.profile" ]]; then
        run bash -c "printf '%s\n' '[ -f \"\$HOME/.bashrc\" ] && . \"\$HOME/.bashrc\"' > '$HOME/.bash_profile'"
        ok "$HOME/.bash_profile (created)"
    fi
}

# ------------------------------------------------------------------ kitty ---
install_kitty() {
    info "Installing kitty configuration"

    local theme_src="$REPO_DIR/kitty/themes/${KITTY_THEME}.conf"
    [[ -f "$theme_src" ]] || die "Theme not found: $theme_src (available: $(cd "$REPO_DIR/kitty/themes" && ls *.conf | sed 's/\.conf$//' | tr '\n' ' '))"

    local src_root="$REPO_DIR"
    if [[ "$LINK_MODE" == "copy" ]]; then
        run mkdir -p "$COPY_TARGET"
        run cp -a "$REPO_DIR/kitty" "$COPY_TARGET/"
        src_root="$COPY_TARGET"
    fi

    install_file "$src_root/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    install_file "$src_root/kitty/themes/${KITTY_THEME}.conf" "$HOME/.config/kitty/theme.conf"

    if ! command -v kitty >/dev/null 2>&1; then
        warn "kitty is not installed yet; the configuration is in place for when it is."
    fi
}

# ------------------------------------------------------------------- main ---
main() {
    detect_distro
    info "Detected: ${DISTRO_NAME} (family: ${DISTRO_FAMILY:-unknown})"

    if (( UNINSTALL )); then do_uninstall; fi

    if (( DO_PACKAGES )); then install_packages; fi
    if (( DO_FONTS ));    then install_fonts;    fi
    if (( DO_BASH ));     then install_bash;     fi
    if (( DO_KITTY ));    then install_kitty;    fi

    echo
    ok "Done."
    echo "  Reload the shell with:  exec bash"
    if (( DO_KITTY )); then echo "  Reload kitty config with: Ctrl+Shift+F5 (or restart kitty)"; fi
    echo "  Machine-specific settings: ~/.bashrc.local and ~/.config/kitty/local.conf"
}

main "$@"
