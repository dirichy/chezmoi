#!/usr/bin/env bash

LOCKDIR="/tmp/tmux_debounce"
THRESHOLD=3

mkdir -p "$LOCKDIR"

# ✅ 用数组保存命令
cmd=("$@")

# 用字符串做 hash（仅用于标识，不用于执行）
cmd_str="$*"
hash=$(printf '%s' "$cmd_str" | md5sum | cut -d' ' -f1)

pidfile="$LOCKDIR/$hash.pid"

# kill 旧任务
if [ -f "$pidfile" ]; then
  oldpid=$(cat "$pidfile")
  if kill -0 "$oldpid" 2>/dev/null; then
    kill "$oldpid" 2>/dev/null
  fi
fi

# 启动延迟执行
(
  sleep "$THRESHOLD"

  echo "[$(date)] Exec running: ${cmd[*]}" >> /tmp/exec.log

  # ✅ 正确执行（无 eval）
  "${cmd[@]}" 2>> ~/tmux.log

) &

echo $! > "$pidfile"
