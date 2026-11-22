#!/usr/bin/env python3
"""Exercise the standalone installer without real network, package installs or user state."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

repo, temporary = map(Path, sys.argv[1:])
root = temporary / "install-entry"
root.mkdir()
bin_dir = root / "bin"
bin_dir.mkdir()
home = root / "home"
home.mkdir()
source = root / "checkout"
log = root / "events"
log.write_text("")
standalone = root / "install.sh"
shutil.copy2(repo / "install.sh", standalone)
python = sys.executable

# A restricted PATH makes chezmoi genuinely unavailable on the first run.
for name in ("bash", "sh", "git", "env", "uname", "mktemp", "rm", "dirname", "mkdir", "cp", "chmod", "cat"):
    (bin_dir / name).symlink_to(shutil.which(name))


def executable(path, code):
    path.write_text(f"#!{python}\n" + code)
    path.chmod(0o755)


fake_cm = root / "fake-chezmoi"
executable(fake_cm, '''
import json, os, sys, shutil
from pathlib import Path
args = sys.argv[1:]
options = {}
while args and args[0] in ('--source','--config','--destination','--cache','--persistent-state'):
    options[args[0]] = args[1]
    args = args[2:]
command = args[0]
source = Path(options.get('--source', os.environ['TEST_SOURCE']))
destination = Path(options.get('--destination', os.environ['HOME']))
with open(os.environ['TEST_LOG'], 'a') as stream:
    stream.write(json.dumps({'command': command, 'args': args[1:],
                            'proxy': os.environ.get('https_proxy'),
                            'git_proxy': os.environ.get('GIT_CONFIG_VALUE_0'),
                            'skip_services': os.environ.get('DOTFILES_SKIP_SERVICES'),
                            'skip_apps': os.environ.get('DOTFILES_SKIP_APP_INIT'),
                            'skip_hooks': os.environ.get('DOTFILES_SKIP_HOOKS'),
                            'services_yes': os.environ.get('DOTFILES_SERVICES_YES'),
                            'config': options.get('--config')}) + '\\n')
if command == 'source-path':
    print(source)
elif command == 'init':
    source.mkdir(parents=True, exist_ok=True)
    (source / '.chezmoi.toml.tmpl').write_text('fixture')
    (source / '.initialized').touch()
    helper = source / 'ignore/bin/dotfiles-packages'
    helper.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(os.environ['TEST_PACKAGE_HELPER'], helper)
elif command == 'execute-template':
    template = args[1]
    if 'hasKey . "install"' in template:
        print('true' if (source / '.initialized').exists() else 'false')
    elif '.chezmoi.destDir' in template:
        print(destination)
    elif '.install.profile' in template:
        print('custom')
    elif '.name' in template:
        print('Fixture')
    elif '.email' in template:
        print('fixture@example.invalid')
    elif 'install-common' in template:
        print('#!/bin/sh')
        print('printf "packages\\\\n" >> "$TEST_STEPS"')
        print('if [ -f "$TEST_SOURCE/.packages-ready" ]; then exit 0; fi')
        print('if [ "${TEST_PACKAGE_EXIT:-0}" != 0 ]; then exit "$TEST_PACKAGE_EXIT"; fi')
        print('touch "$TEST_SOURCE/.packages-ready"')
    else:
        print('false')
elif command == 'diff':
    if not (source / '.applied').exists():
        print('configuration changed')
elif command == 'apply':
    assert '--keep-going' in args and '--exclude' not in args
    if os.environ.get('TEST_APPLY_EXIT', '0') != '0':
        sys.exit(int(os.environ['TEST_APPLY_EXIT']))
    (source / '.applied').touch()
else:
    raise AssertionError(args)
''')

executable(bin_dir / "curl", '''
import json,os,sys
from pathlib import Path
assert 'https://get.chezmoi.io' in sys.argv
with open(os.environ['TEST_LOG'], 'a') as stream:
    stream.write(json.dumps({'command':'bootstrap-download','proxy':os.environ.get('https_proxy')})+'\\n')
output=Path(sys.argv[sys.argv.index('-o')+1])
output.write_text('#!/bin/sh\\nmkdir -p "$2"\\ncp "$TEST_CM" "$2/chezmoi"\\nchmod +x "$2/chezmoi"\\n')
''')
(bin_dir / "touch").symlink_to(shutil.which("touch"))
env = {key: value for key, value in os.environ.items()
       if not key.startswith("GIT_CONFIG_") and key.lower() not in {"http_proxy", "https_proxy", "all_proxy", "no_proxy"}}
steps = root / "steps"
steps.write_text("")
# Homebrew may already provide chezmoi/curl on macOS. Keep bootstrap simulation
# isolated even when the installer adds standard Homebrew locations to PATH.
shell_environment = root / "bash-env"
shell_environment.write_text('''
command() {
    if [[ ${1:-} == -v && ${2:-} == chezmoi && ! -x $HOME/.local/bin/chezmoi ]]; then
        return 1
    fi
    builtin command "$@"
}
curl() { "$TEST_BIN/curl" "$@"; }
''')
env.update(HOME=str(home), PATH=str(bin_dir), TEST_SOURCE=str(source), TEST_LOG=str(log),
           TEST_CM=str(fake_cm), TEST_STEPS=str(steps), BOOTSTRAP_PROXY="http://proxy.example:7890",
           BASH_ENV=str(shell_environment), TEST_BIN=str(bin_dir),
           TEST_PACKAGE_HELPER=str(repo / "ignore/bin/dotfiles-packages"))
command = [shutil.which("bash"), str(standalone), "--source", str(source), "--destination", str(home),
           "--config", str(root / "config.toml"), "--cache", str(root / "cache"), "--state", str(root / "state"),
           "--yes", "--skip-plugins", "--skip-services", "--skip-hooks", "--skip-identity"]


def run(extra=None):
    result = subprocess.run(command, env=dict(env, **(extra or {})), capture_output=True, text=True)
    events = [json.loads(line) for line in log.read_text().splitlines()]
    return result, events


result, events = run()
assert result.returncode == 0, result
assert (home / ".local/bin/chezmoi").is_file()
assert (source / ".applied").exists() and (source / ".packages-ready").exists()
assert [item['command'] for item in events].count("bootstrap-download") == 1
assert [item['command'] for item in events].count("init") == 1
assert all(item["proxy"] == env["BOOTSTRAP_PROXY"] for item in events)
assert all(item.get("git_proxy") == env["BOOTSTRAP_PROXY"] for item in events if item["command"] != "bootstrap-download")
assert events.index(next(item for item in events if item["command"] == "init")) < events.index(next(item for item in events if item["command"] == "apply"))

log.write_text("")
result, events = run()
assert result.returncode == 0, result
assert not any(item["command"] in ("bootstrap-download", "init") for item in events), events
assert any(item["command"] == "apply" for item in events), events
assert all(item[field] == "1" for item in events for field in ("skip_services", "skip_apps", "skip_hooks", "services_yes"))

# Package failure must not prevent the independent apply step, but the installer reports failure.
(source / ".packages-ready").unlink()
(source / ".applied").unlink()
log.write_text("")
result, events = run({"TEST_PACKAGE_EXIT": "7"})
assert result.returncode == 1 and "Install missing dependencies" in result.stderr, result
assert any(item["command"] == "apply" for item in events), events
assert not (source / ".packages-ready").exists()

(source / ".applied").unlink()
result, _ = run({"TEST_APPLY_EXIT": "9"})
assert result.returncode == 1 and "Apply configuration and maintenance" in result.stderr, result

# Enrollment is manual, precedes the regular apply, and can fail without suppressing apply.
identity_helper = source / "ignore/bin/dotfiles-identity"
identity_helper.write_text('''#!/bin/sh
printf 'identity\\n' >> "$TEST_STEPS"
exit "${TEST_IDENTITY_EXIT:-0}"
''')
log.write_text("")
steps.write_text("")
enrolled = subprocess.run([argument for argument in command if argument != "--skip-identity"],
                          env=dict(env, TEST_IDENTITY_EXIT="8"), capture_output=True, text=True)
assert enrolled.returncode == 1 and "Prepare device keys and password store" in enrolled.stderr, enrolled
assert steps.read_text().splitlines() == ["packages", "identity", "packages"], steps.read_text()
assert any(json.loads(line)["command"] == "apply" for line in log.read_text().splitlines())

# Invalid proxy input is rejected without exposing the URL or contacting a server.
bad = dict(env, BOOTSTRAP_PROXY="socks5h://private.example:1080")
result = subprocess.run(command, env=bad, capture_output=True, text=True)
assert result.returncode == 2 and "private.example" not in result.stderr, result
print("Install entry: bootstrap before chezmoi/init, inherited proxy, idempotent retries and failure summary passed")
