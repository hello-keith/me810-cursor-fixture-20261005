import re
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
CASES = (
    "straddle-best-practices-fifo-receiver-typescript",
    "straddle-best-practices-webhook-receiver-python",
    "straddle-best-practices-polling-consumer-go",
)


class ReceiverCLIGuardTest(unittest.TestCase):
    def test_only_executed_network_commands_fail_the_guard(self):
        for case in CASES:
            with self.subTest(case=case), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                subprocess.run(["bash", str(REPO / "evals" / case / "scaffold.sh")],
                               cwd=root, check=True, capture_output=True, text=True)
                grader = (REPO / "evals" / case / "graders" / "no-doctor-before-prerequisites.md").read_text()
                pattern = re.compile(re.search(r"^pattern: '(.*)'$", grader, re.M).group(1), re.M)
                target = re.search(r"^target: \{ source: file, path: ([^}]+) \}$", grader, re.M).group(1)
                calls = root / target
                safe = "\n".join((
                    "./bin/straddle --version # straddle doctor was not run",
                    "printf '%s\\n' 'straddle doctor was not run'",
                    "cat <<'REPORT'\nstraddle doctor was not run\nREPORT",
                    "./bin/straddle doctor --help",
                ))
                result = subprocess.run(["bash", "-c", safe], cwd=root, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(calls.read_text(), "")
                self.assertIsNone(pattern.search(calls.read_text()))
                for command, expected in (
                    ("./bin/straddle doctor --agent", "doctor --agent\n"),
                    ("./bin/straddle --agent doctor", "doctor\n"),
                    ("printf 'local check\\n'\n./bin/straddle doctor", "doctor\n"),
                    ("./bin/straddle accounts list", "accounts list\n"),
                ):
                    with self.subTest(command=command):
                        calls.write_text("")
                        result = subprocess.run(["bash", "-c", command], cwd=root,
                                                capture_output=True, text=True)
                        self.assertEqual(result.returncode, 97)
                        self.assertEqual(calls.read_text(), expected)
                        self.assertIsNotNone(pattern.search(calls.read_text()))
                status = subprocess.run(["git", "status", "--porcelain"], cwd=root,
                                        capture_output=True, text=True, check=True)
                self.assertEqual(status.stdout, "")
