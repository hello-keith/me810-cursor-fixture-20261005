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
        text = (self.root / "kit" / "manifest.yaml").read_text()
        archive, _ = self.build("m")
        self.assertIn(f'    sha256: "{hashlib.sha256(archive).hexdigest()}"\n', text)
        self.assertIn('  status: "candidate"\n', text)
        self.assertIn('  provenance: "local-candidate"\n', text)
        self.assertIn('  minimum_version: "1.0.3"\n', text)
        self.assertIn('  contract_version_served: "1.0.4"\n', text)
        self.assertIn('        - "claude plugin marketplace add https://github.com/straddle-build/skills.git#v0.1.0"\n',
                      text)
        self.assertIn('        - "codex plugin marketplace add straddle-build/skills --ref v0.1.0"\n', text)

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


if __name__ == "__main__":
    unittest.main()
