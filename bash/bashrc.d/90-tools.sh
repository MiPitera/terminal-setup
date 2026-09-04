# Development toolchains. Every entry is guarded, so this file is safe on a
# freshly provisioned VM where none of them are installed.

# PATH helper: prepend only if the directory exists and is not already listed.
_ts_path_prepend() {
    [[ -d "$1" ]] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

_ts_path_prepend "$HOME/.local/bin"
_ts_path_prepend "$HOME/bin"
_ts_path_prepend "$HOME/.cargo/bin"
_ts_path_prepend "$HOME/go/bin"

# Deno
[[ -r "$HOME/.deno/env" ]] && . "$HOME/.deno/env"

# Bun
if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    _ts_path_prepend "$BUN_INSTALL/bin"
    [[ -r "$BUN_INSTALL/_bun" ]] && . "$BUN_INSTALL/_bun"
fi

# nvm
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
fi

# Android SDK
if [[ -d "$HOME/Android/Sdk" ]]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
    _ts_path_prepend "$ANDROID_HOME/platform-tools"
    _ts_path_prepend "$ANDROID_HOME/emulator"
fi

export PATH
