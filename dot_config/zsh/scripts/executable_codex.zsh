#!/bin/zsh

set -euo pipefail

local cmd=${1:-}
local name=${2:-}
if [ -z "$cmd" ]; then
    codex
    return $?
fi

CODEX_DIR=${CODEX_HOME:-"$HOME/.codex"}
STORE_DIR="$HOME/.codex-accounts"
STATUS_FILE="$STORE_DIR/status.json"
# {
#    "current_account": "account_name",
#    "accounts": [
#       "account1","account2",...
#    ]
# }
mkdir -p "$STORE_DIR"
[ -f "$STATUS_FILE" ] || cat > "$STATUS_FILE" <<'JSON'
{
  "current_account": "",
  "accounts": []
}
JSON

usage() {
    echo "用法："
    echo "  $0 save <name>   保存当前登录为 <name>"
    echo "  $0 use  <name>   切换到 <name>"
    echo "  $0 new  <name?>  登录新账号，如果提供<name>则自动store"
    echo "  $0 list          列出所有账号"
    exit 1
}

store() {
    [ -n "$1" ] || return 1
    local target_path="$STORE_DIR/$1"
    mkdir -p "$target_path"
    if [ -f "$CODEX_DIR/auth.json" ]; then
        cp "$CODEX_DIR/auth.json" "$target_path/auth.json"
    else
        echo "⚠️  当前 $CODEX_DIR/auth.json 不存在，跳过"
        exit 1
    fi
    if [ -f "$CODEX_DIR/config.toml" ]; then
        cp "$CODEX_DIR/config.toml" "$target_path/config.toml"
    fi
}

restore() {
    local target_path="$STORE_DIR/$1"
    if [ -f "$target_path/auth.json" ]; then
        cp "$target_path/auth.json" "$CODEX_DIR/auth.json"
    else
        echo "⚠️  当前 $target_path/auth.json 不存在，跳过"
        exit 1
    fi
    if [ -f "$target_path/config.toml" ]; then
        cp "$target_path/config.toml" "$CODEX_DIR/config.toml"
    fi
}

error(){
    echo "$1";
    exit ${2:-1}
}

stop_codex() {
    timeout 5s codex app-server daemon stop || error "Codex is in use, stop all client first!"
    return 0
}
start_codex() {
    timeout 5s codex app-server daemon start || error "Start codex failed"
    return 0
}

add_account(){
    local target_account="$1"
    jq --arg account "$target_account" '
  .accounts |= (
    if index($account) == null
    then . + [$account]
    else .
    end
  )
' "$STATUS_FILE" > "$STATUS_FILE.new" && mv -f "$STATUS_FILE.new" "$STATUS_FILE"
}
update_current_account(){
    jq '.current_account="'"$1"'"' "$STATUS_FILE" > "$STATUS_FILE.new" && mv -f "$STATUS_FILE.new" "$STATUS_FILE"
}

case "$cmd" in
    list)
        local current_account=$(jq --raw-output '.current_account' "$STATUS_FILE")
        if [ -z "$current_account" ]; then
            echo "No current account"
        else
            echo "Current account: $current_account"
        fi
        echo "Avaliable accounts:"
        jq '.accounts' "$STATUS_FILE"
        exit $?
        ;;

    save)
        [ -n "$name" ] || usage
        local current_account=$(jq --raw-output '.current_account' "$STATUS_FILE")
        if [ -n "$current_account" ] && [ "$current_account" != "$name" ]; then
            read -r "answer?Current account seems saved as $current_account, still save it as $name?[y/N]:"
            if [[ "$answer" != [yY] ]]; then
                exit 0
            fi
        fi
        local target_account="$name"
        local target_path="$STORE_DIR/$target_account"
        store "$target_account"
        update_current_account "$target_account"
        add_account "$target_account"
        echo "✅ 已保存当前登录为账号: $target_account"
        echo "   位置: $target_path"
        exit $?
        ;;

    use)
        [ -n "$name" ] || usage
        local current_account=$(jq --raw-output '.current_account' "$STATUS_FILE")
        local target_account="$name"
        if [ "$current_account" = "$target_account" ];then
            echo "Already using $current_account, do nothing"
            exit 0
        fi
        if [ -z "$current_account" ] && [ -f "$CODEX_DIR/auth.json" ]; then
            read -r "answer?Current account is not saved, continue will lose it's auth [y/N]:"
            if [[ "$answer" != [yY] ]]; then
                exit 0
            fi
        fi
        stop_codex
        [ -n "$current_account" ] && store "$current_account"
        restore "$target_account"
        update_current_account "$target_account"
        start_codex
        exit 0
        ;;
    new)
        local current_account=$(jq --raw-output '.current_account' "$STATUS_FILE")
        if [ -z "$current_account" ] && [ -f "$CODEX_DIR/auth.json" ]; then
            read -r "answer?Current account is not saved, continue will lose it's auth [y/N]:"
            if [[ "$answer" != [yY] ]]; then
                exit 0
            fi
        fi
        stop_codex
        [ -n "$current_account" ] && store "$current_account"
        rm "$CODEX_DIR/auth.json"
        rm "$CODEX_DIR/config.toml"
        update_current_account ""
        command codex login --device-auth || error "Codex not logined, please login first"
        [ -n "$name" ] && store "$name" && add_account "$name" && update_current_account "$name"
        exit 0
        ;;
    *)
        command codex "$@"
        return $?
        ;;
esac
