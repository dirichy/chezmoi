#!/usr/bin/env bash
set -euo pipefail

repo_dir=${1:?usage: test-once-cron.sh REPO_DIR TMP_DIR}
tmp_dir=${2:?usage: test-once-cron.sh REPO_DIR TMP_DIR}
once_cron=$repo_dir/dot_local/bin/executable_once-cron
schedule_file=$tmp_dir/once.cron
result_file=$tmp_dir/once-cron-result
runtime_dir=$tmp_dir/runtime
calls_file=$tmp_dir/systemd-calls
mkdir -p "$runtime_dir"

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
    '# status date time expiry command' \
    "pending 2026-10-01 10:01 10m printf '%s\\n' future >> '$result_file'" \
    "pending 2026-10-01 09:55 10m printf '%s\\n' due >> '$result_file'" \
    "pending 2026-10-01 09:50 10m printf '%s\\n' boundary >> '$result_file'" \
    "pending 2026-10-01 09:49 10m printf '%s\\n' expired >> '$result_file'" \
    "pending 2026-10-01 09:55 10m false" \
    "failed 2026-10-01 09:55 10m printf '%s\\n' old-failure >> '$result_file'" \
    "pending 2026-10-01 invalid 10m printf '%s\\n' invalid >> '$result_file'" \
    >"$schedule_file"

set +e
output=$(ONCE_CRON_FILE=$schedule_file \
    ONCE_CRON_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    ONCE_CRON_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    ONCE_CRON_CALLS=$calls_file \
    ONCE_CRON_NOW='2026-10-01 10:00:00 +08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$once_cron")
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
    "pending 2026-10-01 10:01 10m printf '%s\\n' future >> '$result_file'" \
    'future task must remain scheduled'
assert_contains "$schedule_file" \
    "pending 2026-10-01 invalid 10m printf '%s\\n' invalid >> '$result_file'" \
    'invalid task must remain for correction'
assert_not_contains "$schedule_file" \
    "pending 2026-10-01 09:55 10m printf '%s\\n' due >> '$result_file'" \
    'executed task must be removed'
assert_contains "$schedule_file" \
    "expired 2026-10-01 09:49 10m printf '%s\\n' expired >> '$result_file'" \
    'expired task must be marked expired'
assert_contains "$schedule_file" \
    'failed 2026-10-01 09:55 10m false' \
    'failed task must be marked failed'
grep -Fq 'skipped expired task' <<<"$output" || {
    printf 'not ok - expired task must be logged\n' >&2
    exit 1
}

ONCE_CRON_FILE=$schedule_file \
    ONCE_CRON_SYSTEMCTL=$repo_dir/ignore/tests/mock-bin/systemctl \
    ONCE_CRON_SYSTEMD_RUN=$repo_dir/ignore/tests/mock-bin/systemd-run \
    ONCE_CRON_CALLS=$calls_file \
    ONCE_CRON_NOW='2026-10-01 10:02:00 +08:00' \
    TZ=Asia/Shanghai \
    XDG_RUNTIME_DIR=$runtime_dir \
    "$once_cron" >/dev/null
assert_contains "$result_file" future 'future task must execute when it becomes due'
assert_not_contains "$schedule_file" \
    "pending 2026-10-01 10:01 10m printf '%s\\n' future >> '$result_file'" \
    'newly executed task must be removed'

next_epoch=$(TZ=Asia/Shanghai date -d '2026-10-01 10:01:00' +%s)
grep -Fq "<--on-calendar=@$next_epoch>" "$calls_file" || {
    printf 'not ok - only the nearest future wakeup must be scheduled\n' >&2
    exit 1
}

printf 'ok - once-cron executes due tasks and marks expired or failed tasks\n'
