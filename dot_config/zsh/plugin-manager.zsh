#!/bin/zsh
# Antidote manages downloads only. plugins.zsh loads the files explicitly.

_zsh_prepare_antidote_plugins() {
    emulate -L zsh
    local manager="$ZDOTDIR/.antidote" stage='' backup='' repo dir lock_fd
    if ! (( $+commands[git] )); then
        print -u2 -- 'Zsh plugin downloads require Git; loading existing plugins only.'
        return 1
    fi
    : >> "$ZDOTDIR/.cache/plugins.lock" || return 1
    if ! zmodload zsh/system || ! zsystem flock -t 5 -f lock_fd "$ZDOTDIR/.cache/plugins.lock"; then
        print -u2 -- 'Zsh plugin downloads are busy or locking is unavailable; loading existing plugins only.'
        return 1
    fi
    {
        if [[ ! -r "$manager/antidote.zsh" ]] ||
            [[ ! -r "$manager/functions/antidote-setup" && ! -r "$manager/functions/__antidote_setup" ]]; then
            stage=$(command mktemp -d "$ZDOTDIR/.cache/antidote-install.XXXXXX") || return 1
            command git clone --depth=1 --single-branch https://github.com/mattmc3/antidote.git "$stage/repo" || return 1
            [[ -r "$stage/repo/antidote.zsh" ]] || return 1
            if [[ -e $manager ]]; then
                backup=$(command mktemp -d "$ZDOTDIR/.cache/antidote-incomplete.XXXXXX") || return 1
                command mv -- "$manager" "$backup/checkout" || return 1
                print -u2 -- "Preserved incomplete Antidote checkout in $backup/checkout"
            fi
            command mv -- "$stage/repo" "$manager" || return 1
        fi
        export ANTIDOTE_HOME="$ZDOTDIR/.antidote-plugins"
        zstyle ':antidote:bundle' use-friendly-names yes
        source "$manager/antidote.zsh" || return 1

        for repo in "${_zsh_plugin_repos[@]}"; do
            dir="${_zsh_plugin_dirs[${repo:t}]}"
            # Retry an interrupted clone instead of treating any directory as ready.
            if ! command git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1; then
                if [[ -e $dir ]]; then
                    backup=$(command mktemp -d "$ZDOTDIR/.cache/plugin-incomplete.XXXXXX") || return 1
                    command mv -- "$dir" "$backup/checkout" || return 1
                    print -u2 -- "Preserved incomplete plugin checkout in $backup/checkout"
                fi
                antidote bundle "$repo kind:clone" >/dev/null || return 1
                command git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1 || return 1
            fi
        done
    } always {
        [[ -z $stage ]] || command rm -rf -- "$stage"
        zsystem flock -u "$lock_fd"
    }
}

_zsh_prepare_antidote_plugins
unfunction _zsh_prepare_antidote_plugins
