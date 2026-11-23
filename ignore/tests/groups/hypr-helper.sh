#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154

safe_stderr="$tmp_dir/hyprctl-safe.stderr"
fallback_output=$(PATH=/usr/bin:/bin \
    "$repo_dir/ignore/bin/hyprctl-safe" \
    '__dotfiles_test_invalid_command__' 'test fallback' \
    2>"$safe_stderr")
[[ ! -s $safe_stderr ]] || fail 'hyprctl-safe must suppress errors'
[[ $fallback_output == 'test fallback' ]] \
    || fail 'hyprctl-safe must print the requested fallback'
pass 'hyprctl-safe returns the requested fallback'
