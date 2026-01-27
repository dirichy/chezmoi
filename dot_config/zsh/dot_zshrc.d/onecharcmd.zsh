# function p() {
# 	__current_proxy=$(gsettings get org.gnome.system.proxy mode)
# 	if [ "$__current_proxy" = "'manual'" ]; then
# 		gsettings set org.gnome.system.proxy mode none
# 		if [ $? -eq 0 ]; then
# 			echo "Closed proxy for system successfully!"
# 			return 0
# 		else
# 			echo "Closed proxy for system failed!"
# 			return 1
# 		fi
# 	elif [ "$__current_proxy" = "'none'" ]; then
# 		gsettings set org.gnome.system.proxy mode manual
# 		if [ $? -eq 0 ]; then
# 			echo "Opened proxy for system successfully!"
# 			return 0
# 		else
# 			echo "Opened proxy for system failed!"
# 			return 1
# 		fi
# 	else
# 		echo "Unknown mode:$__current_proxy"
# 		return 1
# 	fi
# 	return 0
# }
function s(){
    autossh -M 0 \
        -o "ServerAliveInterval=10" \
        -o "ServerAliveCountMax=3" \
        -t "$@" \
        "$SHELL -lc \"tmux new -A -s ssh\" || $SHELL -l"
}
function t() {
    if [[ -z $(which tmux) ]]; then
        echo "Did not install tmux"
        return 1
    fi
    __tmux_ls=$(tmux ls)
    if [[ $? -ne 0 || -z $__tmux_ls ]]; then
        echo "There is no session, input a name to create a session!"
        read __session_name
        if [ -z $__session_name ]; then
            __session_name="default"
        fi
        tmux new -s $__session_name
        return $?
    fi
    __tmux_ls=$(tmux ls | awk -F ':' '{print $1}' | nl)
    __tmux_ls_count=$(echo "$__tmux_ls" | grep -c .)
    if [ $__tmux_ls_count -eq 1 ]; then
        tmux attach
        return 0
    fi
    echo "There is mutiple sessions, input number to choose"
    echo "$__tmux_ls" | column -t
    read __number
    if [[ -z $__number ]]; then
        __number=1
    fi
    tmux attach -t $(echo "$__tmux_ls" | grep "^\s*$__number\s" | awk -F '	' '{print $2}')
    return $?
}
function v() {
    if [[ -z $(which nvim) ]]; then
        echo "Neovim not installed!"
        return 1
    fi
    if [ -z "$2" ]; then
        if [[ -z "$1" ]]; then
            nvim
            return 0
        fi
        if test -f "$1"; then
            nvim $1
            return 0
        fi
        if test -d "$1"; then
            if [[ ! -z $(which zoxide) ]]; then
                zoxide add $1
                \builtin cd $1
            fi
            nvim .
            return 0
        fi
        if [[ ! -z $(which zoxide) ]]; then
            for knownpath in $(zoxide query -l); do
                if test -f $knownpath/$1; then
                    if [[ $(file $knownpath/$1) =~ "text" ]]; then
                        zoxide add $knownpath
                        nvim $knownpath/$1
                        return 0
                    fi
                fi
            done
        fi
        if test -f $HOME/$1; then
            if [[ $(file $HOME/$1) =~ "text" ]]; then
                nvim $HOME/$1
                return 0
            fi
        fi
    fi
    if [[ ! -z $(which zoxide) ]]; then
        filepath=$(zoxide query $*)
        if [[ $? == 0 ]]; then
            zoxide add $filepath
            \builtin cd $filepath
            nvim .
            return 0
        fi
    fi
    if [[ ! -z $(which fzf) ]]; then
        filename=$(fzf -f $*)
        if [[ -n $filename ]]; then
            filename=$(fzf -q $*)
            if [[ -n $filename ]]; then
                if test -f $filename; then
                    zoxide add $(dirname $filename)
                fi
                if test -d $filename; then
                    zoxide add $filename
                fi
                nvim $filename
                return 0
            fi
        fi
    fi
    return 1
}
function u() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2) tar xjf $1 ;;
            *.tar.gz) tar xzf $1 ;;
            *.tar.xz) tar xf $1 ;;
            *.bz2) bunzip2 $1 ;;
            *.rar) rar x $1 ;;
            *.gz) gunzip $1 ;;
            *.tar) tar xf $1 ;;
            *.tbz2) tar xjf $1 ;;
            *.tgz) tar xzf $1 ;;
            *.zip) unzip $1 ;;
            *.Z) uncompress $1 ;;
            *.7z) 7z x $1 ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
function o() {
    if [ -f $1 ]; then
        case $1 in
            *.pdf) zathura $1 ;;
            *.tex) nvim $1 ;;
            *.txt) nvim $1 ;;
            *) open $1 ;;
        esac
    elif [ -d $1 ]; then
        yazi $1
    else
        echo "unknown file or dictionary"
    fi
}
function b() {
    __path_to_cd=""
    if [ -z $1 ]; then
        __path_to_cd="../"
    else
        for i in $(seq 1 $1); do
            __path_to_cd="$__path_to_cd../"
        done
    fi
    \builtin cd "$__path_to_cd"
    return $?
}
function g() {
    if [ -z $(which lazygit) ]; then
        echo "lazygit not installed!"
        return 1
    fi
    if [ -z $2 ]; then
        if [ -z $1 ]; then
            lazygit
            return $?
        fi
        if [ -d "$1" ]; then
            lazygit -p "$1"
            return $?
        fi
    fi
    if [ ! -z $(which zoxide) ]; then
        __path_to_git=$(zoxide query $*)
        if [ $? -eq 0 ]; then
            lazygit -p "$__path_to_git"
            return $?
        fi
    fi
    return 1
}
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
