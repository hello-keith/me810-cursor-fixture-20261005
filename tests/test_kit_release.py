import base64
import gzip
import hashlib
import io
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "kit-release"
kit = SourceFileLoader("kit_release", str(SCRIPT)).load_module()
PLUGIN_PATHS = ("plugin.json", "mcp.json", ".claude-plugin", ".codex-plugin", ".cursor-plugin", "assets", "skills",
                "references", "third_party", "LICENSE", "README.md")
# A stand-in Wizard pack: its loadBundle accepts any directory with plugin.json, and optionally rejects one that also
# holds kit/, the way a Wizard that only knows the stripped archive layout would.
BUNDLE_JS = """import { appendFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
if (process.env.KIT_TEST_MARKER) appendFileSync(process.env.KIT_TEST_MARKER, 'imported\\n');
export function loadBundle(dir) {
  if (REJECT_KIT && existsSync(join(dir, 'kit'))) return { ok: false, reason: 'unexpected kit/' };
  return { ok: existsSync(join(dir, 'plugin.json')), reason: null };
}
"""
STUB = """#!/bin/bash
echo "$(basename "$0") $*" >> "$STUB_LOG"
case "$(basename "$0") $*" in
  ${STUB_FAIL:-__never__}) exit 1 ;;
esac
case "$*" in
  "plugin list --json") cat "$STUB_DIR/$(basename "$0")-plugins.json" ;;
  "mcp list --json") cat "$STUB_DIR/$(basename "$0")-mcp.json" ;;
esac
"""
API = "https://mcp.scalar.com/mcp/d5d1b1c2-ae5b-432d-b795-4fcb31cfdedd"
DOCS = "https://straddle-build-straddle-openapi.apidocumentation.com/mcp"


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), "-c", "user.email=t@example.com", "-c", "user.name=t", *args],
                          check=True, capture_output=True, text=True).stdout.strip()


def wizard_pack(reject_kit=False, name="@straddlecom/wizard"):
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w") as pack:
        for path, text in (("package/package.json", json.dumps({"name": name, "version": "0.1.0",
                                                                 "bin": {"wizard": "dist/cli.js"}})),
                           ("package/dist/bundle.js", BUNDLE_JS.replace("REJECT_KIT", json.dumps(reject_kit)))):
            info = tarfile.TarInfo(path)
            info.size = len(text.encode())
            pack.addfile(info, io.BytesIO(text.encode()))
    return gzip.compress(buffer.getvalue(), mtime=0)


def wizard_input(data):
    return {"package": "@straddlecom/wizard", "version": "0.1.0", "bin": "wizard", "provenance": "local-candidate",
            "artifact": {"file": "straddlecom-wizard-0.1.0.tgz", "sha256": hashlib.sha256(data).hexdigest(),
                         "integrity": "sha512-" + base64.b64encode(hashlib.sha512(data).digest()).decode()},
            "source": {"repository": "straddle-build/wizard", "commit": "0" * 40},
            "skill_bundle": json.loads((REPO / "kit" / "release-inputs.json").read_text())["wizard"]["skill_bundle"]}


class KitReleaseTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        for rel in PLUGIN_PATHS:
            source = REPO / rel
            (shutil.copytree if source.is_dir() else shutil.copy)(source, self.root / rel)
        inputs = json.loads((REPO / "kit" / "release-inputs.json").read_text())
        inputs["wizard"] = wizard_input(wizard_pack())
        self.write_inputs(inputs)
        git(self.root, "init", "-q")
        self.commit_all("source")

    def scratch(self):
        path = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, path)
        return path

    def write_inputs(self, inputs):
        (self.root / "kit").mkdir(exist_ok=True)
        (self.root / "kit" / "release-inputs.json").write_text(json.dumps(inputs, indent=2))

    def inputs(self):
        return json.loads((self.root / "kit" / "release-inputs.json").read_text())

    def run_kit(self, *args, env=None):
        result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(self.root), *args],
                                capture_output=True, text=True, env={**os.environ, **(env or {})})
        return result.returncode, result.stdout + result.stderr

    def build(self):
        out = self.scratch()
        code, output = self.run_kit("build", "--out", str(out))
        self.assertEqual(code, 0, output)
        return (out / "straddle-plugin-0.1.0.zip").read_bytes(), (out / "SHA256SUMS").read_text()

    def commit_all(self, message):
        git(self.root, "add", "-A")
        git(self.root, "commit", "-qm", message)

    def model(self):
        return kit.manifest_model(self.root, git(self.root, "rev-parse", "HEAD"), self.inputs())

    def released_inputs(self):
        inputs = self.inputs()
        inputs["kit"]["status"] = "release"
        inputs["plugin_release"] = {"tag": "v0.1.0", "checksum_url": "https://example.com/SHA256SUMS"}
        inputs["wizard"] = {**inputs["wizard"], "provenance": "released",
                            "evidence": {"url": "https://example.com/wizard",
                                         "digest": {"algorithm": "sha512", "value": "x"}}}
        for gate in inputs["gates"]:
            gate.update(status="passed", evidence="test")
        return inputs

    def stub_clients(self, plugins=None, mcp=None):
        """Fake claude, codex and npm that log their arguments; STUB_FAIL makes a matching call exit 1."""
        stubs = self.scratch()
        for client in ("claude", "codex", "npm"):
            (stubs / client).write_text(STUB)
            (stubs / client).chmod(0o755)
        for client, listing in (plugins or {}).items():
            (stubs / f"{client}-plugins.json").write_text(json.dumps(listing))
        for client, listing in (mcp or {}).items():
            (stubs / f"{client}-mcp.json").write_text(json.dumps(listing))
        return stubs

    def run_operation(self, operation, stubs, kit_dir, fail=None):
        env = {"PATH": f"{stubs}:/usr/bin:/bin", "STUB_LOG": str(stubs / "log"), "STUB_DIR": str(stubs),
               "HOME": str(stubs)}
        if kit_dir is not None:
            env["STRADDLE_KIT_DIR"] = str(kit_dir)
        if fail:
            env["STUB_FAIL"] = fail
        result = subprocess.run(["bash", "-c", operation], env=env, capture_output=True, text=True)
        self.last_output = result.stdout + result.stderr
        log = (stubs / "log").read_text().splitlines() if (stubs / "log").exists() else []
        (stubs / "log").unlink(missing_ok=True)
        return result.returncode, log

    def kit_dir_with(self, archive):
        kit_dir = self.scratch()
        (kit_dir / "straddle-plugin-0.1.0.zip").write_bytes(archive)
        return kit_dir

    def test_build_is_reproducible_from_git_and_excludes_kit_and_worktree(self):
        first, sums = self.build()
        self.assertEqual(sums, f"{hashlib.sha256(first).hexdigest()}  straddle-plugin-0.1.0.zip\n")
        skill = self.root / "skills" / "straddle-setup" / "SKILL.md"
        skill.write_text(skill.read_text() + "\nuncommitted edit\n")
        (self.root / "kit" / "manifest.yaml").write_text("anything\n")
        self.assertEqual(self.build()[0], first)
        git(self.root, "add", "kit")
        git(self.root, "commit", "-qm", "kit only")
        self.assertEqual(self.build()[0], first)
        self.commit_all("skill change")
        self.assertNotEqual(self.build()[0], first)

    def test_generate_requires_the_wizard_artifact(self):
        inputs = self.inputs()
        del inputs["wizard"]
        self.write_inputs(inputs)
        code, output = self.run_kit("generate")
        self.assertEqual(code, 1)
        self.assertIn("wizard (the Wizard npm pack artifact is a true dependency) is required", output)
        self.assertFalse((self.root / "kit" / "manifest.yaml").exists())

    def test_check_fails_on_stale_manifest_and_skill_drift_fails_generation(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("manifest")
        self.assertEqual(self.run_kit("check"),
                         (0, f"kit-release check (local candidate) at {git(self.root, 'rev-parse', 'HEAD')}: ok\n"))
        inputs = self.inputs()
        inputs["clients"]["codex"]["observed_version"] = "9.9.9"
        self.write_inputs(inputs)
        code, output = self.run_kit("check")
        self.assertEqual(code, 1)
        self.assertIn("kit/manifest.yaml does not match plugin source", output)
        skill = self.root / "skills" / "straddle-plan" / "SKILL.md"
        skill.write_text(skill.read_text() + "\nchanged\n")
        self.commit_all("skill drift")
        code, output = self.run_kit("generate")
        self.assertEqual(code, 1)
        self.assertIn("wizard.skill_bundle.content_sha256 e9a5db1d995e5798681e04d9d7f840000b6e0861f3e4b76ae3a31b881ad00b7c "
                      "does not match the plugin content", output)

    def test_manifest_records_versions_digests_and_candidate_provenance(self):
        manifest = self.model()
        archive, _ = self.build()
        self.assertEqual(manifest["plugin"]["archive"]["sha256"], hashlib.sha256(archive).hexdigest())
        self.assertEqual(manifest["plugin"]["content_sha256"],
                         "e9a5db1d995e5798681e04d9d7f840000b6e0861f3e4b76ae3a31b881ad00b7c")
        self.assertEqual((manifest["kit"]["status"], manifest["plugin"]["provenance"]), ("candidate", "local-candidate"))
        self.assertEqual(manifest["cli"]["minimum_version"], "1.0.3")
        self.assertEqual({name: sdk["minimum_version"] for name, sdk in manifest["sdks"].items()},
                         {"typescript": "1.0.4", "python": "1.0.5", "ruby": "1.0.4", "dotnet": "1.0.4", "go": "1.0.4"})
        self.assertEqual(manifest["hosted_mcp"]["contract_version_served"], "1.0.4")

    def test_generate_rejects_incomplete_or_malformed_inputs(self):
        def drop(path):
            def edit(inputs):
                *parents, last = path
                target = inputs
                for key in parents:
                    target = target[key]
                del target[last]
            return edit

        def duplicate_gate(inputs):
            inputs["gates"].append(dict(inputs["gates"][0]))

        def set_value(path, value):
            def edit(inputs):
                *parents, last = path
                target = inputs
                for key in parents:
                    target = target[key]
                target[last] = value
            return edit

        def drop_pins(inputs):
            del inputs["contract"]["version"]
            del inputs["hosted_mcp"]["contract_version_served"]

        cases = {
            "sdks must list exactly": drop(("sdks", "python")),
            "cli.minimum_version is required": drop(("cli", "minimum_version")),
            "contract.version is required": drop_pins,
            "sdks.go.evidence.digest is required": drop(("sdks", "go", "evidence", "digest")),
            "required gate walkthrough-approval is missing": lambda i: i["gates"].pop(0),
            "gate walkthrough-approval is listed more than once": duplicate_gate,
            "wizard.provenance must be one of": set_value(("wizard", "provenance"), "local_candidate"),
            "hosted_mcp.api_url does not match straddle-api in mcp.json":
                set_value(("hosted_mcp", "api_url"), "https://example.com/mcp"),
            "sdks.ruby.minimum_version is newer than version": set_value(("sdks", "ruby", "minimum_version"), "1.1.0"),
            "plugin_repository must be a GitHub owner/name": set_value(("plugin_repository",), "x; rm -rf /"),
        }
        original = self.inputs()
        for message, edit in cases.items():
            with self.subTest(message=message):
                inputs = json.loads(json.dumps(original))
                edit(inputs)
                self.write_inputs(inputs)
                code, output = self.run_kit("generate")
                self.assertEqual(code, 1, output)
                self.assertIn(message, output)

    def test_release_validation_rejects_unpublished_components(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("manifest")
        code, output = self.run_kit("check", "--release")
        self.assertEqual(code, 1)
        for problem in ("kit.status is 'candidate'; a published release requires 'release'",
                        "wizard: provenance is 'local-candidate', not published",
                        "plugin: no published release (plugin_release.tag v0.1.0 and checksum_url)",
                        "gate walkthrough-approval: open",
                        "kit-release check (published release)"):
            self.assertIn(problem, output)

    def test_release_validation_passes_only_with_proof_and_matching_tag(self):
        self.write_inputs(self.released_inputs())
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("release manifest")
        code, output = self.run_kit("check", "--release")
        self.assertEqual(code, 1)
        self.assertIn("plugin: tag v0.1.0 does not exist in this repository", output)
        git(self.root, "tag", "v0.1.0")
        self.assertEqual(self.run_kit("check", "--release")[0], 0)
        (self.root / "kit" / "notes.txt").write_text("after tag\n")
        self.commit_all("after tag")
        code, output = self.run_kit("check", "--release")
        self.assertEqual(code, 1)
        self.assertIn("plugin: tag v0.1.0 does not point at", output)

    def test_release_validation_reports_missing_evidence_on_passed_gate(self):
        inputs = self.released_inputs()
        inputs["gates"][0]["evidence"] = ""
        self.write_inputs(inputs)
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("gate missing evidence")
        git(self.root, "tag", "v0.1.0")
        code, output = self.run_kit("check", "--release")
        self.assertEqual(code, 1)
        self.assertIn("gate walkthrough-approval: passed but missing evidence", output)

    def test_wizard_tarball_must_match_and_accept_archive_and_checkout(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("manifest")
        tarball = self.scratch() / "straddlecom-wizard-0.1.0.tgz"
        tarball.write_bytes(wizard_pack())
        self.assertEqual(self.run_kit("check", "--wizard-tarball", str(tarball))[0], 0)
        tarball.write_bytes(wizard_pack() + b"!")
        code, output = self.run_kit("check", "--wizard-tarball", str(tarball))
        self.assertEqual(code, 1)
        self.assertIn("sha256 does not match wizard.artifact.sha256", output)
        rejecting = wizard_pack(reject_kit=True)
        inputs = self.inputs()
        inputs["wizard"] = wizard_input(rejecting)
        self.write_inputs(inputs)
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("kit-rejecting wizard")
        tarball.write_bytes(rejecting)
        code, output = self.run_kit("check", "--wizard-tarball", str(tarball))
        self.assertEqual(code, 1)
        self.assertIn("the Wizard rejects the full repository checkout", output)
        self.assertNotIn("rejects the plugin archive", output)

    def test_wizard_tarball_code_runs_only_after_bytes_and_identity_verify(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("manifest")
        marker = self.scratch() / "imported"
        env = {"KIT_TEST_MARKER": str(marker)}
        tarball = self.scratch() / "straddlecom-wizard-0.1.0.tgz"
        tarball.write_bytes(wizard_pack(name="@straddlecom/wizard-other"))
        code, output = self.run_kit("check", "--wizard-tarball", str(tarball), env=env)
        self.assertEqual((code, marker.exists()), (1, False))
        self.assertIn("sha256 does not match wizard.artifact.sha256", output)
        inputs = self.inputs()
        inputs["wizard"] = {**wizard_input(tarball.read_bytes()), "package": "@straddlecom/wizard"}
        self.write_inputs(inputs)
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("recorded digests of a pack with another package name")
        code, output = self.run_kit("check", "--wizard-tarball", str(tarball), env=env)
        self.assertEqual((code, marker.exists()), (1, False))
        self.assertIn("package.json name, version or bin differs", output)
        inputs["wizard"] = wizard_input(wizard_pack())
        self.write_inputs(inputs)
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("verified pack")
        tarball.write_bytes(wizard_pack())
        self.assertEqual(self.run_kit("check", "--wizard-tarball", str(tarball), env=env)[0], 0)
        self.assertEqual(marker.read_text(), "imported\nimported\n")

    def test_candidate_install_changes_nothing_without_a_verified_archive(self):
        archive, _ = self.build()
        operations = self.model()["instructions"]
        for client, directory in (("claude-code", "claude-code-plugin"), ("codex", "codex-plugin")):
            with self.subTest(client=client):
                stubs = self.stub_clients()
                tampered = self.kit_dir_with(archive[:-1] + b"x")
                code, log = self.run_operation(operations[client]["candidate"]["install"], stubs, tampered)
                self.assertNotEqual(code, 0)
                self.assertEqual((log, sorted(p.name for p in tampered.iterdir())), ([], ["straddle-plugin-0.1.0.zip"]))
                code, log = self.run_operation(operations[client]["candidate"]["install"], stubs, None)
                self.assertNotEqual(code, 0)
                self.assertEqual(log, [])
                good = self.kit_dir_with(archive)
                code, log = self.run_operation(operations[client]["candidate"]["install"], stubs, good)
                self.assertEqual(code, 0)
                self.assertTrue((good / directory / "plugin.json").is_file())
        stubs = self.stub_clients()
        wizard_dir = self.scratch()
        (wizard_dir / "straddlecom-wizard-0.1.0.tgz").write_bytes(wizard_pack() + b"!")
        code, log = self.run_operation(operations["wizard"]["candidate"]["install"], stubs, wizard_dir)
        self.assertNotEqual(code, 0)
        self.assertEqual(log, [])

    def test_update_keeps_the_installed_plugin_when_verification_or_refresh_fails(self):
        archive, _ = self.build()
        operations = self.model()["instructions"]
        for client, directory, refresh in (("claude-code", "claude-code-plugin", "claude plugin update*"),
                                           ("codex", "codex-plugin", "codex plugin add*")):
            with self.subTest(client=client):
                stubs = self.stub_clients()
                kit_dir = self.kit_dir_with(archive)
                self.assertEqual(self.run_operation(operations[client]["candidate"]["install"], stubs, kit_dir)[0], 0)
                (kit_dir / directory / "previous-install").write_text("0.1.0\n")
                (kit_dir / "straddle-plugin-0.1.0.zip").write_bytes(archive[:-1] + b"x")
                code, log = self.run_operation(operations[client]["candidate"]["update"], stubs, kit_dir)
                self.assertEqual((code != 0, log), (True, []))
                self.assertTrue((kit_dir / directory / "previous-install").is_file())
                (kit_dir / "straddle-plugin-0.1.0.zip").write_bytes(archive)
                code, log = self.run_operation(operations[client]["candidate"]["update"], stubs, kit_dir, fail=refresh)
                self.assertNotEqual(code, 0)
                self.assertTrue((kit_dir / directory / "previous-install").is_file())
                self.assertEqual(sorted(p.name for p in kit_dir.iterdir()), [directory, "straddle-plugin-0.1.0.zip"])
                code, log = self.run_operation(operations[client]["candidate"]["update"], stubs, kit_dir)
                self.assertEqual(code, 0)
                self.assertFalse((kit_dir / directory / "previous-install").exists())

    def test_release_update_verifies_the_tag_content_before_changing_anything(self):
        operations = self.model()["instructions"]["claude-code"]["release"]
        origin = self.scratch() / "skills"
        git(self.root, "clone", "-q", str(self.root), str(origin))
        (origin / "README.md").write_text("not the released content\n")
        git(origin, "commit", "-qam", "drift")
        git(origin, "tag", "v0.1.0")
        local = {op: text.replace("https://github.com/straddle-build/skills.git", str(origin))
                 for op, text in operations.items()}
        stubs = self.stub_clients()
        kit_dir = self.scratch()
        (kit_dir / "claude-code-plugin").mkdir()
        (kit_dir / "claude-code-plugin" / "previous-install").write_text("0.0.9\n")
        code, log = self.run_operation(local["update"], stubs, kit_dir)
        self.assertEqual((code != 0, log), (True, []))
        self.assertEqual(sorted(p.name for p in kit_dir.iterdir()), ["claude-code-plugin"])
        self.assertTrue((kit_dir / "claude-code-plugin" / "previous-install").is_file())
        git(origin, "tag", "-f", "v0.1.0", "HEAD~1")
        code, log = self.run_operation(local["update"], stubs, kit_dir)
        self.assertEqual(code, 0)
        self.assertEqual(log, ["claude plugin marketplace update straddle", "claude plugin update straddle@straddle"])
        self.assertFalse((kit_dir / "claude-code-plugin" / "previous-install").exists())

    def test_release_install_hands_clients_only_the_verified_plugin_files(self):
        operations = self.model()["instructions"]["codex"]["release"]
        origin = self.scratch() / "skills"
        git(self.root, "clone", "-q", str(self.root), str(origin))
        (origin / "hooks").mkdir()
        (origin / "hooks" / "hooks.json").write_text('{"hooks": {"SessionStart": []}}\n')
        (origin / "kit" / "manifest.yaml").write_text("inert release metadata\n")
        git(origin, "add", "-A")
        git(origin, "commit", "-qm", "root hooks and kit metadata beside the plugin")
        git(origin, "tag", "v0.1.0")
        local = {op: text.replace("https://github.com/straddle-build/skills.git", str(origin))
                 for op, text in operations.items()}
        stubs = self.stub_clients()
        kit_dir = self.scratch()
        code, log = self.run_operation(local["install"], stubs, kit_dir)
        self.assertEqual(code, 0)
        self.assertTrue(log[0].startswith("codex plugin marketplace add ") and log[0].endswith("/codex-plugin"), log)
        self.assertEqual(sorted(p.name for p in (kit_dir / "codex-plugin").iterdir()), sorted(PLUGIN_PATHS))
        self.assertEqual(sorted(p.name for p in kit_dir.iterdir()), ["codex-plugin"])
        (origin / "skills" / "straddle-setup" / "linked.md").symlink_to("/etc/hosts")
        git(origin, "add", "-A")
        git(origin, "commit", "-qm", "symlink inside a skill")
        git(origin, "tag", "-f", "v0.1.0")
        (kit_dir / "codex-plugin" / "previous-install").write_text("0.1.0\n")
        code, log = self.run_operation(local["update"], stubs, kit_dir)
        self.assertEqual((code != 0, log), (True, []))
        self.assertEqual(sorted(p.name for p in kit_dir.iterdir()), ["codex-plugin"])
        self.assertTrue((kit_dir / "codex-plugin" / "previous-install").is_file())

    def test_content_check_rejects_extra_root_entries_and_links(self):
        files = kit.source_files(self.root, git(self.root, "rev-parse", "HEAD"))
        check = "( set -eu; " + kit.content_check("stage", kit.tree_digest(files)) + " )"
        for extra in (None, "hooks", "link"):
            with self.subTest(extra=extra):
                scratch = self.scratch()
                for name, _, data in files:
                    (scratch / "stage" / name).parent.mkdir(parents=True, exist_ok=True)
                    (scratch / "stage" / name).write_bytes(data)
                if extra == "hooks":
                    (scratch / "stage" / "hooks").mkdir()
                    (scratch / "stage" / "hooks" / "hooks.json").write_text('{"hooks": {}}\n')
                if extra == "link":
                    (scratch / "stage" / "assets" / "logo-link.svg").symlink_to("logo.svg")
                result = subprocess.run(["bash", "-c", check], cwd=scratch, capture_output=True, text=True)
                self.assertEqual((result.returncode == 0, (scratch / "stage").exists()), (extra is None,) * 2)

    def test_codex_validate_requires_the_bearer_variable_name_without_echoing_other_servers(self):
        validate = self.model()["instructions"]["codex"]["candidate"]["validate"]
        plugins = {"installed": [{"pluginId": "straddle@straddle", "version": "0.1.0", "enabled": True}]}
        other = {"name": "stdio-tool", "enabled": True, "transport": {"type": "stdio", "command": "run"}}
        secret = "Bearer " + "synthetic-unrelated-credential"
        unrelated = {"name": "other-mcp", "enabled": True,
                     "transport": {"url": "https://example.invalid/mcp", "http_headers": {"Authorization": secret}}}
        docs = {"name": "straddle-docs", "enabled": True, "transport": {"url": DOCS}}
        for bearer, expected in (("STRADDLE_API_KEY", 0), (None, 1), ("OTHER_KEY", 1)):
            with self.subTest(bearer=bearer):
                api = {"name": "straddle-api", "enabled": True, "transport": {"url": API, "bearer_token_env_var": bearer}}
                stubs = self.stub_clients({"codex": plugins}, {"codex": [other, unrelated, api, docs]})
                code, _ = self.run_operation(validate, stubs, None)
                self.assertEqual(code != 0, bool(expected))
                self.assertNotIn("synthetic-unrelated-credential", self.last_output)
                self.assertNotIn("example.invalid", self.last_output)
                if expected:
                    self.assertIn('"straddle-api bearer_token_env_var is STRADDLE_API_KEY": false', self.last_output)


if __name__ == "__main__":
    unittest.main()
