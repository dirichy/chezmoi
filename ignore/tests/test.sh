#!/usr/bin/env bash
set -euo pipefail
tests_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
exec python3 "$tests_dir/run.py" "$@"
