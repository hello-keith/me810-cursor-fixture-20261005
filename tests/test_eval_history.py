import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "eval-history"
FIXTURES = REPO / "tests" / "fixtures" / "eval-history"


def run(*args):
    return subprocess.run([str(SCRIPT), *args], capture_output=True, text=True)


class EvalHistoryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.commit = subprocess.run(["git", "-C", str(REPO), "rev-parse", "HEAD"], capture_output=True, text=True,
                                    check=True).stdout.strip()
        cls.short = cls.commit[:7]
        with tempfile.TemporaryDirectory() as out:
            subprocess.run([str(REPO / "scripts" / "kit-release"), "build", "--commit", cls.commit, "--out", out],
                           capture_output=True, check=True)
            cls.zip_sha = hashlib.sha256(next(Path(out).glob("*.zip")).read_bytes()).hexdigest()

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.history = Path(temp.name) / "history"

    def record(self, results):
        return run("--history", str(self.history), "record", str(FIXTURES / results), "--commit", "HEAD")

    def line(self, pass_id, date, case, runs, passes, errors, failing):
        return {"pass": pass_id, "case": case, "skills_commit": self.commit, "plugin_sha256": self.zip_sha,
                "date": date, "model": "claude-opus-5-5", "runs": runs, "passes": passes, "errors": errors,
                "failing_graders": failing}

    def test_record_and_compare(self):
        a, b = f"2026-09-30T2255Z-{self.short}", f"2026-10-02T0930Z-{self.short}"
        result = self.record("pass-a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f"{self.history / a}.jsonl: 4 cases, 2 pass\n")
        self.assertEqual(self.record("pass-b").returncode, 0)

        def lines(pass_id):
            return [json.loads(line) for line in (self.history / f"{pass_id}.jsonl").read_text().splitlines()]

        self.assertEqual(lines(a), [
            self.line(a, "2026-09-30", "straddle-plan-asks-decisions", 3, 0, 0,
                      ["open-questions-logged", "round-format"]),
            self.line(a, "2026-09-30", "straddle-plan-interview-dont-know", 3, 0, 1, ["assumption-recorded"]),
            self.line(a, "2026-09-30", "straddle-plan-interview-resume", 3, 3, 0, []),
            self.line(a, "2026-09-30", "straddle-plan-python-retired-sdk", 3, 3, 0, []),
        ])
        # Pass B is one with-without aggregate; its failing no-plugin arm must not count.
        self.assertEqual(lines(b), [
            self.line(b, "2026-10-02", "straddle-integrate-ambiguous-retry", 3, 3, 0, []),
            self.line(b, "2026-10-02", "straddle-plan-asks-decisions", 3, 3, 0, []),
            self.line(b, "2026-10-02", "straddle-plan-interview-dont-know", 3, 1, 0, ["explains-assumption"]),
            self.line(b, "2026-10-02", "straddle-plan-interview-resume", 3, 2, 0, ["read-plan"]),
        ])

        result = run("--history", str(self.history), "compare", "2026-09-30", "2026-10-02")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, (
            "new    straddle-integrate-ambiguous-retry  - -> 3/3\n"
            "fixed  straddle-plan-asks-decisions  0/3 [open-questions-logged round-format] -> 3/3\n"
            "fail   straddle-plan-interview-dont-know  0/3 [assumption-recorded] errors=1 -> 1/3 [explains-assumption]\n"
            "broke  straddle-plan-interview-resume  3/3 -> 2/3 [read-plan]\n"
            "gone   straddle-plan-python-retired-sdk  3/3 -> -\n"
            f"{a}: 2/4 cases pass\n"
            f"{b}: 2/4 cases pass\n"
            "0 pass, 1 fail, 1 fixed, 1 broke, 1 new, 1 gone\n"))

        result = run("--history", str(self.history), "compare", self.short, b)
        self.assertEqual(result.returncode, 1)
        self.assertIn(f"{self.short}: matches 2 passes", result.stderr)

    def test_refuses_partial_pass(self):
        with tempfile.TemporaryDirectory() as results:
            aggregate = json.loads((FIXTURES / "pass-b" / "aggregate-result.json").read_text())
            aggregate["partial"] = True
            (Path(results) / "aggregate-result.json").write_text(json.dumps(aggregate))
            result = run("--history", str(self.history), "record", results, "--commit", "HEAD")
        self.assertEqual(result.returncode, 1)
        self.assertIn("partial run", result.stderr)
        self.assertFalse(self.history.exists())


if __name__ == "__main__":
    unittest.main()
