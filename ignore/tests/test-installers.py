#!/usr/bin/env python3
"""Exercise rendered installers with failing package managers, without installing anything."""

import os
from pathlib import Path
import shutil
import subprocess
import sys

repo, temporary = map(Path, sys.argv[1:])
chezmoi = shutil.which("chezmoi")
assert chezmoi, "chezmoi is required"
root = temporary / "installers"
root.mkdir()
bin_dir = root / "bin"
bin_dir.mkdir()
home = root / "home"
home.mkdir()
log = root / "calls"


def mock(name, body):
    target = bin_dir / name
    target.write_text("#!/bin/sh\n" + body + "\n")
    target.chmod(0o755)


mock("pacman", "exit 1")
mock("install-mock", 'echo "$*" >> "$INSTALL_TEST_LOG"; exit 1')
mock("brew", '''case "$1" in
shellenv) exit 0 ;;
list) exit 1 ;;
install) echo "$*" >> "$INSTALL_TEST_LOG"; exit 1 ;;
*) exit 99 ;;
esac''')
mock("xcode-select", "exit 0")
mock("curl", 'echo "curl $*" >> "$INSTALL_TEST_LOG"; exit 99')
for name in ("sudo", "systemctl", "luarocks"):
    mock(name, 'echo "unexpected mutation $0 $*" >> "$INSTALL_TEST_LOG"; exit 99')
mock("npm", 'echo "npm $*" >> "$INSTALL_TEST_LOG"; exit 0')
mock("uv", 'echo "uv $*" >> "$INSTALL_TEST_LOG"; exit 0')
env = dict(os.environ, PATH=f"{bin_dir}:/usr/bin:/bin", HOME=str(home),
           XDG_CONFIG_HOME=str(home / ".config"), XDG_CACHE_HOME=str(home / ".cache"),
           INSTALL_TEST_LOG=str(log), INSTALL_PROFILE="custom", INSTALL_MODULES="core,shell,proxy",
           INSTALL_COMMAND="install-mock", INSTALL_ADMIN="false", SKIP_SERVICES="1",
           SKIP_LUAROCKS="1")

for platform in ("linux", "macos"):
    shell = "bash"
    if not shutil.which(shell):
        print(f"# skip - {platform} installer behavior requires {shell}")
        continue
    shell = shutil.which(shell)
    runtime_env = dict(env, PATH=str(bin_dir))
    for phase in ("manual",):
        rendered = root / f"{platform}-{phase}.sh"
        command = [chezmoi, "--source", str(repo), "--destination", str(home),
                   "--config", str(repo / f"ignore/tests/fixtures/{platform}-desktop.toml"),
                   "--cache", str(root / "cache"), "--persistent-state", str(root / "state"),
                   "--refresh-externals=never", "execute-template", '{{ includeTemplate "install-common" (dict "config" . "platform" "' + platform + '") }}']
        check_command = command[:-1] + [command[-1].replace('"platform"', '"checkOnly" true "platform"')]
        checked = root / f"{platform}-check.sh"
        checked.write_text(subprocess.check_output(check_command, text=True, env=env))
        log.write_text("")
        checked_result = subprocess.run([shell, str(checked)],
                                        env=dict(runtime_env, INSTALL_MODULES="core,shell,system,proxy" if platform == "linux" else "core,shell,proxy",
                                                 INSTALL_ADMIN="true", SKIP_SERVICES="0", SKIP_LUAROCKS="0"),
                                        capture_output=True, text=True)
        assert checked_result.returncode == 0, checked_result
        assert "Warning: missing dependencies:" in checked_result.stderr, checked_result
        assert not log.read_text(), log.read_text()
        rendered.write_text(subprocess.check_output(command, text=True, env=env))
        subprocess.run([shell, "-n", str(rendered)], check=True)
        if shutil.which("shellcheck"):
            subprocess.run(["shellcheck", str(rendered)], check=True)
        log.write_text("")
        result = subprocess.run([shell, str(rendered)], env=runtime_env, capture_output=True, text=True)
        assert result.returncode == 1, result
        assert "Package installation failures:" in result.stderr, result.stderr
        calls = log.read_text().splitlines()
        assert len(calls) >= 2, calls
        assert any("gopass" in call for call in calls), calls
        assert any("neovim" in call for call in calls), calls
        assert any("mihomo" in call for call in calls), calls
        # Profiles and explicit module lists share dispatch on both platforms.
        log.write_text("")
        profiled = subprocess.run([shell, str(rendered)],
                                  env=dict(runtime_env, INSTALL_PROFILE="desktop", INSTALL_MODULES=""),
                                  capture_output=True, text=True)
        assert profiled.returncode == 1, profiled
        assert "mihomo" in log.read_text(), log.read_text()
        log.write_text("")
        selected = subprocess.run([shell, str(rendered)],
                                  env=dict(runtime_env, INSTALL_MODULES=" shell, font-and-im proxy "),
                                  capture_output=True, text=True)
        assert selected.returncode == 1, selected
        calls = log.read_text()
        assert "gopass" not in calls, calls
        assert "mihomo" in calls and "neovim" in calls, calls
        assert ("android-tools" if platform == "linux" else "--cask android-platform-tools") in calls, calls
        assert "python" in calls, calls
        if platform == "macos":
            mock("xcode-select", "exit 1")
            unavailable = subprocess.run([shell, str(rendered)], env=runtime_env,
                                         capture_output=True, text=True)
            assert unavailable.returncode == 1, unavailable
            assert "Package installation failures:" in unavailable.stderr, unavailable.stderr
            mock("xcode-select", "exit 0")
        # A skip profile must never call the package manager, even with module overrides.
        log.write_text("")
        skipped = subprocess.run([shell, str(rendered)], env=dict(runtime_env, INSTALL_PROFILE="skip"),
                                 capture_output=True, text=True)
        assert skipped.returncode == 0 and not log.read_text(), skipped
        # Existing packages make the entire phase succeed.
        if platform == "linux":
            mock("pacman", "exit 0")
        else:
            mock("brew", 'case "$1" in shellenv|list) exit 0 ;; *) exit 99 ;; esac')
        successful = subprocess.run([shell, str(rendered)], env=runtime_env, capture_output=True, text=True)
        assert successful.returncode == 0, successful
        assert "Package installation failures" not in successful.stderr, successful.stderr
        if platform == "linux":
            mock("pacman", "exit 1")
        else:
            mock("brew", '''case "$1" in
shellenv) exit 0 ;;
list) exit 1 ;;
install) echo "$*" >> "$INSTALL_TEST_LOG"; exit 1 ;;
*) exit 99 ;;
esac''')

# Arch's default installer bootstraps a missing paru, but check-only apply never does.
if os.geteuid() != 0:
    for name in ("mktemp", "rm", "mkdir", "chmod"):
        target = bin_dir / name
        if not target.exists():
            target.symlink_to(shutil.which(name))
    mock("pacman", 'if [ "$1" = -S ]; then echo "pacman $*" >> "$INSTALL_TEST_LOG"; exit 0; fi; exit 1')
    mock("sudo", 'echo "sudo $*" >> "$INSTALL_TEST_LOG"; case "$1" in --preserve-env=*) shift ;; esac; "$@"')
    mock("git", 'echo "git $*" >> "$INSTALL_TEST_LOG"; for last do :; done; mkdir -p "$last"')
    mock("makepkg", '''echo "makepkg $*" >> "$INSTALL_TEST_LOG"
printf '#!/bin/sh\\necho "paru $*" >> "$INSTALL_TEST_LOG"\\nexit 1\\n' > "$INSTALL_TEST_BIN/paru"
chmod +x "$INSTALL_TEST_BIN/paru"''')
    paru_env = dict(env, PATH=str(bin_dir), INSTALL_COMMAND="paru -S --needed --noconfirm --skipreview",
                    INSTALL_ADMIN="true", INSTALL_MODULES="core", INSTALL_TEST_BIN=str(bin_dir),
                    BOOTSTRAP_PROXY="http://proxy.example:7890")
    log.write_text("")
    readonly = subprocess.run([shutil.which("bash"), str(root / "linux-check.sh")], env=paru_env,
                              capture_output=True, text=True)
    assert readonly.returncode == 0 and not log.read_text(), readonly
    assert "package manager: paru" in readonly.stderr, readonly.stderr
    installed = subprocess.run([shutil.which("bash"), str(root / "linux-manual.sh")], env=paru_env,
                               capture_output=True, text=True)
    assert installed.returncode == 1, installed
    calls = log.read_text().splitlines()
    assert calls[0].startswith("sudo --preserve-env="), calls
    assert "base-devel git rust" in calls[0], calls
    assert next(i for i, call in enumerate(calls) if call.startswith("git clone")) < next(i for i, call in enumerate(calls) if call.startswith("makepkg")), calls
    assert next(i for i, call in enumerate(calls) if call.startswith("makepkg")) < next(i for i, call in enumerate(calls) if call.startswith("paru")), calls
    log.write_text("")
    subprocess.run([shutil.which("bash"), str(root / "linux-manual.sh")], env=paru_env,
                   capture_output=True, text=True)
    assert not any(call.startswith(("sudo", "git", "makepkg")) for call in log.read_text().splitlines())
    print("Paru bootstrap: build before packages, inherited proxy, existing paru skipped, daily checks read-only")
