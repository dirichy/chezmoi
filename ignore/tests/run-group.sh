#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=ignore/tests/groups/common.sh
source "$(dirname -- "$0")/groups/common.sh"
group=${1:?missing group}
case "$group" in
    runner)
        python3 "$tests_dir/test-runner.py" "$repo_dir" "$tmp_dir"
        ;;
    installers|install-entry|maintenance|downloads|rime-tiger|rime-deploy)
        python3 "$tests_dir/test-$group.py" "$repo_dir" "$tmp_dir"
        ;;
    rime-native|rime-android)
        prepare_source
        if [[ $group == rime-android ]]; then
            python3 "$tests_dir/test-rime-radical.py" "$repo_dir" "$source_dir" "$tmp_dir" android
        else
            python3 "$tests_dir/test-rime-radical.py" "$repo_dir" "$source_dir" "$tmp_dir"
        fi
        ;;
    *)
        # Each group is sourced into the common fixture environment.
        # shellcheck disable=SC1090
        source "$tests_dir/groups/$group.sh"
        ;;
esac
