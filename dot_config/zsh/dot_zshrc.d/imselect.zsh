# Match imselect.nvim: SSH controls the client through Kitty; local shells use Fcitx.
typeset -g _zsh_imselect_driver=''
if [[ -n $SSH_TTY || -n $SSH_CONNECTION ]]; then
    _zsh_imselect_driver=kitty
elif whence fcitx5-remote >/dev/null 2>&1; then
    _zsh_imselect_driver=fcitx
fi
[[ -n $_zsh_imselect_driver ]] || return 0

typeset -g _zsh_imselect_saved=${_zsh_imselect_saved-}

_zsh_imselect_send() {
    local encoded osc esc=$'\e'
    case $1 in
        temp_ascii) encoded=dGVtcF9hc2NpaQ== ;;
        restore) encoded=cmVzdG9yZQ== ;;
        *) return 0 ;;
    esac
    osc=$'\e]1337;SetUserVar=im='"$encoded"$'\e\\'
    if [[ -n $TMUX ]]; then
        osc=$'\ePtmux;'"${osc//$esc/${esc}${esc}}"$'\e\\'
    fi
    print -rn -- "$osc"
}

# One worker owns the saved state and serializes slow Fcitx calls.
# NUL-separated fields preserve PATH and user function definitions without eval.
typeset -g _zsh_imselect_fd=${_zsh_imselect_fd-}

_zsh_imselect_fcitx_restore() {
    [[ -n $_zsh_imselect_saved ]] || return 0
    local flag=-c
    [[ $_zsh_imselect_saved != 2 ]] || flag=-o
    fcitx5-remote "$flag" >/dev/null 2>&1 || return 0
    _zsh_imselect_saved=''
}

_zsh_imselect_worker() {
    local action worker_path wrapper current
    local _zsh_imselect_saved=''
    trap '' INT QUIT
    trap '_zsh_imselect_fcitx_restore' EXIT
    while IFS= read -r -d '' action &&
        IFS= read -r -d '' worker_path &&
        IFS= read -r -d '' wrapper; do
        export PATH=$worker_path
        if [[ -n $wrapper ]]; then
            functions[fcitx5-remote]=$wrapper
        else
            unfunction fcitx5-remote 2>/dev/null
        fi
        case $action in
            temp_ascii)
                [[ -z $_zsh_imselect_saved ]] || continue
                current=$(fcitx5-remote 2>/dev/null) || continue
                # 0 means unavailable; do not save an unknown state.
                [[ $current == [12] ]] || continue
                if [[ $current == 2 ]]; then
                    fcitx5-remote -c >/dev/null 2>&1 || continue
                fi
                _zsh_imselect_saved=$current
                ;;
            restore) _zsh_imselect_fcitx_restore ;;
        esac
    done
    _zsh_imselect_fcitx_restore
    trap - EXIT
}

_zsh_imselect_request() {
    if [[ -z $_zsh_imselect_fd ]]; then
        [[ $1 == temp_ascii ]] || return 0
        exec {_zsh_imselect_fd}> >(_zsh_imselect_worker)
    fi
    print -rn -u "$_zsh_imselect_fd" -- "$1"$'\0'"$PATH"$'\0'"${functions[fcitx5-remote]-}"$'\0'
    return 0
}

_zsh_imselect_temp_ascii() {
    if [[ $_zsh_imselect_driver == kitty ]]; then
        [[ -z $_zsh_imselect_saved ]] || return 0
        _zsh_imselect_send temp_ascii
        _zsh_imselect_saved=kitty
    else
        _zsh_imselect_request temp_ascii
    fi
    return 0
}

_zsh_imselect_restore() {
    if [[ $_zsh_imselect_driver == kitty ]]; then
        [[ -n $_zsh_imselect_saved ]] || return 0
        _zsh_imselect_send restore
        _zsh_imselect_saved=''
    else
        _zsh_imselect_request restore
    fi
    return 0
}

_zsh_imselect_stop() {
    _zsh_imselect_restore
    if [[ -n $_zsh_imselect_fd ]]; then
        exec {_zsh_imselect_fd}>&-
        _zsh_imselect_fd=''
    fi
    return 0
}

_zsh_imselect_keymap() {
    case $KEYMAP in
        vicmd) _zsh_imselect_temp_ascii ;;
        viins|main) _zsh_imselect_restore ;;
    esac
    return 0
}

# Compose with prompt/plugin widgets instead of replacing their hooks.
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _zsh_imselect_keymap
add-zle-hook-widget keymap-select _zsh_imselect_keymap
# Queue restore before handing control to a command (including Neovim).
add-zle-hook-widget line-finish _zsh_imselect_restore
# Ctrl-C can abort ZLE without running line-finish.
autoload -Uz add-zsh-hook
add-zsh-hook precmd _zsh_imselect_restore
add-zsh-hook zshexit _zsh_imselect_stop
