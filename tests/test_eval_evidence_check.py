import json
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "eval-evidence-check"
ROOT = "/srv/tree"
SKILLS = ["straddle:straddle-plan", "verify"]
EXPECT = {"claude_code_version": "2.1.289", "model": "claude-opus-5-5", "judge_model": "claude-opus-5-5",
          "apiKeySource": "none", "plugins": ["straddle@inline"], "skills": SKILLS}


def run(*args):
    return subprocess.run([str(SCRIPT), *map(str, args)], capture_output=True, text=True)


def init(**fields):
    return {"type": "system", "subtype": "init", "claude_code_version": "2.1.289", "model": "claude-opus-5-5",
            "apiKeySource": "none", "plugins": [{"name": "straddle", "source": "straddle@inline", "path": ROOT}],
            "skills": SKILLS, **fields}


def said(text):
    return {"type": "assistant", "message": {"model": "claude-opus-5-5", "content": [{"type": "text", "text": text}]}}


def done(denials=()):
    return {"type": "result", "subtype": "success", "permission_denials": list(denials)}


def native_view(lines):
    """The runner's `focus: trace` judge input for a trace under 100,000 chars."""
    if len(lines) <= 24:
        return "\n".join(lines)
    return "\n".join(lines[:12]) + f"\n[…{len(lines) - 24} messages elided…]\n" + "\n".join(lines[-12:])


class EvalEvidenceCheckTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        self.expect = self.dir / "expect.json"
        self.expect.write_text(json.dumps(EXPECT))

    def write(self, events, case="straddle-plan-asks-decisions", passed=True, evidence=None, name="a"):
        """A one-run aggregate whose `judge` grader has focus: trace; evidence defaults to the native judge view."""
        lines = events if isinstance(events, list) and all(isinstance(e, str) for e in events) else None
        lines = lines or [json.dumps(event) for event in events]
        trace = self.dir / name / "trace.jsonl"
        trace.parent.mkdir(parents=True)
        trace.write_text("\n".join(lines) + "\n")
        aggregate = {"claudeVersion": "2.1.289", "suite": {"root": ROOT, "judgeModel": "claude-opus-5-5"},
                     "cases": [{"name": case, "dir": f"evals/{case}",
                                "graders": [{"name": "judge", "type": "llm",
                                             "config": {"criteria": "asks first", "focus": "trace"}}],
                                "arms": {"with": [{"passed": passed, "error": None, "tracePath": str(trace),
                                                   "graders": [{"name": "judge", "passed": passed,
                                                                "judgeVotes": [True, True, False],
                                                                "evidence": native_view(lines) if evidence is None
                                                                else evidence}]}]}}]}
        path = self.dir / name / "results" / "aggregate-result.json"
        path.parent.mkdir()
        path.write_text(json.dumps(aggregate))
        return path, trace

    def check(self, *args):
        result = run("check", "--expect", self.expect, *args)
        return result, [json.loads(line) for line in result.stdout.splitlines()]

    def test_matching_short_run_keeps_its_fail_and_passes_integrity_only(self):
        path, _ = self.write([init(), said("Which bank?"), done()], passed=False)
        pinned = run("identity", path)
        self.assertEqual(json.loads(pinned.stdout), EXPECT)
        result, (line,) = self.check(path)
        self.assertEqual((result.returncode, line["verdict"], line["evidence_integrity"], line["reasons"]),
                         (0, "FAIL", "complete", []))
        self.assertIn("Not a candidate PASS, semantic acceptance or confinement proof.", result.stderr)

    def test_runtime_drift_and_unavailable_identity_are_gaps(self):
        drifted = init(claude_code_version="2.1.286", skills=SKILLS + ["schedule"])
        del drifted["apiKeySource"]
        path, _ = self.write([drifted, said("ok"), done()])
        result, (line,) = self.check(path)
        self.assertEqual((result.returncode, line["verdict"], line["evidence_integrity"]), (1, "PASS", "incomplete"))
        self.assertEqual(line["reasons"], ['drift:claude_code_version expected "2.1.289" got "2.1.286"',
                                           "identity-unavailable:apiKeySource",
                                           'drift:skills extra ["schedule"] missing []'])

    def test_missing_trace_fails_closed(self):
        path, trace = self.write([init(), done()])
        trace.unlink()
        result, (line,) = self.check(path)
        self.assertEqual((result.returncode, line["verdict"], line["reasons"]), (1, "PASS", [f"trace-missing: {trace}"]))

    def test_bad_middle_event_hidden_from_judge_is_flagged_and_exported_in_full(self):
        events = [init()] + [said(f"step {n}") for n in range(1, 29)] + [done()]
        events[15] = {"type": "assistant", "message": {"model": "claude-opus-5-5", "content": [
            {"type": "tool_use", "name": "Write", "input": {"file_path": ".env", "content": "KEY=live"}}]}}
        path, trace = self.write(events)
        result, (line,) = self.check(path, "--export", self.dir / "export")
        self.assertEqual((result.returncode, line["verdict"], line["reasons"]),
                         (1, "PASS", ["trace-elided:judge judge saw 24 of 30 events"]))
        run_dir = self.dir / "export" / "straddle-plan-asks-decisions" / "run-1"
        self.assertEqual((run_dir / "trace.jsonl").read_bytes(), trace.read_bytes())
        record = json.loads((run_dir / "judge.json").read_text())
        self.assertEqual((record["passed"], record["judge_votes"], record["trace_events"], ".env" in record["judge_saw"]),
                         (True, [True, True, False], 30, False))

    def test_unreadable_middle_line_fails_closed(self):
        lines = [json.dumps(init())] + [json.dumps(said(f"step {n}")) for n in range(1, 29)] + [json.dumps(done())]
        lines[14] = '{"type": "assistant", "message": '
        path, _ = self.write(lines)
        result, (line,) = self.check(path)
        self.assertEqual((result.returncode, line["reasons"]), (1, ["trace-unreadable: line 15"]))

    def test_judge_input_that_is_not_this_trace_is_a_gap(self):
        path, _ = self.write([init(), said("ok"), done()], evidence="a different trace")
        result, (line,) = self.check(path)
        self.assertEqual(line["reasons"], ["evidence-mismatch:judge retained judge input isn't this trace's native view"])

    def test_permission_denials_are_reported_beside_the_verdict(self):
        denial = {"tool_name": "Glob", "tool_use_id": "t1", "tool_input": {"pattern": "plugin.json", "path": ROOT}}
        path, _ = self.write([init(), said("ok"), done([denial])])
        result, (line,) = self.check(path)
        self.assertEqual((result.returncode, line["denials"], line["reasons"]), (0, [denial], []))
        path, _ = self.write([init(), said("ok")], name="b")
        result, (line,) = self.check(path)
        self.assertEqual((line["denials"], line["reasons"]), (None, ["denials-unavailable"]))

    def test_case_plugin_counts_as_drift_unless_pinned_for_that_case(self):
        fixture = {"name": "straddle-eval-env-fixture", "source": "straddle-eval-env-fixture@inline",
                   "path": f"{ROOT}/evals/straddle-plan-asks-decisions/env-fixture"}
        path, _ = self.write([init(plugins=init()["plugins"] + [fixture]), said("ok"), done()])
        _, (line,) = self.check(path)
        self.assertEqual(line["reasons"], ['drift:plugins extra ["straddle-eval-env-fixture@inline"] missing []'])
        self.expect.write_text(json.dumps({**EXPECT, "case_plugins": {
            "straddle-plan-asks-decisions": ["straddle-eval-env-fixture@inline"]}}))
        result, (line,) = self.check(path)
        self.assertEqual((result.returncode, line["case_plugins_excluded"]), (0, ["straddle-eval-env-fixture@inline"]))

    def test_refuses_what_it_cannot_check_or_would_overwrite(self):
        (self.dir / "empty").mkdir()
        self.assertEqual(run("check", "--expect", self.expect, self.dir / "empty").returncode, 2)
        self.expect.write_text(json.dumps({**EXPECT, "apiKeySource": None}))
        path, _ = self.write([init(), done()])
        result = run("check", "--expect", self.expect, path)
        self.assertEqual((result.returncode, result.stderr),
                         (2, f"eval-evidence-check: {self.expect}: expected identity has no value for apiKeySource\n"))
        self.expect.write_text(json.dumps(EXPECT))
        twice, _ = self.write([init(), done()], name="b")
        export = self.dir / "export"
        result, _ = self.check(path, twice, "--export", export)
        self.assertEqual(result.returncode, 2)
        self.assertIn("already exported (a case/run appears twice), not overwriting", result.stderr)
        self.assertEqual(run("check", "--expect", self.expect, "--export", export, path).returncode, 2)
        unsafe, _ = self.write([init(), done()], case="../escape", name="c")
        result, _ = self.check(unsafe, "--export", self.dir / "fresh")
        self.assertEqual((result.returncode, (self.dir / "escape").exists()), (2, False))
        self.assertIn('["../escape"]: not a safe file name', result.stderr)


if __name__ == "__main__":
    unittest.main()
