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
    '# date time expiry command' \
    "2026-10-01 10:01 10m printf '%s\\n' future >> '$result_file'" \
    "2026-10-01 09:55 10m printf '%s\\n' due >> '$result_file'" \
    "2026-10-01 09:50 10m printf '%s\\n' boundary >> '$result_file'" \
    "2026-10-01 09:49 10m printf '%s\\n' expired >> '$result_file'" \
    "2026-10-01 09:55 10m false" \
    "# [failed:1] 2026-10-01 09:55 10m printf '%s\\n' old-failure >> '$result_file'" \
    "2026-10-01 invalid 10m printf '%s\\n' invalid >> '$result_file'" \
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
    "$later")
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
    "2026-10-01 10:01 10m printf '%s\\n' future >> '$result_file'" \
    'future task must remain scheduled'
assert_contains "$schedule_file" \
    "2026-10-01 invalid 10m printf '%s\\n' invalid >> '$result_file'" \
    'invalid task must remain for correction'
assert_not_contains "$schedule_file" \
    "2026-10-01 09:55 10m printf '%s\\n' due >> '$result_file'" \
    'executed task must be removed'
assert_contains "$schedule_file" \
    "# [expired] 2026-10-01 09:49 10m printf '%s\\n' expired >> '$result_file'" \
    'expired task must be marked expired'
assert_contains "$schedule_file" \
    '# [failed:1] 2026-10-01 09:55 10m false' \
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
    "$later")
assert_contains "$result_file" future 'future task must execute when it becomes due'
assert_not_contains "$schedule_file" \
    "2026-10-01 10:01 10m printf '%s\\n' future >> '$result_file'" \
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
    LATER_EDITOR_LINE='2030-01-01 12:00 1h true' \
    EDITOR=$repo_dir/ignore/tests/mock-bin/editor \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$later" -e >/dev/null
listed=$(LATER_FILE=$cli_file "$later" -l)
grep -Fq '2030-01-01 12:00 1h true' <<<"$listed" || {
    printf 'not ok - later -e and -l must edit and list the task file\n' >&2
    exit 1
}

printf 'ok - later executes due tasks and marks expired or failed tasks\n'
