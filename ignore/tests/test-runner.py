#!/usr/bin/env python3
"""Exercise incremental scheduling in a disposable Git repository with fake groups."""

import fnmatch
import os
import runpy
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="test-runner-", dir=sys.argv[2])
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        self.tests = self.repo / "ignore/tests"
        self.tests.mkdir(parents=True)
        shutil.copy2(Path(sys.argv[1]) / "ignore/tests/run.py", self.tests)
        (self.tests / "dependencies.py").write_text(
            'SOURCES = ["dot_*"]\nDEPENDENCIES = {"alpha": ["dot_alpha*"], "beta": ["dot_beta*"], '
            '"profiles": [".chezmoiignore"]}\n')
        (self.tests / "run-group.sh").write_text(
            '#!/bin/bash\necho "executed $1"\n'
            'if [[ ${FAKE_FAIL:-} == "$1" ]]; then exit 1; fi\n'
            'if [[ ${FAKE_SKIP:-} == "$1" ]]; then echo "# skip - missing fixture tool"; fi\n')
        (self.repo / "dot_alpha").write_text("a")
        (self.repo / "dot_beta").write_text("b")
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        subprocess.run(["git", "-C", str(self.repo), "add", "."], check=True)

    def run_tests(self, *args, expected=0, **environment):
        result = subprocess.run([sys.executable, str(self.tests / "run.py"), *args],
                                env=dict(os.environ, **environment), capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result.stdout

    def test_first_run_and_unchanged(self):
        self.assertIn("3 passed", self.run_tests())
        self.assertIn("0 passed, 0 failed, 3 cached", self.run_tests())

    def test_content_changes_do_not_invalidate_other_groups(self):
        self.run_tests()
        (self.repo / "dot_alpha").write_text("edited without staging")
        output = self.run_tests()
        self.assertIn("executed alpha", output)
        self.assertNotIn("executed beta", output)
        self.assertNotIn("executed profiles", output)

    def test_add_delete_rename_and_mode(self):
        self.run_tests()
        original = self.repo / "dot_alpha"
        original.rename(self.repo / "dot_alpha_new")
        output = self.run_tests()
        self.assertIn("executed alpha", output)
        self.assertIn("executed profiles", output)
        (self.repo / "dot_alpha_new").unlink()
        self.assertIn("executed alpha", self.run_tests())
        (self.repo / "dot_beta").chmod(0o755)
        self.assertIn("executed beta", self.run_tests())

    def test_failed_group_does_not_replace_success(self):
        self.run_tests()
        self.run_tests("alpha", FAKE_FAIL="alpha", expected=1)
        self.assertFalse((self.tests / ".cache/alpha.json").exists())
        self.assertIn("executed alpha", self.run_tests())

    def test_skipped_checks_remain_pending(self):
        self.run_tests("alpha", FAKE_SKIP="alpha")
        self.assertFalse((self.tests / ".cache/alpha.json").exists())
        self.assertIn("executed alpha", self.run_tests())

    def test_force_dry_run_and_invalid_group(self):
        self.run_tests()
        self.assertIn("3 selected", self.run_tests("--all", "--dry-run"))
        self.assertIn("executed beta", self.run_tests("beta"))
        self.run_tests("typo", expected=2)

    def test_symlink_target_changes(self):
        link = self.repo / "dot_alpha_link"
        link.symlink_to("first")
        self.run_tests()
        link.unlink()
        link.symlink_to("second")
        self.assertIn("executed alpha", self.run_tests())

    def test_real_dependency_boundaries(self):
        dependencies = runpy.run_path(str(Path(sys.argv[1]) / "ignore/tests/dependencies.py"))["DEPENDENCIES"]

        def affected(path):
            return {name for name, patterns in dependencies.items()
                    if any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)}

        self.assertEqual(affected("dot_config/nvim/lua/plugins/lsp.lua"), {"maintenance", "render"})
        self.assertEqual(affected("dot_config/nvim/lua/plugins/keymap.lua"), {"maintenance", "render"})
        self.assertEqual(affected("ignore/bin/rime-deploy"), {"rime-deploy", "render"})
        self.assertEqual(affected("README.md"), set())
        self.assertEqual(affected(".chezmoitemplates/surfingkeys/scripts/test.js"), {"render"})
        self.assertNotIn("rime-native", affected(".chezmoitemplates/install-common"))
        self.assertIn("installers", affected(".chezmoitemplates/install-common"))
        self.assertIn("rime-config", affected("dot_config/fcitx5/conf/private_rime.conf.tmpl"))
        self.assertIn("rime-native", affected("ignore/tests/fixtures/rime-ice/input-check.c"))

    def test_corrupt_cache_and_runner_change(self):
        self.run_tests()
        (self.tests / ".cache/alpha.json").write_text("invalid JSON")
        self.assertIn("executed alpha", self.run_tests())
        runner = self.tests / "run.py"
        runner.write_text(runner.read_text() + "\n# modified runner\n")
        self.assertIn("3 passed", self.run_tests())


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
