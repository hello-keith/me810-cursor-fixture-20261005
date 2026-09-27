import http.server
import json
import shutil
import subprocess
import sys
import tempfile
import threading
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "validate-package"
FIXTURES = REPO / "tests" / "fixtures" / "policy"
validator = SourceFileLoader("validate_package", str(SCRIPT)).load_module()

PACKAGE_FILES = ("plugin.json", "mcp.json", ".claude-plugin", ".codex-plugin", ".cursor-plugin", "assets")
KNOWN_GATES = [
    (".codex-plugin/plugin.json", "codex", "interface.privacyPolicyURL is required"),
    (".codex-plugin/plugin.json", "codex", "interface.termsOfServiceURL is required"),
] + [(f"skills/{skill}", "skill", "required skill is missing") for skill in sorted(validator.REQUIRED_SKILLS)]


def offline(url):
    raise AssertionError(f"unexpected network request to {url}")


def lint(path, **kwargs):
    kwargs.setdefault("remote", offline)
    return sorted((d.line, d.rule) for d in validator.lint_file(path, path.name, **kwargs))


def run_cli(*args, cwd=REPO):
    result = subprocess.run([sys.executable, str(SCRIPT), *args], cwd=cwd, capture_output=True, text=True)
    return result.returncode, result.stdout.splitlines()


class PolicyLintTest(unittest.TestCase):
    def test_positive_fixtures_pass(self):
        for path in sorted((FIXTURES / "pass").rglob("*.md")):
            with self.subTest(path=path.name):
                self.assertEqual(lint(path), [])

    def test_negative_fixtures_report_rule_and_line(self):
        expected = {
            "resource-polling.md": [(3, "resource-polling"), (7, "resource-polling"), (16, "resource-polling"),
                                    (20, "resource-polling"), (23, "resource-polling"), (26, "resource-polling"),
                                    (29, "resource-polling")],
            "excluded-operations.md": [(3, "excluded-operation"), (5, "excluded-operation"),
                                       (10, "excluded-operation"), (16, "excluded-operation")],
            "cross-rule-framing.md": [(5, "credentials"), (10, "credentials"), (16, "credentials"), (19, "credentials"),
                                      (23, "credentials")],
            "credentials.md": [(3, "credentials"), (5, "credentials"), (7, "credentials"), (10, "credentials"),
                               (14, "credentials"), (15, "credentials")],
            "links.md": [(3, "links"), (3, "links"), (5, "links")],
            "negative-framing-ends.md": [(9, "resource-polling")],
            "SKILL.md": [(1, "frontmatter"), (1, "frontmatter")],
        }
        actual = {path.name: lint(path) for path in (FIXTURES / "fail").rglob("*.md")}
        self.assertEqual(actual, expected)

    def test_cli_exits_nonzero_on_negative_fixtures_and_zero_on_positive(self):
        code, lines = run_cli("--offline", str(FIXTURES / "fail" / "resource-polling.md"))
        self.assertEqual(code, 1)
        self.assertIn("tests/fixtures/policy/fail/resource-polling.md:7: resource-polling: code repeatedly reads an "
                      "ordinary API resource with a delay; use a webhook, FIFO or polling endpoint for status changes",
                      lines)
        code, lines = run_cli("--offline", *map(str, sorted((FIXTURES / "pass").rglob("*.md"))))
        self.assertEqual((code, lines), (0, []))

    def test_webhook_guidance_passes_in_every_distribution_path(self):
        guides = [REPO / "references" / "receiving-webhooks.md",
                  REPO / "skills" / "straddle-best-practices" / "references" / "receiving-webhooks.md"]
        present = [path for path in guides if path.is_file()]
        self.assertTrue(present)
        for path in present:
            with self.subTest(path=path.relative_to(REPO).as_posix()):
                self.assertEqual(lint(path, remote=lambda url: 200), [])

    def test_remote_links_must_return_200_after_redirects(self):
        class Handler(http.server.BaseHTTPRequestHandler):
            def do_HEAD(self):
                routes = {"/ok": (200, None), "/moved": (301, "/ok"), "/missing": (404, None), "/head-refused": (405, None)}
                status, location = routes.get(self.path, (404, None))
                self.send_response(status)
                if location:
                    self.send_header("Location", location)
                self.end_headers()

            def do_GET(self):
                self.send_response(200 if self.path == "/head-refused" else 404)
                self.end_headers()

            def log_message(self, *args):
                pass

        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        base = f"http://127.0.0.1:{server.server_port}"
        with tempfile.TemporaryDirectory() as tmp:
            page = Path(tmp) / "links.md"
            page.write_text(f"# Links\n\n[ok]({base}/ok) and [moved]({base}/moved).\n\n"
                            f"[missing]({base}/missing) and [refused head]({base}/head-refused).\n")
            found = validator.lint_file(page, "links.md", checked_hosts=("127.0.0.1",), allowlist=(),
                                        remote=validator.fetch_status)
        self.assertEqual([str(d) for d in found],
                         [f"links.md:5: links: link {base}/missing returned 404, expected 200"])


class PackageTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        for name in PACKAGE_FILES:
            source = REPO / name
            (shutil.copytree if source.is_dir() else shutil.copy)(source, self.root / name)

    def check(self):
        package = validator.Package(self.root)
        package.check()
        return sorted((d.path, d.rule, d.message) for d in package.diagnostics)

    def edit_json(self, rel, change):
        path = self.root / rel
        value = json.loads(path.read_text())
        change(value)
        path.write_text(json.dumps(value))

    def new_gates(self):
        return [d for d in self.check() if d not in KNOWN_GATES]

    def test_committed_package_reports_only_known_gates(self):
        self.assertEqual(self.check(), sorted(KNOWN_GATES))

    def test_mcp_headers_are_rejected(self):
        self.edit_json("mcp.json", lambda v: v["mcpServers"]["straddle-api"].update(
            headers={"Authorization": "Bearer ${STRADDLE_API_KEY}"}))
        self.assertEqual(self.new_gates(), [
            ("mcp.json", "mcp", "straddle-api must not declare headers: Agent Plugins header values are literal "
             "package data and credentials are client-managed (spec section 7.2.1)")])

    def test_invalid_plugin_name_and_version_drift(self):
        self.edit_json("plugin.json", lambda v: v.update(name="Straddle_Kit"))
        self.edit_json(".cursor-plugin/plugin.json", lambda v: v.update(name="Straddle_Kit", version="0.2.0"))
        self.assertEqual(self.new_gates(), [
            (".claude-plugin/marketplace.json", "package", "must list plugin 'Straddle_Kit' exactly once"),
            (".claude-plugin/plugin.json", "package", "name must match plugin.json name 'Straddle_Kit'"),
            (".codex-plugin/plugin.json", "package", "name must match plugin.json name 'Straddle_Kit'"),
            (".cursor-plugin/plugin.json", "version", "version must match plugin.json version '0.1.0'"),
            ("plugin.json", "agent-plugins",
             "$.name does not match ^(?!.*(?:--|\\.\\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$"),
        ])

    def test_codex_icon_must_be_square_png(self):
        shutil.copy(REPO / "assets" / "logo.png", self.root / "assets" / "wide.png")
        data = bytearray((self.root / "assets" / "wide.png").read_bytes())
        data[16:20] = (1024).to_bytes(4, "big")
        (self.root / "assets" / "wide.png").write_bytes(bytes(data))
        self.edit_json(".codex-plugin/plugin.json", lambda v: v["interface"].update(composerIcon="./assets/wide.png"))
        self.assertEqual(self.new_gates(), [(".codex-plugin/plugin.json", "asset",
                                             "interface.composerIcon file ./assets/wide.png must be square, found "
                                             "1024x512")])

    def test_eval_cases_are_discovered_per_skill(self):
        skill = self.root / "skills" / "straddle-setup"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("---\nname: straddle-setup\ndescription: d\nmetadata:\n  version: 0.1.0\n---\n")
        self.assertIn(("skills/straddle-setup", "eval", "no eval case named straddle-setup-* under evals/"),
                      self.check())
        case = self.root / "evals" / "straddle-setup-reports-missing-key"
        (case / "mocks" / "straddle-admin").mkdir(parents=True)
        (case / "prompt.md").write_text("Check my Straddle setup.\n")
        (case / "mocks" / "straddle-admin" / "tool.md").write_text("ok\n")
        (self.root / "evals" / "mocks" / "straddle-api").mkdir(parents=True)
        self.assertEqual([d for d in self.new_gates() if d[0] != "skills/straddle-setup" or d[1] != "skill"], [
            ("evals/straddle-setup-reports-missing-key", "eval", "case has no graders/*.md"),
            ("evals/straddle-setup-reports-missing-key/mocks/straddle-admin", "eval",
             "mock server must be one of ['straddle-api', 'straddle-docs']"),
        ])

    def test_skill_that_adds_charge_polling_fails_with_file_and_line(self):
        shutil.copytree(REPO / "scripts", self.root / "scripts")
        skill = self.root / "skills" / "straddle-setup"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text(
            "---\nname: straddle-setup\ndescription: Check setup.\nmetadata:\n  version: 0.1.0\n---\n\n# Setup\n\n"
            "```ts\nfor (;;) {\n  const charge = await client.charges.get(id);\n  await sleep(2000);\n}\n```\n")
        code, lines = run_cli("--offline", cwd=self.root)
        self.assertEqual(code, 1)
        self.assertIn("skills/straddle-setup/SKILL.md:12: resource-polling: code repeatedly reads an ordinary API "
                      "resource with a delay; use a webhook, FIFO or polling endpoint for status changes", lines)


if __name__ == "__main__":
    unittest.main()
