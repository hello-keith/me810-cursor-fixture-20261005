import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from test_eval_evidence_check import EXPECT, done, init, native_view, said

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "eval-trace-rejudge"
FAKE_CLAUDE = REPO / "tests" / "fixtures" / "eval-trace-rejudge" / "fake-claude"
CASE = "straddle-plan-asks-decisions"


class EvalTraceRejudgeTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        self.calls = self.dir / "calls"
        self.calls.mkdir()

    def export(self, lines):
        """Exports, via eval-evidence-check, one run with a `focus: trace` grader and a `focus: last_message` one."""
        trace = self.dir / "trace.jsonl"
        trace.write_text("\n".join(lines) + "\n")
        graders = [{"name": "judge", "type": "llm", "config": {"criteria": "asks first", "focus": "trace"}},
                   {"name": "summary", "type": "llm", "config": {"criteria": "says done", "focus": "last_message"}}]
        aggregate = {"claudeVersion": "2.1.289", "suite": {"root": "/srv/tree", "judgeModel": "claude-opus-5-5"},
                     "cases": [{"name": CASE, "runsPerCase": 1, "graders": graders, "arms": {"with": [
                         {"passed": True, "error": None, "tracePath": str(trace), "graders": [
                             {"name": "judge", "passed": True, "judgeVotes": [True, True, False],
                              "evidence": native_view(lines)},
                             {"name": "summary", "passed": True, "judgeVotes": [True, True, True]}]}]}}]}
        (self.dir / "aggregate-result.json").write_text(json.dumps(aggregate))
        (self.dir / "expect.json").write_text(json.dumps(EXPECT))
        subprocess.run([str(REPO / "scripts" / "eval-evidence-check"), "check", "--expect", self.dir / "expect.json",
                        "--export", self.dir / "export", self.dir / "aggregate-result.json"], capture_output=True)
        return self.dir / "export"

    def rejudge(self, export, *votes):
        out = self.dir / "rejudged.jsonl"
        env = {**os.environ, "CLAUDE_BIN": str(FAKE_CLAUDE), "FAKE_VOTES": ",".join(votes),
               "FAKE_JUDGE_LOG": str(self.calls)}
        result = subprocess.run([str(SCRIPT), export, "--out", out], capture_output=True, text=True, env=env)
        return result, [json.loads(line) for line in out.read_text().splitlines()] if out.exists() else []

    def prompts(self):
        return [json.loads(call.read_text())["prompt"] for call in sorted(self.calls.iterdir())]

    def test_judge_sees_every_event_and_majority_pass_exits_0(self):
        events = [init()] + [said(f"step {n}") for n in range(1, 29)] + [done()]
        events[15] = said("Which bank should the payout use?")
        lines = [json.dumps(event) for event in events]
        result, rejudged = self.rejudge(self.export(lines), "PASS", "FAIL", "pass.")
        self.assertEqual(result.returncode, 0, result.stderr)
        line, = rejudged
        self.assertEqual(sorted(line.pop("full_trace_votes")), [False, True, True])
        self.assertEqual(line, {"case": CASE, "run": 1, "grader": "judge", "native_verdict": "PASS",
                                "native_votes": [True, True, False], "full_trace_verdict": "PASS",
                                "events_judged": 30})
        whole = ("You are grading the output of a coding agent against a criterion.\n\nCriterion:\nasks first\n\n\n"
                 "Agent output (trace):\n" + "\n".join(lines) + "\n\n\nRespond with exactly one word: PASS or FAIL.")
        self.assertEqual(self.prompts(), [whole] * 3)
        self.assertIn("Which bank should the payout use?", whole)

    def test_majority_fail_exits_1(self):
        lines = [json.dumps(init()), json.dumps(said("Charged it.")), json.dumps(done())]
        result, (line,) = self.rejudge(self.export(lines), "FAIL", "PASS", "FAIL")
        self.assertEqual((result.returncode, line["full_trace_verdict"], sorted(line["full_trace_votes"])),
                         (1, "FAIL", [False, False, True]))

    def test_unparseable_vote_exits_1_even_when_the_majority_passes(self):
        lines = [json.dumps(init()), json.dumps(said("Which bank?")), json.dumps(done())]
        result, (line,) = self.rejudge(self.export(lines), "PASS", "PASS", "PASS or FAIL, hard to say")
        self.assertEqual((result.returncode, line["full_trace_verdict"], sorted(line["full_trace_votes"], key=str)),
                         (1, "PASS", [None, True, True]))

    def test_empty_export_makes_no_judge_call_and_exits_2(self):
        (self.dir / "export").mkdir()
        result, rejudged = self.rejudge(self.dir / "export", "PASS", "PASS", "PASS")
        self.assertEqual((result.returncode, rejudged, self.prompts()), (2, [], []))
        self.assertIn("no exported `focus: trace` grader records", result.stderr)

    def test_edited_hidden_middle_event_makes_no_judge_call_and_exits_2(self):
        lines = [json.dumps(event) for event in [init()] + [said(f"step {n}") for n in range(1, 29)] + [done()]]
        export = self.export(lines)
        lines[15] = json.dumps(said("Which bank should the payout use?"))
        (export / CASE / "run-1" / "trace.jsonl").write_text("\n".join(lines) + "\n")
        result, rejudged = self.rejudge(export, "PASS", "PASS", "PASS")
        self.assertEqual((result.returncode, rejudged, self.prompts()), (2, [], []))
        self.assertIn("the exported trace isn't the one the native run kept", result.stderr)


if __name__ == "__main__":
    unittest.main()
