#!/bin/zsh

if (( $+commands[hyprctl] )); then
    function hyprctl() {
        if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
            command hyprctl -i 0 "$@"
        else
            command hyprctl "$@"
        fi
    }
fi
