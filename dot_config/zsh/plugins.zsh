#!/bin/zsh
# Both download backends use the same plugin list and loading order.

# Keep Zsh's history and plugin caches with the portable configuration.
zstyle ':zsh-utils:plugins:history' use-xdg-basedirs no
: ${ZSH_COMPDUMP:=$ZDOTDIR/.cache/zcompdump-$ZSH_VERSION}
: ${FAST_WORK_DIR:=$ZDOTDIR/.cache/fast-syntax-highlighting}
command mkdir -p -- "$ZDOTDIR/.cache" "${ZSH_COMPDUMP:h}" "$FAST_WORK_DIR"

source "$ZDOTDIR/plugin-backend.zsh"
_zsh_plugin_repos=("${(@f)$(<"$ZDOTDIR/plugin-repos.txt")}")
typeset -A _zsh_plugin_dirs
for _repo in "${_zsh_plugin_repos[@]}"; do
    if [[ $_zsh_plugin_backend == antidote ]]; then
        _zsh_plugin_dirs[${_repo:t}]="$ZDOTDIR/.antidote-plugins/$_repo"
    else
        _zsh_plugin_dirs[${_repo:t}]="$ZDOTDIR/plugins/${_repo:t}"
    fi
done
if [[ $_zsh_plugin_backend == antidote ]]; then
    source "$ZDOTDIR/plugin-manager.zsh"
fi

# Register all completion/function paths before initializing compinit.
for _plugin in "${(@v)_zsh_plugin_dirs}" \
    "${_zsh_plugin_dirs[zsh-completions]}/src" \
    "${_zsh_plugin_dirs[zsh-utils]}/completion/functions" \
    "${_zsh_plugin_dirs[zsh-utils]}/editor" \
    "${_zsh_plugin_dirs[zsh-utils]}/history" \
    "${_zsh_plugin_dirs[zsh-utils]}/utility" \
    "${_zsh_plugin_dirs[ohmyzsh]}/plugins/extract"; do
    [[ ! -d $_plugin ]] || fpath+=("$_plugin")
done
[[ ! -d ${_zsh_plugin_dirs[zsh-bench]} ]] || path=("${_zsh_plugin_dirs[zsh-bench]}" $path)

_zsh_missing_plugins=()
for _plugin in \
    ez-compinit/ez-compinit.plugin.zsh \
    zsh-utils/editor/editor.plugin.zsh \
    zsh-utils/history/history.plugin.zsh \
    zsh-utils/utility/utility.plugin.zsh; do
    _plugin_file="${_zsh_plugin_dirs[${_plugin%%/*}]}/${_plugin#*/}"
    if [[ -r $_plugin_file ]]; then
        source "$_plugin_file"
    else
        _zsh_missing_plugins+=("$_plugin")
    fi
done

# Initialize now so fzf-tab and local compdef calls always see real completions.
# Fall back to Zsh's built-in implementation if ez-compinit is missing.
if (( $+functions[run-compinit] )); then
    run-compinit
else
    autoload -Uz compinit
    compinit -i -d "$ZSH_COMPDUMP"
fi
if [[ -r "${_zsh_plugin_dirs[zsh-utils]}/completion/functions/compstyle_zshzoo_setup" ]]; then
    autoload -Uz compstyle_zshzoo_setup
    compstyle_zshzoo_setup
fi

for _plugin in \
    fzf-tab/fzf-tab.plugin.zsh \
    powerlevel10k/powerlevel10k.zsh-theme \
    ohmyzsh/plugins/extract/extract.plugin.zsh \
    fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
    zsh-autosuggestions/zsh-autosuggestions.plugin.zsh \
    zsh-history-substring-search/zsh-history-substring-search.plugin.zsh \
    zsh-lazyload/zsh-lazyload.plugin.zsh; do
    # A directory-only copy may land on a machine without fzf.
    if [[ $_plugin == fzf-tab/* ]] && ! (( $+commands[fzf] )); then
        continue
    fi
    _plugin_file="${_zsh_plugin_dirs[${_plugin%%/*}]}/${_plugin#*/}"
    if [[ -r $_plugin_file ]]; then
        source "$_plugin_file"
    else
        _zsh_missing_plugins+=("$_plugin")
    fi
done
if [[ $OSTYPE == darwin* ]]; then
    if [[ -r "${_zsh_plugin_dirs[macos]}/macos.plugin.zsh" ]]; then
        source "${_zsh_plugin_dirs[macos]}/macos.plugin.zsh"
    else
        _zsh_missing_plugins+=(macos/macos.plugin.zsh)
    fi
fi

if (( $#_zsh_missing_plugins )); then
    print -u2 -- "Zsh plugins missing: ${(j:, :)_zsh_missing_plugins}"
    if [[ $_zsh_plugin_backend == chezmoi ]]; then
        print -u2 -- 'Run chezmoi apply, or copy the complete .config/zsh directory.'
    else
        print -u2 -- 'Check Antidote download errors above, then start a new Zsh to retry.'
    fi
fi
unset _plugin _plugin_file _repo _zsh_missing_plugins _zsh_plugin_dirs _zsh_plugin_repos _zsh_plugin_backend
