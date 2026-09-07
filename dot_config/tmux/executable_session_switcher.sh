#!/usr/bin/env zsh

# Open window to select tmux session to switch to

result=$(tmux list-sessions | ~/.config/tmux/fzfp.sh | awk -F: '{print $1}')

if [[ -z $result ]]; then
    exit 0
fi

curr_session=$(tmux display-message -p '#S')

if [[ $curr_session == $result ]]; then
    exit 0
fi

if [[ -v TMUX ]]; then
    tmux switch-client -t "$result"
else
    tmux attach -t "$result"
fi
