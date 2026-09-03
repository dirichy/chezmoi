#!/bin/zsh
#
# .aliases - Set whatever shell aliases you want.
#
alias fk='open -a Finder.app .'
alias bypy='python3 -m bypy'
paru() {
    local arg
    local do_keyring=0

    for arg in "$@"; do
        case "$arg" in
            -S|-Su|-Syu|-Syuu|-Syyu|-Syyuu)
                do_keyring=1
                break
                ;;
            -S*)
                # 排除纯查询类
                case "$arg" in
                    -Ss|-Si|-Sg|-Sl|-Sp)
                        ;;
                    *)
                        do_keyring=1
                        break
                        ;;
                esac
                ;;
        esac
    done

    if (( do_keyring )); then
        sudo pacman -Sy --needed --noconfirm archlinux-keyring || return
    fi

    command paru --sudoloop "$@"
}
yay(){
    paru "$@"
}
# single character aliases - be sparing!
alias _=sudo
if [ -n "$(whence lsd)" ]; then
    alias ls='lsd'
fi
# alias g=git

# mask built-ins with better defaults
# alias vi=vim

# more ways to ls
alias ll='ls -lh'
alias la='ls -lAh'
alias l.='ls -ld .*'
alias l='ls -lhA'

# alias sed=gsed
# fix common typos
alias q='exit'

# tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# find
alias fd='find . -type d -name'
alias ff='find . -type f -name'

# url encode/decode
alias urldecode='python3 -c "import sys, urllib.parse as ul; \
    print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; \
    print (ul.quote_plus(sys.argv[1]))"'

# misc
alias please=sudo
alias zshrc='${EDITOR:-nvim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'
alias zdot='cd ${ZDOTDIR:-~}'
function wol(){
    local -A cmd
    cmd=(
        byl "ssh dell wakeonlan 34:5a:60:a6:66:44"
        wyy "ssh yoga wakeonlan 34:5a:60:a6:66:47"
    )
    if [[ -n ${cmd[$1]} ]]; then
        command zsh -c "${cmd[$1]}"
    else
        command wakeonlan "$1"
    fi
}
# for macos
