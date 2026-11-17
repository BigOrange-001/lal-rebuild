"""Check related-test selection and errors against an isolated Git checkout."""
import contextlib
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import run_related_tests as runner


class RelatedTestsRunnerTests(unittest.TestCase):
    def test_staged_unstaged_and_new_paths_are_selected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            def git(*args):
                subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)
            git("init", "-q")
            for name in ("staged.txt", "unstaged.txt"):
                (root / name).write_text("old", encoding="utf-8")
            git("add", ".")
            git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "initial")
            for name in ("staged.txt", "unstaged.txt", "new.txt"):
                (root / name).write_text("new", encoding="utf-8")
            git("add", "staged.txt")
            with patch.object(runner, "ROOT", root):
                self.assertEqual(runner.changed_files("HEAD"), ["new.txt", "staged.txt", "unstaged.txt"])

    def test_invalid_base_is_an_error_instead_of_a_successful_empty_run(self):
        run = subprocess.run([sys.executable, str(Path(runner.__file__)), "--base",
                              "refs/heads/related-test-missing-base", "--dry-run"],
                             capture_output=True, encoding="utf-8")
        self.assertNotEqual(run.returncode, 0)
        self.assertIn("Cannot read Git changes", run.stderr)
        self.assertNotIn("No changed files", run.stdout)

    def test_each_test_module_has_a_category(self):
        tests = set(runner.all_tests())
        covered = set().union(*(runner.expand(category["tests"], tests)
                                for category in runner.CATEGORIES.values()))
        self.assertEqual(tests - covered, set())

    def test_category_selection_includes_client_regressions(self):
        for source, test in (("client/src/stages/018_PanelChatRoom.as", "scripts/test_guild_chat_polling_client.py"),
                             ("client/src/stages/100_ItemVIPShopping.as", "scripts/test_vip_pack_rewards_client.py")):
            selected, _ = runner.select([source])
            self.assertIn(test, selected)

    def test_list_reports_uncategorized_modules(self):
        tests = runner.all_tests() + ["server/test_uncategorized_new_feature.py"]
        output = io.StringIO()
        with patch.object(sys, "argv", ["run_related_tests.py", "--list"]), \
                patch.object(runner, "all_tests", return_value=tests), \
                contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(output):
            self.assertEqual(runner.main(), 1)
        self.assertIn("server/test_uncategorized_new_feature.py", output.getvalue())
