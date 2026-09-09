#!/usr/bin/env bash
hyprshutdown &
sleep 5;
reboot
# hyprctl dispatch 'hl.dsp.exit()'
# rm -rf $XDG_RUNTIME_DIR/hypr
