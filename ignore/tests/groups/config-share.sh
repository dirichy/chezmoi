#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
python3 "$tests_dir/test-config-share-server.py" \
    "$repo_dir/dot_local/libexec/executable_config-share-server"
pass 'config sharing server always allows loopback and filters other clients by CIDR'
