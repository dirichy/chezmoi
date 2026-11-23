#!/usr/bin/env python3
"""Run test groups whose inputs differ from their last successful run."""

import argparse
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile
import time

from dependencies import DEPENDENCIES, SOURCES

TESTS = Path(__file__).resolve().parent
REPO = TESTS.parent.parent
INFRA = ["ignore/tests/test.sh", "ignore/tests/run.py", "ignore/tests/run-group.sh",
         "ignore/tests/dependencies.py", "ignore/tests/groups/common.sh"]
TOOLS = ("bash", "python3", "chezmoi", "git", "zsh", "lua", "luac", "shellcheck",
         "cc", "pkg-config", "plutil", "tar")


def matches(path, patterns):
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def repository_files(repo):
    # Includes staged, unstaged, untracked and deleted tracked paths, without reading .git internals.
    result = subprocess.check_output(
        ["git", "-C", str(repo), "ls-files", "--cached", "--others", "--exclude-standard", "-z"])
    return sorted(set(os.fsdecode(path) for path in result.split(b"\0") if path))


def environment_key():
    tools = {}
    for name in TOOLS:
        path = shutil.which(name)
        if path:
            stat = Path(path).stat()
            tools[name] = [path, stat.st_size, stat.st_mtime_ns]
        else:
            tools[name] = None
    # Native checks can become available after installing librime/librime-lua.
    if tools["pkg-config"]:
        result = subprocess.run(["pkg-config", "--modversion", "rime"],
                                capture_output=True, text=True)
        tools["rime"] = [result.returncode, result.stdout]
        libdir = subprocess.run(["pkg-config", "--variable=libdir", "rime"],
                                capture_output=True, text=True).stdout.strip()
        plugin = Path(libdir) / "rime-plugins/librime-lua.so"
        if plugin.is_file():
            stat = plugin.stat()
            tools["rime-lua"] = [stat.st_size, stat.st_mtime_ns]
    return json.dumps([platform.platform(), sys.version, str(REPO), tools], sort_keys=True)


def dependencies_for(name):
    script = f"ignore/tests/groups/{name}.sh"
    return INFRA + DEPENDENCIES[name] + ([script] if (REPO / script).is_file() else [])


def inputs_for(name, repo, paths):
    patterns = dependencies_for(name)
    inputs = {}
    for relative in paths:
        path = repo / relative
        if matches(relative, patterns):
            if path.is_symlink():
                value = "symlink:" + os.readlink(path)
            elif path.is_file():
                value = hashlib.sha256(path.read_bytes()).hexdigest() + f":{path.stat().st_mode & 0o777:o}"
            else:
                continue
            inputs[relative] = value
        elif name == "profiles" and matches(relative, SOURCES) and (path.is_file() or path.is_symlink()):
            inputs[relative] = "present"
    return inputs


def fingerprint(inputs, environment):
    return hashlib.sha256((environment + json.dumps(inputs, sort_keys=True)).encode()).hexdigest()


def changed_inputs(before, after):
    return sorted(path for path in before.keys() | after.keys() if before.get(path) != after.get(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("groups", nargs="*", help="explicit groups (always rerun)")
    parser.add_argument("--all", action="store_true", help="force the full default suite")
    parser.add_argument("--list", action="store_true", help="show group dependency globs without running")
    parser.add_argument("--dry-run", action="store_true", help="show selection and reasons without running")
    parser.add_argument("--cache-dir", type=Path, default=TESTS / ".cache",
                        help="successful-run records (default: ignore/tests/.cache)")
    args = parser.parse_args()
    unknown = set(args.groups) - DEPENDENCIES.keys()
    if unknown:
        parser.error("unknown groups: " + ", ".join(sorted(unknown)))
    if args.list:
        for name in args.groups or DEPENDENCIES:
            print(f"{name}: " + ", ".join(dependencies_for(name)))
            if name == "profiles":
                print("  also depends on deployed source file names: " + ", ".join(SOURCES))
        return 0
    paths = repository_files(REPO)
    environment = environment_key()
    selected = []
    cached = 0
    for name in args.groups or DEPENDENCIES:
        inputs = inputs_for(name, REPO, paths)
        digest = fingerprint(inputs, environment)
        record = args.cache_dir / f"{name}.json"
        try:
            previous = json.loads(record.read_text())
        except (OSError, ValueError):
            previous = {}
        if not isinstance(previous, dict) or not isinstance(previous.get("inputs", {}), dict):
            previous = {}
        if not args.all and not args.groups and previous.get("fingerprint") == digest:
            cached += 1
            print(f"cached - {name}", flush=True)
            continue
        changes = changed_inputs(previous.get("inputs", {}), inputs)
        reason = "forced" if args.all or args.groups else (
            "no successful baseline" if not previous else ", ".join(changes[:4]) or "tool/platform changed")
        if len(changes) > 4 and previous and not (args.all or args.groups):
            reason += f" (+{len(changes) - 4} files)"
        print(f"run - {name}: {reason}", flush=True)
        selected.append((name, inputs, digest, record))
    if args.dry_run:
        print(f"{len(selected)} selected, {cached} cached")
        return 0
    failures = []
    for name, inputs, digest, record in selected:
        start = time.monotonic()
        skipped = False
        with tempfile.TemporaryDirectory(prefix=f"dotfiles-test-{name}-") as directory:
            env = dict(os.environ, PYTHONPYCACHEPREFIX=str(Path(directory) / "pycache"))
            process = subprocess.Popen(["bash", str(TESTS / "run-group.sh"), name, directory],
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
            for line in process.stdout:
                print(line, end="", flush=True)
                # Optional checks stay pending. Platform-inapplicable checks need no retry.
                if line.startswith("# skip -") and "macOS only" not in line:
                    skipped = True
            status = process.wait()
        if status:
            record.unlink(missing_ok=True)
            failures.append(name)
            print(f"FAIL - {name} ({time.monotonic() - start:.1f}s)", flush=True)
        else:
            # Do not certify inputs edited while the test was running.
            current = inputs_for(name, REPO, repository_files(REPO))
            if current == inputs and not skipped:
                record.parent.mkdir(parents=True, exist_ok=True)
                with tempfile.NamedTemporaryFile(mode="w", dir=record.parent, delete=False) as stream:
                    json.dump({"fingerprint": digest, "inputs": inputs}, stream, sort_keys=True)
                    temporary = stream.name
                os.replace(temporary, record)
            else:
                record.unlink(missing_ok=True)
            print(f"ok - {name} ({time.monotonic() - start:.1f}s)" +
                  ("; optional checks skipped, not cached" if skipped else ""), flush=True)
    print(f"{len(selected) - len(failures)} passed, {len(failures)} failed, {cached} cached")
    return bool(failures)


if __name__ == "__main__":
    sys.exit(main())
