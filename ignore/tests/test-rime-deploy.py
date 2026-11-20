#!/usr/bin/env python3
"""Exercise ownership-preserving updates through a local fake ADB, never a phone."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

repo = Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix="rime-deploy-test-", dir=sys.argv[2]) as directory:
    root = Path(directory)
    source, remote, binaries = root / "source", root / "remote", root / "bin"
    (source / "lua").mkdir(parents=True)
    (source / "default.yaml").write_text("new configuration\n")
    (source / "lua/quick_input.lua").write_text("new Lua\n")
    shutil.copytree(source, remote)
    for path in remote.rglob("*"):
        if path.is_file():
            path.write_text("original\n")
            path.chmod(0o660)
    originals = {path.relative_to(remote): (path.read_bytes(), path.stat())
                 for path in remote.rglob("*") if path.is_file()}
    binaries.mkdir()
    # POSIX stat formatting is supplied locally so the fake also works on macOS/root CI.
    (binaries / "stat").write_text('''#!/usr/bin/env python3
import os, sys
s = os.stat(sys.argv[-1])
print(sys.argv[2].replace('%u', '11001').replace('%g', '1078').replace('%a', format(s.st_mode & 0o7777, 'o')))
''')
    (binaries / "sha256sum").write_text('''#!/usr/bin/env python3
import hashlib, pathlib, sys
for name in sys.argv[1:]: print(hashlib.sha256(pathlib.Path(name).read_bytes()).hexdigest() + '  ' + name)
''')
    (binaries / "adb").write_text('''#!/usr/bin/env python3
import os, pathlib, subprocess, sys
args = sys.argv[1:]
if args[:1] == ['-s']: args = args[2:]
assert args[:2] == ['shell', '-T']
script = args[2]
fault = os.environ.get('FAULT_PATH')
marker = pathlib.Path(os.environ['FAULT_MARKER'])
if fault and script.startswith('cat > ') and fault in script and (not marker.exists() or os.environ.get('PERSISTENT_FAULT')):
    marker.touch()
    subprocess.run(script, shell=True, input=b'partial failed write')
    sys.exit(1)
sys.exit(subprocess.call(script, shell=True))
''')
    for path in binaries.iterdir():
        path.chmod(0o755)
    environment = dict(os.environ, PATH=str(binaries) + os.pathsep + os.environ["PATH"],
                       FAULT_MARKER=str(root / "fault"), TMPDIR=str(root))

    def run(*args, success=True, **extra):
        result = subprocess.run([str(repo / "ignore/bin/rime-deploy"), "--from-dir", str(source),
                                 "--remote-dir", str(remote), *args],
                                env=dict(environment, **extra), capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result

    def assert_original():
        for relative, (content, _) in originals.items():
            assert (remote / relative).read_bytes() == content

    assert "2 need updating" in run("--dry-run").stdout
    assert_original()
    (source / "new.lua").write_text("new file")
    assert "nothing was changed" in run(success=False).stderr
    assert_original()
    (source / "new.lua").unlink()
    (source / "user.yaml").write_text("runtime state")
    assert "runtime state" in run(success=False).stderr
    assert_original()
    (source / "user.yaml").unlink()
    run(success=False, FAULT_PATH=str(remote / "lua/quick_input.lua"))
    assert_original()  # Both an earlier success and the partial failed write were rolled back.
    run("--serial", "fixture-device")
    for relative, (_, before) in originals.items():
        path = remote / relative
        after = path.stat()
        assert path.read_bytes() == (source / relative).read_bytes()
        assert (after.st_ino, after.st_uid, after.st_gid, after.st_mode) == (
            before.st_ino, before.st_uid, before.st_gid, before.st_mode)
    assert "0 need updating" in run().stdout
    (source / "default.yaml").write_text("next configuration\n")
    (source / "lua/quick_input.lua").write_text("next Lua\n")
    failed = run(success=False, FAULT_PATH=str(remote / "lua/quick_input.lua"), PERSISTENT_FAULT="1")
    assert "Original contents saved for recovery" in failed.stderr
    recovery = next(root.glob("rime-deploy-recovery-*"))
    assert (recovery / "lua/quick_input.lua").read_text() == "new Lua\n"
    assert (recovery / "default.yaml").read_text() == "new configuration\n"
    print("Rime deployment: dry run, preflight, runtime-state exclusion, rollback and inode/ownership preservation passed")
