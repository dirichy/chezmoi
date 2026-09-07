#!/usr/bin/env bash

# fzfp - Script to use tmux popups with fzf. Example:
#
#   > tmux list-sessions | ./fzfp
#
# https://github.com/kevinhwang91/fzf-tmux-script/blob/main/popup/fzfp

fail() {
    echo "$1" >&2
    exit 2
}

fzf=$(command -v fzf 2>/dev/null) || fzf=$(dirname "$0")/fzf
[[ -x "$fzf" ]] || fail 'fzf executable not found'

if [[ -n $TMUX_POPUP_NESTED_FB ]]; then
    exec "$fzf" "$@"
fi

# tmux -V | awk '{match($0, /[0-9]+\.[0-9]+/, m);exit m[0]<3.2}' || exec fzf "$@"

args=('--no-height')
while (($#)); do
    arg=$1
    case $arg in
    --height | --width)
        (($# >= 2)) || fail "$arg requires a value"
        case $arg in
        --height) height=$2 ;;
        --width) width=$2 ;;
        esac
        shift
        ;;
    --height=* | --width=*)
        case $arg in
        --height=*) height=${arg#--height=} ;;
        --width=*) width=${arg#--width=} ;;
        esac
        ;;
    *)
        args+=("$arg")
        ;;
    esac
    shift
done

opts=$(printf '%q ' "${args[@]}")

[[ -z $height ]] && height=${TMUX_POPUP_HEIGHT:-80%}
[[ -z $width ]] && width=${TMUX_POPUP_WIDTH:-80%}

envs="SHELL=$(printf %q "$SHELL")"
[[ -n $FZF_DEFAULT_OPTS ]] && envs="$envs FZF_DEFAULT_OPTS=$(printf %q "$FZF_DEFAULT_OPTS")"
[[ -n $FZF_DEFAULT_COMMAND ]] && envs="$envs FZF_DEFAULT_COMMAND=$(printf %q "$FZF_DEFAULT_COMMAND")"

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/fzfp.XXXXXXXXXX") || fail 'failed to create temp dir'
cmd_file="$tmpdir/cmd"
pstdin="$tmpdir/stdin"
pstdout="$tmpdir/stdout"

cleanup() {
    rm -rf -- "$tmpdir"
}
trap 'cleanup' EXIT

mkfifo "$pstdout"

printf 'trap %q EXIT SIGINT SIGTERM SIGHUP;' "rm -rf -- $(printf %q "$tmpdir")" >"$cmd_file"

if [[ -t 0 ]]; then
    printf 'exec %q %s> %q' "$fzf" "$opts" "$pstdout" >>"$cmd_file"
else
    mkfifo "$pstdin"
    printf 'exec %q %s< %q > %q' "$fzf" "$opts" "$pstdin" "$pstdout" >>"$cmd_file"
    cat <&0 >"$pstdin" &
fi
cat "$pstdout" &
tmux popup -d '#{pane_current_path}' -xC -yC -w"$width" -h"$height" -E "$envs bash $(printf %q "$cmd_file")"
