import base64
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "kit-release"
WIZARD_BYTES = b"wizard tarball bytes for tests"
PLUGIN_PATHS = ("plugin.json", "mcp.json", ".claude-plugin", ".codex-plugin", ".cursor-plugin", "assets", "skills",
                "references", "third_party", "LICENSE", "README.md")


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), "-c", "user.email=t@example.com", "-c", "user.name=t", *args],
                          check=True, capture_output=True, text=True).stdout.strip()


def parse_yaml(text):
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        lines.append((indent, stripped))

    def parse_block(idx, current_indent):
        if idx >= len(lines):
            return None, idx
        indent, content = lines[idx]
        if indent < current_indent:
            return None, idx
        if content.startswith("- "):
            res = []
            while idx < len(lines):
                ind, cont = lines[idx]
                if ind < current_indent:
                    break
                if ind == current_indent and cont.startswith("- "):
                    val_str = cont[2:].strip()
                    if ":" in val_str and not (val_str.startswith("\"") or val_str.startswith("{") or val_str.startswith("[")):
                        k, v = val_str.split(":", 1)
                        k, v = k.strip(), v.strip()
                        sub_dict = {}
                        idx += 1
                        if v:
                            sub_dict[k] = json.loads(v)
                        else:
                            nested, idx = parse_block(idx, ind + 2)
                            sub_dict[k] = nested
                        while idx < len(lines):
                            i2, c2 = lines[idx]
                            if i2 < ind + 2 or (i2 == ind and c2.startswith("- ")):
                                break
                            if ":" in c2:
                                k2, v2 = c2.split(":", 1)
                                k2, v2 = k2.strip(), v2.strip()
                                idx += 1
                                if v2:
                                    sub_dict[k2] = json.loads(v2)
                                else:
                                    nested, idx = parse_block(idx, i2 + 2)
                                    sub_dict[k2] = nested
                            else:
                                break
                        res.append(sub_dict)
                    elif val_str:
                        res.append(json.loads(val_str))
                        idx += 1
                    else:
                        idx += 1
                        nested, idx = parse_block(idx, ind + 2)
                        res.append(nested)
                else:
                    break
            return res, idx
        else:
            res = {}
            while idx < len(lines):
                ind, cont = lines[idx]
                if ind < current_indent:
                    break
                if ind == current_indent:
                    k, v = cont.split(":", 1)
                    k, v = k.strip(), v.strip()
                    idx += 1
                    if v:
                        res[k] = json.loads(v)
                    else:
                        nested, idx = parse_block(idx, ind + 2)
                        res[k] = nested
                else:
                    break
            return res, idx

    parsed, _ = parse_block(0, 0)
    return parsed


class KitReleaseTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        for rel in PLUGIN_PATHS:
            source = REPO / rel
            (shutil.copytree if source.is_dir() else shutil.copy)(source, self.root / rel)
        inputs = json.loads((REPO / "kit" / "release-inputs.json").read_text())
        inputs["wizard"] = {
            "package": "@straddlecom/wizard", "version": "0.1.0", "bin": "wizard", "provenance": "local-candidate",
            "artifact": {"file": "straddlecom-wizard-0.1.0.tgz", "sha256": hashlib.sha256(WIZARD_BYTES).hexdigest(),
                         "integrity": "sha512-" + base64.b64encode(hashlib.sha512(WIZARD_BYTES).digest()).decode()},
            "source": {"repository": "straddle-build/wizard", "commit": "0" * 40},
        }
        self.write_inputs(inputs)
        git(self.root, "init", "-q")
        git(self.root, "add", "-A")
        git(self.root, "commit", "-qm", "source")

    def write_inputs(self, inputs):
        (self.root / "kit").mkdir(exist_ok=True)
        (self.root / "kit" / "release-inputs.json").write_text(json.dumps(inputs, indent=2))

    def inputs(self):
        return json.loads((self.root / "kit" / "release-inputs.json").read_text())

    def run_kit(self, *args):
        result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(self.root), *args],
                                capture_output=True, text=True)
        return result.returncode, result.stdout + result.stderr

    def build(self, name):
        out = self.root.parent / f"{self.root.name}-{name}"
        self.addCleanup(shutil.rmtree, out, True)
        code, output = self.run_kit("build", "--out", str(out))
        self.assertEqual(code, 0, output)
        return (out / "straddle-plugin-0.1.0.zip").read_bytes(), (out / "SHA256SUMS").read_text()

    def commit_all(self, message):
        git(self.root, "add", "-A")
        git(self.root, "commit", "-qm", message)

    def test_build_is_reproducible_from_git_and_excludes_kit_and_worktree(self):
        first, sums = self.build("a")
        skill = self.root / "skills" / "straddle-setup" / "SKILL.md"
        skill.write_text(skill.read_text() + "\nuncommitted edit\n")
        (self.root / "kit" / "manifest.yaml").write_text("anything\n")
        self.assertEqual(self.build("b")[0], first)
        git(self.root, "add", "kit")
        git(self.root, "commit", "-qm", "kit only")
        self.assertEqual(self.build("c")[0], first)
        self.commit_all("skill change")
        self.assertNotEqual(self.build("d")[0], first)

    def test_generate_requires_the_wizard_artifact(self):
        inputs = self.inputs()
        del inputs["wizard"]
        self.write_inputs(inputs)
        code, output = self.run_kit("generate")
        self.assertEqual(code, 1)
        self.assertIn("wizard (the Wizard npm pack artifact is a true dependency) is required", output)
        self.assertFalse((self.root / "kit" / "manifest.yaml").exists())

    def test_check_passes_fresh_manifest_and_fails_on_source_drift(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("manifest")
        self.assertEqual(self.run_kit("check"), (0, f"kit-release check (local candidate) at {git(self.root, 'rev-parse', 'HEAD')}: ok\n"))
        skill = self.root / "skills" / "straddle-plan" / "SKILL.md"
        skill.write_text(skill.read_text() + "\nchanged\n")
        self.commit_all("skill drift")
        code, output = self.run_kit("check")
        self.assertEqual(code, 1)
        self.assertIn("kit/manifest.yaml does not match plugin source", output)

    def test_manifest_records_versions_digests_and_candidate_provenance(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.assertEqual(self.run_kit("check")[0], 0)
        manifest = parse_yaml((self.root / "kit" / "manifest.yaml").read_text())
        archive, _ = self.build("m")
        self.assertEqual(manifest["plugin"]["archive"]["sha256"], hashlib.sha256(archive).hexdigest())
        self.assertEqual(manifest["kit"]["status"], "candidate")
        self.assertEqual(manifest["plugin"]["provenance"], "local-candidate")
        self.assertEqual(manifest["cli"]["minimum_version"], "1.0.3")
        self.assertEqual(manifest["hosted_mcp"]["contract_version_served"], "1.0.4")
        self.assertIn("claude plugin marketplace add https://github.com/straddle-build/skills.git#v0.1.0",
                      manifest["instructions"]["claude-code"]["release"]["install"])
        self.assertIn("codex plugin marketplace add straddle-build/skills --ref v0.1.0",
                      manifest["instructions"]["codex"]["release"]["install"])

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
        inputs = self.inputs()
        inputs["kit"]["status"] = "release"
        inputs["plugin_release"] = {"tag": "v0.1.0", "checksum_url": "https://example.com/SHA256SUMS"}
        inputs["wizard"] = {"package": "@straddlecom/wizard", "version": "0.1.0", "bin": "wizard",
                            "provenance": "released", "evidence": {"url": "https://example.com/wizard",
                                                                   "digest": {"algorithm": "sha512", "value": "x"}}}
        for gate in inputs["gates"]:
            gate.update(status="passed", evidence="test")
        self.write_inputs(inputs)
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("release manifest")
        code, output = self.run_kit("check", "--release")
        self.assertEqual(code, 1)
        self.assertIn("plugin: tag v0.1.0 does not exist in this repository", output)
        git(self.root, "tag", "v0.1.0")
        self.assertEqual(self.run_kit("check", "--release")[0], 0)
        (self.root / "README.md").write_text("after tag\n")
        self.commit_all("after tag")
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("regenerate")
        code, output = self.run_kit("check", "--release")
        self.assertEqual(code, 1)
        self.assertIn("plugin: tag v0.1.0 does not point at", output)

    def test_wizard_tarball_bytes_must_match(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("manifest")
        tarball = self.root.parent / f"{self.root.name}.tgz"
        self.addCleanup(tarball.unlink)
        tarball.write_bytes(WIZARD_BYTES)
        self.assertEqual(self.run_kit("check", "--wizard-tarball", str(tarball))[0], 0)
        tarball.write_bytes(WIZARD_BYTES + b"!")
        code, output = self.run_kit("check", "--wizard-tarball", str(tarball))
        self.assertEqual(code, 1)
        self.assertIn("sha256 does not match wizard.artifact.sha256", output)

    def test_hosted_mcp_must_serve_the_manifest_contract(self):
        inputs = self.inputs()
        inputs["hosted_mcp"]["contract_version_served"] = "1.0.3"
        self.write_inputs(inputs)
        code, output = self.run_kit("generate")
        self.assertEqual(code, 1)
        self.assertIn("hosted_mcp.contract_version_served must equal contract.version", output)

    def test_codex_validate_tolerates_non_url_transports(self):
        self.assertEqual(self.run_kit("generate")[0], 0)
        manifest = parse_yaml((self.root / "kit" / "manifest.yaml").read_text())
        command = manifest["instructions"]["codex"]["candidate"]["validate"][1]
        py_code = command.split("python3 -c ")[1].strip("'")
        servers = [
            {"name": "stdio-tool", "enabled": True, "transport": {"type": "stdio", "command": "run"}},
            {"name": "straddle-api", "enabled": True, "transport": {"type": "http", "url": "https://mcp.scalar.com/mcp/d5d1b1c2-ae5b-432d-b795-4fcb31cfdedd"}},
            {"name": "straddle-docs", "enabled": True, "transport": {"type": "http", "url": "https://straddle-build-straddle-openapi.apidocumentation.com/mcp"}},
        ]
        res = subprocess.run([sys.executable, "-c", py_code], input=json.dumps(servers), text=True, capture_output=True)
        self.assertEqual(res.returncode, 0, res.stderr)

    def test_release_validation_reports_missing_evidence_on_passed_gate(self):
        inputs = self.inputs()
        inputs["kit"]["status"] = "release"
        inputs["plugin_release"] = {"tag": "v0.1.0", "checksum_url": "https://example.com/SHA256SUMS"}
        inputs["wizard"] = {"package": "@straddlecom/wizard", "version": "0.1.0", "bin": "wizard",
                            "provenance": "released", "evidence": {"url": "https://example.com/wizard",
                                                                   "digest": {"algorithm": "sha512", "value": "x"}}}
        for gate in inputs["gates"]:
            gate.update(status="passed", evidence="test")
        inputs["gates"][0]["evidence"] = ""
        self.write_inputs(inputs)
        self.assertEqual(self.run_kit("generate")[0], 0)
        self.commit_all("gate missing evidence")
        git(self.root, "tag", "v0.1.0")
        code, output = self.run_kit("check", "--release")
        self.assertEqual(code, 1)
        self.assertIn(f"gate {inputs['gates'][0]['id']}: passed but missing evidence", output)


if __name__ == "__main__":
    unittest.main()
