import json
import shutil
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
checker = SourceFileLoader("check_eval_fixtures", str(REPO / "scripts" / "check-eval-fixtures")).load_module()

DOCS_SEARCH = {"name": "search-documentation", "description": "Search the documentation.",
               "inputSchema": {"type": "object", "properties": {"question": {"type": "string"}}}}
EXECUTE = {"name": "execute-request", "description": "Execute an HTTP request.",
           "inputSchema": {"type": "object", "properties": {"path": {"type": "string"}}}}


class CheckEvalFixturesTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        self.evals = self.root / "evals"

    def case(self, name, tools="[Read, Skill]", mocks=(), listing=None):
        case = self.evals / name
        (case / "graders").mkdir(parents=True)
        (case / "prompt.md").write_text(f"---\nallowed_tools: {tools}\n---\n\nHello.\n")
        server = case / "mocks" / "straddle-docs"
        for tool in mocks:
            server.mkdir(parents=True, exist_ok=True)
            (server / f"{tool}.md").write_text("canned answer\n")
        if listing is not None:
            (server / "_tools.json").write_text(json.dumps(listing))
        return server

    def problems(self):
        return checker.check_mocks(self.evals) + checker.check_write_grants(self.evals)

    def test_repository_fixtures_pass(self):
        self.assertEqual(checker.main(["--root", str(REPO)]), 0)

    def test_mocked_tool_without_listing_is_reported(self):
        self.case("straddle-get-started-a", mocks=["search-documentation"])
        self.assertEqual(len(self.problems()), 1)
        self.assertIn("no _tools.json", self.problems()[0])

    def test_listing_must_match_mocked_tools_and_carry_metadata(self):
        self.case("straddle-get-started-a", mocks=["search-documentation"], listing={"tools": [DOCS_SEARCH]})
        self.assertEqual(self.problems(), [])
        self.case("straddle-get-started-b", mocks=["search-documentation"],
                  listing={"tools": [{"name": "search-documentation"}, EXECUTE]})
        self.assertEqual(sorted(p.split(": ", 1)[1] for p in self.problems()), [
            "lists execute-request, which this directory doesn't mock",
            "search-documentation has no description",
            "search-documentation has no object inputSchema",
        ])

    def test_runner_shape_and_jsonrpc_envelope(self):
        self.case("straddle-get-started-a", mocks=["search-documentation"],
                  listing={"jsonrpc": "2.0", "id": 2, "result": {"tools": [DOCS_SEARCH]}})
        self.case("straddle-get-started-b", mocks=["search-documentation"], listing=[DOCS_SEARCH])
        self.assertEqual(len(self.problems()), 1)
        self.assertIn("expected a saved tools/list response", self.problems()[0])

    def test_report_writing_skill_needs_write(self):
        self.case("straddle-integrate-no-write", tools="[Read, Skill, Bash]")
        self.case("straddle-setup-write", tools="[Read, Skill, Write]")
        self.case("straddle-best-practices-answer", tools="[Read, Skill]")
        self.assertEqual(self.problems(), [
            "evals/straddle-integrate-no-write/prompt.md: allowed_tools has no Write, but the skill writes its report"])

    def test_write_keeps_only_mocked_tools_and_refuses_incomplete_capture(self):
        server = self.case("straddle-get-started-a", mocks=["search-documentation"])
        capture = self.root / "capture.json"
        capture.write_text(json.dumps({"result": {"tools": [EXECUTE, DOCS_SEARCH]}}))
        checker.write_listings(self.evals, "straddle-docs", capture)
        self.assertEqual(json.loads((server / "_tools.json").read_text()), {"tools": [DOCS_SEARCH]})
        capture.write_text(json.dumps({"tools": [EXECUTE]}))
        with self.assertRaises(SystemExit):
            checker.write_listings(self.evals, "straddle-docs", capture)
        self.assertEqual(json.loads((server / "_tools.json").read_text()), {"tools": [DOCS_SEARCH]})


if __name__ == "__main__":
    unittest.main()
