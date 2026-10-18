#!/bin/env bash
# Minimal interactive Bash setup for shared server accounts.
# Source it explicitly; it intentionally does not assume control of ~/.bashrc.

source .profile

case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

__has() {
  command -v "$1" >/dev/null 2>&1
}

# Keep shared accounts tidy by default. Override before sourcing if wanted:
#   SERVER_BASH_HISTFILE=~/.bash_history.mine source ./server.bashrc
export HISTFILE=".bash_history_wyy"
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=5000
export HISTFILESIZE=5000
shopt -s histappend checkwinsize cmdhist 2>/dev/null || true

set -o vi
bind 'set show-mode-in-prompt off' 2>/dev/null || true
bind '"\e[A": history-search-backward' 2>/dev/null || true
bind '"\e[B": history-search-forward' 2>/dev/null || true
bind '"\C-p": history-search-backward' 2>/dev/null || true
bind '"\C-n": history-search-forward' 2>/dev/null || true
bind '"\C-l": clear-screen' 2>/dev/null || true

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"

if __has lsd; then
  alias ls='lsd'
fi

alias q='exit'
alias ll='ls -lh'
alias la='ls -lAh'
alias l.='ls -ld .*'
alias l='ls -lhA'
alias tarls='tar -tvf'
alias untar='tar -xf'
alias fd='find . -type d -name'
alias ff='find . -type f -name'
alias v.='${EDITOR:-nvim} .'
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'

b() {
  local levels=${1:-1}
  local target=""
  local i

  case $levels in
    ''|*[!0-9]*)
      printf 'Usage: b [number]\n' >&2
      return 1
      ;;
  esac

  for ((i = 0; i < levels; i++)); do
    target="../$target"
  done
  cd -- "$target" || return
}

s() {
  if __has autossh; then
    autossh -M 0 \
      -o "ServerAliveInterval=10" \
      -o "ServerAliveCountMax=3" \
      "$@"
  else
    ssh \
      -o "ServerAliveInterval=10" \
      -o "ServerAliveCountMax=3" \
      "$@"
  fi
}

t() {
  if ! __has tmux; then
    printf 'tmux is not installed.\n' >&2
    return 1
  fi

  local tmux_ls session_name number target first_char name_rest
  tmux_ls=$(tmux ls 2>/dev/null)
  if [[ -z $tmux_ls ]]; then
    printf 'There is no tmux session. Input a name to create one, or press [Esc] to quit:\n'
    IFS= read -r -n 1 first_char || return 0
    [[ $first_char == $'\e' ]] && { printf '\n'; return 0; }
    if [[ $first_char == $'\n' || $first_char == $'\r' ]]; then
      session_name=""
    else
      IFS= read -r name_rest
      session_name=$first_char$name_rest
    fi
    [[ -z $session_name ]] && session_name="default"
    if [[ -z $TMUX ]]; then
      exec tmux new-session -s "$session_name"
    fi
    tmux new-session -s "$session_name" -d && tmux switch-client -t "$session_name"
    return $?
  fi

  tmux_ls=$(tmux ls 2>/dev/null | awk -F ':' '{print $1}' | nl)
  printf 'Choose a session ([Enter] selects 1), press [a] to create one, or [q] to quit\n'
  if __has column; then
    printf '%s\n' "$tmux_ls" | column -t
  else
    printf '%s\n' "$tmux_ls"
  fi
  IFS= read -r -n 1 number
  printf '\n'

  [[ $number == q ]] && return 0
  [[ -z $number || $number == $'\n' || $number == $'\r' ]] && number=1
  if [[ $number == a ]]; then
    printf 'Input a name for the new tmux session, or press [Esc] to cancel:\n'
    IFS= read -r -n 1 first_char || return 0
    [[ $first_char == $'\e' ]] && { printf '\n'; return 0; }
    if [[ $first_char == $'\n' || $first_char == $'\r' ]]; then
      session_name=""
    else
      IFS= read -r name_rest
      session_name=$first_char$name_rest
    fi
    [[ -z $session_name ]] && session_name="default"
    if [[ -z $TMUX ]]; then
      exec tmux new-session -s "$session_name"
    fi
    tmux new-session -s "$session_name" -d && tmux switch-client -t "$session_name"
    return $?
  fi

  target=$(printf '%s\n' "$tmux_ls" | awk -v number="$number" '$1 == number { print $2 }')
  if [[ -z $target ]]; then
    printf 'Invalid selection: %s\n' "$number" >&2
    return 1
  fi
  if [[ -z $TMUX ]]; then
    exec tmux attach-session -t "$target"
  fi
  tmux switch-client -t "$target"
}

v() {
  local editor=${EDITOR:-}
  if [[ -z $editor ]]; then
    if __has nvim; then
      editor=nvim
    elif __has vim; then
      editor=vim
    else
      editor=vi
    fi
  fi

  if (($# == 0)); then
    "$editor"
    return $?
  fi

  if (($# == 1)); then
    if [[ -f $1 ]]; then
      "$editor" -- "$1"
      return $?
    fi
    if [[ -d $1 ]]; then
      __has zoxide && zoxide add -- "$1"
      cd -- "$1" || return
      "$editor" .
      return $?
    fi
    if [[ -f $HOME/$1 ]] && file -- "$HOME/$1" 2>/dev/null | grep -q text; then
      "$editor" -- "$HOME/$1"
      return $?
    fi
  fi

  if __has zoxide; then
    local path_to_dir
    path_to_dir=$(zoxide query -- "$@") || return 1
    zoxide add -- "$path_to_dir"
    cd -- "$path_to_dir" || return
    "$editor" .
    return $?
  fi

  return 1
}

g() {
  if ! __has lazygit; then
    printf 'lazygit is not installed.\n' >&2
    return 1
  fi

  if (($# == 0)); then
    lazygit
    return $?
  fi
  if (($# == 1)) && [[ -d $1 ]]; then
    lazygit -p "$1"
    return $?
  fi
  if __has zoxide; then
    local path_to_git
    path_to_git=$(zoxide query -- "$@") || return 1
    lazygit -p "$path_to_git"
    return $?
  fi
  return 1
}

y() {
  if ! __has yazi; then
    printf 'yazi is not installed.\n' >&2
    return 1
  fi

  local tmp cwd
  tmp=$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX") || return 1
  yazi "$@" --cwd-file="$tmp"
  if cwd=$(cat -- "$tmp") && [[ -n $cwd && $cwd != "$PWD" ]]; then
    cd -- "$cwd" || return
  fi
  rm -f -- "$tmp"
}

if __has zoxide; then
  eval "$(zoxide init bash)"
fi

if __has fzf; then
  eval "$(fzf --bash 2>/dev/null)" || true
fi
