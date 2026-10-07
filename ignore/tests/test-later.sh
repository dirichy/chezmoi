#!/usr/bin/env bash
set -euo pipefail

repo_dir=${1:?usage: test-later.sh REPO_DIR TMP_DIR}
tmp_dir=${2:?usage: test-later.sh REPO_DIR TMP_DIR}
later=$repo_dir/dot_local/bin/executable_later
schedule_file=$tmp_dir/once.cron
result_file=$tmp_dir/later-result
runtime_dir=$tmp_dir/runtime
cache_dir=$tmp_dir/cache
calls_file=$tmp_dir/systemd-calls
mkdir -p "$runtime_dir" "$cache_dir"

auto_file=$tmp_dir/later-auto-created/tasks
LATER_FILE=$auto_file \
    LATER_CACHE_DIR=$tmp_dir/later-auto-created/cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" --run >/dev/null
[[ $(head -n 1 "$auto_file") == '# vim: set ft=later :' ]] || {
	printf 'not ok - later must put the Neovim modeline first\n' >&2
	exit 1
}
grep -Fq '# One-off tasks. Fields: time-range command' "$auto_file" || {
    printf 'not ok - later must create its documented task file on first run\n' >&2
    exit 1
}

assert_contains() {
    local file=$1 text=$2 description=$3
    grep -Fqx -- "$text" "$file" || {
        printf 'not ok - %s\n' "$description" >&2
        exit 1
    }
}

assert_not_contains() {
    local file=$1 text=$2 description=$3
    if grep -Fqx -- "$text" "$file"; then
        printf 'not ok - %s\n' "$description" >&2
        exit 1
    fi
}

printf '%s\n' \
    '# time-range command' \
    "2026-10-01T10:01:00-2026-10-01T10:11:00 printf '%s\\n' future >> '$result_file'" \
    "2026-10-01T09:55:00-2026-10-01T10:05:00 printf '%s\\n' due >> '$result_file'" \
    "2026-10-01T09:50:00-2026-10-01T10:00:00 printf '%s\\n' boundary >> '$result_file'" \
    "2026-10-01T09:49:00-2026-10-01T09:59:00 printf '%s\\n' expired >> '$result_file'" \
    "2026-10-01T09:55:00-2026-10-01T10:05:00 false" \
    "# [failed:1] 2026-10-01T09:55:00-2026-10-01T10:05:00 printf '%s\\n' old-failure >> '$result_file'" \
    >"$schedule_file"

set +e
output=$(LATER_FILE=$schedule_file \
    LATER_CACHE_DIR=$cache_dir \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01 10:00:00 +08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" --run)
scan_status=$?
set -e
[[ $scan_status == 1 ]] || {
    printf 'not ok - a failed task must make the scan fail\n' >&2
    exit 1
}

assert_contains "$result_file" due 'due task must execute'
assert_contains "$result_file" boundary 'task at expiry boundary must execute'
assert_not_contains "$result_file" expired 'expired task must not execute'
assert_not_contains "$result_file" future 'future task must not execute early'
assert_not_contains "$result_file" old-failure 'failed task must not execute again'
assert_contains "$schedule_file" \
    "2026-10-01T10:01:00-2026-10-01T10:11:00 printf '%s\\n' future >> '$result_file'" \
    'future task must remain scheduled'
assert_not_contains "$schedule_file" \
    "2026-10-01T09:55:00-2026-10-01T10:05:00 printf '%s\\n' due >> '$result_file'" \
    'executed task must be removed'
assert_contains "$schedule_file" \
    "# [expired] 2026-10-01T09:49:00-2026-10-01T09:59:00 printf '%s\\n' expired >> '$result_file'" \
    'expired task must be marked expired'
assert_contains "$schedule_file" \
    '# [failed:1] 2026-10-01T09:55:00-2026-10-01T10:05:00 false' \
    'failed task must be marked failed'
grep -Fq 'skipped expired task' <<<"$output" || {
    printf 'not ok - expired task must be logged\n' >&2
    exit 1
}

second_output=$(LATER_FILE=$schedule_file \
    LATER_CACHE_DIR=$cache_dir \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01 10:02:00 +08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" --run)
assert_contains "$result_file" future 'future task must execute when it becomes due'
assert_not_contains "$schedule_file" \
    "2026-10-01T10:01:00-2026-10-01T10:11:00 printf '%s\\n' future >> '$result_file'" \
    'newly executed task must be removed'
grep -Fq 'compiled schedule: 1 cached, 0 changed' <<<"$second_output" || {
    printf 'not ok - unchanged pending tasks must reuse compiled timestamps\n' >&2
    exit 1
}

next_epoch=$(TZ=Asia/Shanghai date -d '2026-10-01 10:01:00' +%s)
grep -Fq "<--on-calendar=@$next_epoch>" "$calls_file" || {
    printf 'not ok - only the nearest future wakeup must be scheduled\n' >&2
    exit 1
}

cli_file=$tmp_dir/later-cli-tasks
cli_cache=$tmp_dir/later-cli-cache
LATER_FILE=$cli_file \
    LATER_CACHE_DIR=$cli_cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    LATER_EDITOR_LINE='30-01-01T12:00+1h true' \
    EDITOR=$repo_dir/ignore/tests/mock-bin/editor \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" -e >/dev/null
listed=$(LATER_FILE=$cli_file "$later" -l)
grep -Fq '2030-01-01T12:00:00-2030-01-01T13:00:00 true' <<<"$listed" || {
    printf 'not ok - later -e and -l must edit and list the task file\n' >&2
    exit 1
}

status_output=$(LATER_FILE=$schedule_file "$later")
grep -Fq 'Failed (2):' <<<"$status_output" || {
    printf 'not ok - later without arguments must list failed tasks\n' >&2
    exit 1
}
grep -Fq 'Expired (1):' <<<"$status_output" || {
    printf 'not ok - later without arguments must list expired tasks\n' >&2
    exit 1
}

failed_task='2026-10-01T09:55:00-2026-10-01T10:05:00 false'
failed_id=$(printf '%s' "$failed_task" | sha256sum | cut -c1-8)
grep -Fq "[$failed_id] 2026-10-01T09:55:00 → 2026-10-01T10:05:00  false" <<<"$status_output" || {
    printf 'not ok - task status must show the stable task ID\n' >&2
    exit 1
}
failed_log=$(LATER_FILE=$schedule_file "$later" -j "$failed_id")
grep -Fq "task: $failed_task" <<<"$failed_log" || {
    printf 'not ok - later -j ID must show the selected task log\n' >&2
    exit 1
}
grep -Fq 'exit 1' <<<"$failed_log" || {
    printf 'not ok - task logs must record the exit status\n' >&2
    exit 1
}
log_index=$(LATER_FILE=$schedule_file "$later" -j)
grep -Fq "[$failed_id] 2026-10-01T09:55:00 → 2026-10-01T10:05:00  false" <<<"$log_index" || {
    printf 'not ok - non-interactive later -j must list searchable task lines\n' >&2
    exit 1
}

add_file=$tmp_dir/later-add-tasks
add_cache=$tmp_dir/later-add-cache
add_output=$(LATER_FILE=$add_file \
    LATER_CACHE_DIR=$add_cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" +2h+30m notify-send 'hello world')
grep -Fq "2026-10-01T12:00:00 → 2026-10-01T12:30:00  notify-send 'hello world'" <<<"$add_output" || {
    printf 'not ok - later must resolve relative time, expiry, and command arguments\n' >&2
    exit 1
}
LATER_FILE=$add_file \
    LATER_CACHE_DIR=$add_cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" +3d true >/dev/null
assert_contains "$add_file" '2026-10-04T10:00:00-2026-10-04T11:00:00 true' \
    'later must support relative days and the default expiry'

LATER_FILE=$add_file \
    LATER_CACHE_DIR=$add_cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" +2d3h+1h30m -- 'printf done > /tmp/later-output' >/dev/null
assert_contains "$add_file" '2026-10-03T13:00:00-2026-10-03T14:30:00 printf done > /tmp/later-output' \
    'later must support composite relative times and a quoted shell command'

LATER_FILE=$add_file \
    LATER_CACHE_DIR=$add_cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" 2026-10-05T09:30+2h printf -- -n >/dev/null
assert_contains "$add_file" '2026-10-05T09:30:00-2026-10-05T11:30:00 printf -- -n' \
    'later must support local absolute times and command options without a separator'

LATER_FILE=$add_file \
    LATER_CACHE_DIR=$add_cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" 09:30+20m true >/dev/null
assert_contains "$add_file" '2026-10-02T09:30:00-2026-10-02T09:50:00 true' \
    'later must resolve a time-only schedule to its next occurrence'

LATER_FILE=$add_file \
    LATER_CACHE_DIR=$add_cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" 10-03T09:30-10-03T11:00 true >/dev/null
assert_contains "$add_file" '2026-10-03T09:30:00-2026-10-03T11:00:00 true' \
    'later must resolve partial absolute start and deadline times'

set +e
timezone_output=$(LATER_FILE=$add_file \
    "$later" 2026-10-05T09:30+08:00 true 2>&1)
timezone_status=$?
set -e
[[ $timezone_status == 2 ]] || {
    printf 'not ok - later must reject absolute times with a timezone\n' >&2
    exit 1
}
grep -Fq 'absolute times must use local time without a timezone' <<<"$timezone_output" || {
    printf 'not ok - timezone rejection must explain the local-time requirement\n' >&2
    exit 1
}

invalid_file=$tmp_dir/later-invalid-tasks
printf '%s\n' 'not-a-time true' >"$invalid_file"
set +e
invalid_output=$(LATER_FILE=$invalid_file \
    LATER_CACHE_DIR=$tmp_dir/later-invalid-cache \
    LATER_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    LATER_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    LATER_CALLS=$calls_file \
    LATER_NOW='2026-10-01T10:00:00+08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" --run 2>&1)
invalid_status=$?
set -e
[[ $invalid_status == 1 ]] || {
    printf 'not ok - invalid task files must fail compilation\n' >&2
    exit 1
}
grep -Fq 'line 1 is invalid' <<<"$invalid_output" || {
    printf 'not ok - compilation errors must include the line number\n' >&2
    exit 1
}
assert_contains "$invalid_file" 'not-a-time true' \
    'failed compilation must not partially rewrite the task file'

set +e
check_output=$(printf '%s\n' \
    '09:30+20m true' \
    'not-a-time false' \
    | LATER_NOW='2026-10-01T10:00:00+08:00' \
        TZ=Asia/Shanghai \
        "$later" --check=- --json)
check_status=$?
set -e
[[ $check_status == 1 ]] || {
    printf 'not ok - later --check must fail when stdin contains an invalid task\n' >&2
    exit 1
}
grep -Fq '"line": 2' <<<"$check_output" || {
    printf 'not ok - later --check JSON must report the invalid line\n' >&2
    exit 1
}
grep -Fq 'invalid local time: not-a-time' <<<"$check_output" || {
    printf 'not ok - later --check JSON must use the scheduler parser error\n' >&2
    exit 1
}

printf 'ok - later executes due tasks and marks expired or failed tasks\n'
