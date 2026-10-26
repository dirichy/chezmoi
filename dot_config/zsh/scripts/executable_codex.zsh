#!/bin/zsh

set -euo pipefail
umask 077

cmd=${1:-}
name=${2:-}

if [[ -z "$cmd" ]]; then
  command codex
  exit $?
fi

CODEX_DIR=${CODEX_HOME:-"$HOME/.codex"}
STORE_DIR="$HOME/.codex-accounts"
STATUS_FILE="$STORE_DIR/status.json"

# Account status format:
# {
#   "current_account": "account_name",
#   "accounts": ["account1", "account2"]
# }

mkdir -p "$STORE_DIR" "$CODEX_DIR"

if [[ ! -f "$STATUS_FILE" ]]; then
  cat >"$STATUS_FILE" <<'JSON'
{
  "current_account": "",
  "accounts": []
}
JSON
fi

error() {
  print -u2 -- "Error: $1"
  exit "${2:-1}"
}

usage() {
  cat <<'EOF'
Usage:
  codex save/store <name>   Save the current account as <name>
  codex use  <name>         Switch to a saved account
  codex new  [name]         Log in to a new account, optionally saving it
  codex list/status         List all saved accounts
  codex help                Show help information

All other commands are forwarded to Codex CLI.
EOF
  exit "${1:-1}"
}

confirm() {
  local answer
  read -r "answer?$1 [y/N]: " || return 1
  [[ "$answer" == [yY] ]]
}

validate_name() {
  local account="$1"

  [[ "$account" =~ '^[a-zA-Z0-9]+$' ]] ||
    error "Invalid account name: $account (only letters and digits are allowed)"
}

# Atomically copy a file to avoid partial writes.
safe_copy() {
  local source="$1"
  local destination="$2"
  local tmp="${destination}.tmp.$$"

  [[ -f "$source" ]] || error "Source file not found: $source"

  cp "$source" "$tmp" || error "Failed to copy: $source"
  mv -f "$tmp" "$destination" || error "Failed to write: $destination"
}

# Atomically update account status.
update_status() {
  local filter="$1"
  shift

  local tmp="${STATUS_FILE}.tmp.$$"

  if ! jq "$@" "$filter" "$STATUS_FILE" >"$tmp"; then
    rm -f "$tmp"
    error "Failed to update account status."
  fi

  mv -f "$tmp" "$STATUS_FILE"
}

current_account() {
  jq -r '.current_account' "$STATUS_FILE"
}

add_account() {
  local account="$1"

  update_status '
        .accounts |= (
            if index($account) == null
            then . + [$account]
            else .
            end
        )
    ' --arg account "$account"
}

update_current_account() {
  local account="$1"

  update_status \
    '.current_account = $account' \
    --arg account "$account"
}

store() {
  local account="$1"
  validate_name "$account"

  local target_path="$STORE_DIR/$account"
  local auth_file="$CODEX_DIR/auth.json"

  [[ -f "$auth_file" ]] || error "No active Codex authentication found."

  mkdir -p "$target_path"

  safe_copy "$auth_file" "$target_path/auth.json"

  if [[ -f "$CODEX_DIR/config.toml" ]]; then
    safe_copy "$CODEX_DIR/config.toml" "$target_path/config.toml"
  fi
}

restore() {
  local account="$1"
  validate_name "$account"

  local target_path="$STORE_DIR/$account"

  [[ -f "$target_path/auth.json" ]] ||
    error "Saved account not found: $account"

  safe_copy "$target_path/auth.json" "$CODEX_DIR/auth.json"

  if [[ -f "$target_path/config.toml" ]]; then
    safe_copy "$target_path/config.toml" "$CODEX_DIR/config.toml"
  fi
}

stop_codex() {
  timeout 5s codex app-server daemon stop ||
    error "Failed to stop Codex daemon. Close all Codex clients first."
}

start_codex() {
  timeout 5s codex app-server daemon start ||
    error "Failed to start Codex daemon."
}

codex_usage() {
  emulate -L zsh
  setopt localoptions no_monitor

  local line response
  local init='{"id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-status","title":"Codex Status","version":"1.0"}}}'

  coproc codex app-server 2>/dev/null

  print -p -- "$init"

  while read -p -r line; do
    if [[ $(jq -r '.id // empty' <<<"$line") == 1 ]]; then
      break
    fi
  done

  print -p -- '{"method":"initialized"}'
  print -p -- '{"id":2,"method":"account/rateLimits/read"}'

  while read -p -r line; do
    if [[ $(jq -r '.id // empty' <<<"$line") == 2 ]]; then
      response=$line
      break
    fi
  done

  if [[ -z $response ]]; then
    print -u2 "Failed to read Codex status"
    return 1
  fi

  if jq -e '.error' >/dev/null <<<"$response"; then
    jq -r '.error.message' <<<"$response" >&2
    return 1
  fi

  print
  printf '  \033[1;36mCurrent Account Codex Usage\033[0m\n\n'

  local i
  jq -r '
    def limit_label($fallback):
      if .windowDurationMins == 300 then
        "5-hour limit"
      elif .windowDurationMins == 10080 then
        "Weekly limit"
      elif (.windowDurationMins // 0) > 0 then
        ((.windowDurationMins / 60) | floor | tostring) + "-hour limit"
      else
        $fallback
      end;

    .result.rateLimits
    | [
        [(.primary | limit_label("5-hour limit")), .primary],
        [(.secondary | limit_label("Weekly limit")), .secondary]
      ][]
    | select(.[1] != null)
    | [
        .[0],
        (100 - .[1].usedPercent | floor),
        (.[1].resetsAt // 0)
      ]
    | @tsv
' <<<"$response" |
    while IFS=$'\t' read -r label remaining reset; do
      local width=30
      local filled=$((remaining * width / 100))
      local empty=$((width - filled))
      local bar=""

      for ((i = 0; i < filled; i++)); do
        bar+="█"
      done

      for ((i = 0; i < empty; i++)); do
        bar+="░"
      done

      local color=32
      ((remaining < 50)) && color=33
      ((remaining < 20)) && color=31

      printf '  \033[1m%s\033[0m\n' "$label"
      printf "  \033[%sm%s\033[0m  %d%% remaining\n" \
        "$color" "$bar" "$remaining"

      if ((reset > 0)); then
        printf '  \033[90mResets %s\033[0m\n' \
          "$(date -d "@$reset" '+%b %d, %H:%M')"
      fi

      printf '\n'
    done
}
case "$cmd" in
list | status)
  current=$(current_account)

  if [[ -z "$current" ]]; then
    echo "Current account: none"
  else
    echo "Current account: $current"
  fi

  echo "Saved accounts:"
  jq -r '.accounts[] | "  - \(.)"' "$STATUS_FILE"
  codex_usage
  ;;

save | store)
  [[ -n "$name" ]] || usage
  validate_name "$name"

  current=$(current_account)

  if [[ -n "$current" && "$current" != "$name" ]]; then
    confirm "Current account is '$current'. Save it as '$name' instead?" ||
      exit 0
  fi

  if [[ "$current" != "$name" &&
    -f "$STORE_DIR/$name/auth.json" ]]; then
    confirm "Account '$name' already exists. Overwrite its credentials?" ||
      exit 0
  fi

  store "$name"
  add_account "$name"
  update_current_account "$name"

  echo "Account saved successfully: $name"
  echo "Location: $STORE_DIR/$name"
  ;;

use | restore)
  [[ -n "$name" ]] || usage
  validate_name "$name"

  current=$(current_account)

  if [[ "$current" == "$name" ]]; then
    echo "Already using account: $name"
    exit 0
  fi

  [[ -f "$STORE_DIR/$name/auth.json" ]] ||
    error "Account '$name' does not exist."

  if [[ -z "$current" && -f "$CODEX_DIR/auth.json" ]]; then
    confirm "The current account is not saved. Continue and discard its credentials?" ||
      exit 0
  fi

  stop_codex

  if [[ -n "$current" ]]; then
    store "$current"
  fi

  restore "$name"
  update_current_account "$name"

  start_codex

  echo "Switched to account: $name"
  ;;

new)
  if [[ -n "$name" ]]; then
    validate_name "$name"

    if [[ -f "$STORE_DIR/$name/auth.json" ]]; then
      error "Account '$name' already exists. Choose another name."
    fi
  fi

  current=$(current_account)

  if [[ -z "$current" && -f "$CODEX_DIR/auth.json" ]]; then
    confirm "The current account is not saved. Continue and discard its credentials?" ||
      exit 0
  fi

  stop_codex

  if [[ -n "$current" ]]; then
    store "$current"
  fi

  rm -f "$CODEX_DIR/auth.json"
  update_current_account ""

  echo "Starting Codex device authentication..."

  if ! command codex login --device-auth; then
    error "Codex login failed. Run 'codex new' to retry."
  fi

  if [[ -n "$name" ]]; then
    store "$name"
    add_account "$name"
    update_current_account "$name"
    echo "New account saved: $name"
  else
    echo "Login successful. Use 'codex save <name>' to save this account."
  fi

  start_codex
  ;;

help)
  command codex help
  echo
  echo "Additional account management commands:"
  usage 0
  ;;

*)
  command codex "$@"
  ;;
esac
