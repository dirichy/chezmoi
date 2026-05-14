#!/bin/zsh
#
# .aliases - Set whatever shell aliases you want.
#
alias fk='open -a Finder.app .'
alias bypy='python3 -m bypy'
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
function cd() {
    if [[ -z $(command -v z) ]]; then
        \builtin cd $*
        return $?
    fi
    z $*
    return $?
}
function wol(){
    local -A cmd
    cmd=(
        byl "ssh dell wakeonlan 34:5a:60:a6:66:44"
        wyy "ssh yoga wakeonlan 34:5a:60:a6:66:47"
    )
    local c=$cmd[$1]
    if [[ -z c ]]; then
        local -A mac=()
        local m=$mac[$1]
        if [[ -z m ]]; then
            wakeonlan $1
        else
            wakeonlan $m
        fi
    else
        zsh -c $c
    fi
}
# for macos
