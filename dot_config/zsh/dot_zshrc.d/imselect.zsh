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

_zsh_imselect_temp_ascii() {
    [[ -z $_zsh_imselect_saved ]] || return 0
    if [[ $_zsh_imselect_driver == kitty ]]; then
        _zsh_imselect_send temp_ascii
        _zsh_imselect_saved=kitty
    else
        local current
        current=$(fcitx5-remote 2>/dev/null) || return 0
        # 0 means unavailable; do not save an unknown state.
        [[ $current == [12] ]] || return 0
        if [[ $current == 2 ]]; then
            fcitx5-remote -c >/dev/null 2>&1 || return 0
        fi
        _zsh_imselect_saved=$current
    fi
    return 0
}

_zsh_imselect_restore() {
    [[ -n $_zsh_imselect_saved ]] || return 0
    if [[ $_zsh_imselect_driver == kitty ]]; then
        _zsh_imselect_send restore
    else
        local flag=-c
        [[ $_zsh_imselect_saved != 2 ]] || flag=-o
        fcitx5-remote "$flag" >/dev/null 2>&1 || return 0
    fi
    _zsh_imselect_saved=''
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
# Release temporary ASCII before handing control to a command (including Neovim).
add-zle-hook-widget line-finish _zsh_imselect_restore
# Ctrl-C can abort ZLE without running line-finish.
autoload -Uz add-zsh-hook
add-zsh-hook precmd _zsh_imselect_restore
