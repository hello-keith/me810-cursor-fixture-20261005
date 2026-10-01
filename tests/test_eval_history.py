import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "eval-history"
FIXTURES = REPO / "tests" / "fixtures" / "eval-history"
PASS_B = json.loads((FIXTURES / "pass-b" / "aggregate-result.json").read_text())


def run(*args):
    return subprocess.run([str(SCRIPT), *args], capture_output=True, text=True)


def aggregate(**suite):
    return {**PASS_B, "suite": {**PASS_B["suite"], **suite}}


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
        self.results = Path(temp.name) / "results"

    def record(self, results, *args):
        return run("--history", str(self.history), "record", str(results), "--commit", "HEAD", *args)

    def write_results(self, **aggregates):
        """Write each aggregate (a dict, or raw text) to results/<name>/aggregate-result.json."""
        for name, result in aggregates.items():
            path = self.results / name / "aggregate-result.json"
            path.parent.mkdir(parents=True)
            path.write_text(result if isinstance(result, str) else json.dumps(result))
        return [str(self.results / name / "aggregate-result.json") for name in aggregates]

    def assert_refused(self, result, message):
        self.assertEqual((result.returncode, result.stderr), (1, f"eval-history: {message}\n"))
        self.assertFalse(self.history.exists())

    def line(self, pass_id, date, claude, case, runs, passes, errors, failing):
        return {"pass": pass_id, "case": case, "skills_commit": self.commit, "plugin_sha256": self.zip_sha,
                "date": date, "model": "claude-opus-5-5", "judge_model": "claude-opus-5-5", "claude_version": claude,
                "runs": runs, "passes": passes, "errors": errors, "failing_graders": failing}

    def lines(self, pass_id):
        return [json.loads(line) for line in (self.history / f"{pass_id}.jsonl").read_text().splitlines()]

    def test_record_and_compare(self):
        a, b = f"2026-09-30T225525.376Z-{self.short}", f"2026-10-02T093000.000Z-{self.short}"
        result = self.record(FIXTURES / "pass-a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f"{self.history / a}.jsonl: 4 cases, 2 pass\n")
        self.assertEqual(self.record(FIXTURES / "pass-b").returncode, 0)

        self.assertEqual(self.lines(a), [
            self.line(a, "2026-09-30", "2.1.286", "straddle-plan-asks-decisions", 3, 0, 0,
                      ["open-questions-logged", "round-format"]),
            self.line(a, "2026-09-30", "2.1.286", "straddle-plan-interview-dont-know", 3, 0, 1,
                      ["assumption-recorded"]),
            self.line(a, "2026-09-30", "2.1.286", "straddle-plan-interview-resume", 3, 3, 0, []),
            self.line(a, "2026-09-30", "2.1.286", "straddle-plan-python-retired-sdk", 3, 3, 0, []),
        ])
        # Pass B is one with-without aggregate; its failing no-plugin arm must not count.
        self.assertEqual(self.lines(b), [
            self.line(b, "2026-10-02", "2.1.280", "straddle-integrate-ambiguous-retry", 3, 3, 0, []),
            self.line(b, "2026-10-02", "2.1.280", "straddle-plan-asks-decisions", 3, 3, 0, []),
            self.line(b, "2026-10-02", "2.1.280", "straddle-plan-interview-dont-know", 3, 1, 0,
                      ["explains-assumption"]),
            self.line(b, "2026-10-02", "2.1.280", "straddle-plan-interview-resume", 3, 2, 0, ["read-plan"]),
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

    def test_passes_started_in_the_same_minute_keep_their_own_files(self):
        # Real targeted lanes on form-dev started 24 ms apart.
        dont_know, resume = (FIXTURES / "pass-a" / f"straddle-plan-interview-{case}" for case in ("dont-know", "resume"))
        first = self.history / f"2026-10-01T001820.442Z-{self.short}.jsonl"
        second = self.history / f"2026-10-01T001820.466Z-{self.short}.jsonl"
        self.assertEqual(self.record(dont_know).stdout, f"{first}: 1 cases, 0 pass\n")
        self.assertEqual(self.record(resume).stdout, f"{second}: 1 cases, 1 pass\n")
        self.assertEqual([line["case"] for line in map(json.loads, first.read_text().splitlines())],
                         ["straddle-plan-interview-dont-know"])
        recorded = first.read_text()
        result = self.record(dont_know)
        self.assertEqual((result.returncode, result.stdout), (0, f"{first}: 1 cases, 0 pass\n"))

        # Both lanes together start at the first lane's time but hold different results.
        self.write_results(**{path.name: json.loads((path / "aggregate-result.json").read_text())
                              for path in (dont_know, resume)})
        result = self.record(self.results)
        self.assertEqual((result.returncode, result.stderr), (1, (
            f"eval-history: {first}: already holds different results for pass {first.stem}, not overwriting it\n")))
        self.assertEqual(first.read_text(), recorded)

    def test_refuses_partial_pass(self):
        (path,) = self.write_results(a={**PASS_B, "partial": True, "partialReason": "cost_ceiling"})
        self.assert_refused(self.record(self.results), f"{path}: partial run (cost_ceiling), rerun it before recording")

    def test_refuses_mixed_models(self):
        for key, field, other in (("model", "modelOverride", "claude-sonnet-4-5"),
                                  ("judge model", "judgeModel", "claude-sonnet-4-5")):
            with self.subTest(field):
                self.setUp()
                a, b = self.write_results(a=aggregate(), b=aggregate(**{field: other}))
                self.assert_refused(self.record(self.results), (
                    f"{self.results}: one pass has one {key}, found claude-opus-5-5 in {a}; {other} in {b}"))

    def test_refuses_a_case_twice(self):
        a, b = self.write_results(a=PASS_B, b=PASS_B)
        self.assert_refused(self.record(self.results), (
            f"straddle-plan-asks-decisions appears twice in {self.results}: {a} and {b}"))

    def test_refuses_unreadable_aggregate(self):
        text = json.dumps(PASS_B)
        for name, broken, error in (("truncated", text[:200], "JSONDecodeError"),
                                    ("no cases", json.dumps({key: value for key, value in PASS_B.items() if key != "cases"}),
                                     "KeyError: 'cases'")):
            with self.subTest(name):
                self.setUp()
                (path,) = self.write_results(a=broken)
                result = self.record(self.results)
                self.assertEqual(result.returncode, 1)
                self.assertTrue(result.stderr.startswith(
                    f"eval-history: {path}: can't read this aggregate result ({error}"), result.stderr)
                self.assertFalse(self.history.exists())

    def test_hashes_the_commit_given_not_head(self):
        with tempfile.TemporaryDirectory() as clone:
            git = ["git", "-C", clone, "-c", "user.email=t@example.com", "-c", "user.name=t"]
            subprocess.run(["git", "clone", "-q", "--shared", str(REPO), clone], capture_output=True, check=True)
            subprocess.run([*git, "checkout", "-q", "--detach", self.commit], capture_output=True, check=True)
            with open(Path(clone) / "README.md", "a") as readme:
                readme.write("A plugin change after the pass.\n")
            subprocess.run([*git, "commit", "-qam", "Change the plugin"], capture_output=True, check=True)
            result = run("--history", str(self.history), "record", str(FIXTURES / "pass-b"), "--root", clone,
                         "--commit", self.commit)
        self.assertEqual(result.returncode, 0, result.stderr)
        (line, *_) = self.lines(f"2026-10-02T093000.000Z-{self.short}")
        self.assertEqual((line["skills_commit"], line["plugin_sha256"]), (self.commit, self.zip_sha))


if __name__ == "__main__":
    unittest.main()
