import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GRADER = REPO / "evals/straddle-audit-findings-table/graders/read-installed-sdk.md"

# Exact trace.jsonl bytes (tool_use blocks) from retained straddle-audit-findings-table runs at d12526b.
SDK_READS = {
    "bash cd into the package, then cat (claude-eval-2h5xrv)":
        r'''"type":"tool_use","id":"toolu_01PdRqZFxiGaVe6CAtYGaWXP","name":"Bash","input":{"command":"cd /tmp/claude-eval-2h5xrv/home/cwd/node_modules/@straddlecom/straddle/dist/cjs; for f in client.js index.js resources/charges.js resources/webhooks.js; do echo \"=== $f\"; cat -n $f; done; ls ..; ls ../..",''',
    "bash relative cd, then sed (claude-eval-fpRtb1)":
        r'''"type":"tool_use","id":"toolu_01DF8qTjXyfKytUi6de1KmTe","name":"Bash","input":{"command":"cd node_modules/@straddlecom/straddle/dist/cjs && sed -n 224,300p client.js; grep -n \"shouldRetry\" -A20 client.js | sed -n 1,40p",''',
    "bash sed on a package path (claude-eval-fpRtb1)":
        r'''"type":"tool_use","id":"toolu_01Toig5H7j9p83jXMFLo3o6M","name":"Bash","input":{"command":"sed -n 358,385p node_modules/@straddlecom/straddle/dist/cjs/client.js; grep -n \"Payment dates\" -A12''',
    "Grep tool (claude-eval-ZWGPPP)":
        r'''"type":"tool_use","id":"toolu_01M8c8FgwJ94yUaWPtZmNc3h","name":"Grep","input":{"pattern":"idempotencyHeader","path":"/tmp/claude-eval-ZWGPPP/home/cwd/node_modules/@straddlecom/straddle/dist",''',
    "Read tool (claude-eval-2h5xrv)":
        r'''"type":"tool_use","id":"toolu_01HcqWXtKkh5c2WVC3qwEx8E","name":"Read","input":{"file_path":"/tmp/claude-eval-2h5xrv/home/cwd/node_modules/@straddlecom/straddle/dist/cjs/resources/webhooks.js"''',
}

# Commands that name the package without reading its source.
NOT_SDK_READS = {
    "version lookup: ls | head, grep package-lock.json (claude-eval-2h5xrv)":
        r'''"type":"tool_use","id":"toolu_013se2jrbWp41FJgExCewzEQ","name":"Bash","input":{"command":"cd /tmp/claude-eval-2h5xrv/home/cwd; ls node_modules/@straddlecom/straddle 2>&1 | head; grep -n -A3 '\"node_modules/@straddlecom/straddle\"' package-lock.json; command -v straddle && straddle --version && straddle auth status --json",''',
    "listing the package through a pipe":
        r'''"name":"Bash","input":{"command":"cd node_modules/@straddlecom/straddle; find dist -type f | head -50"''',
    "cd out of the package before the read":
        r'''"name":"Bash","input":{"command":"cd node_modules/@straddlecom/straddle; cd /repo; cat package.json"''',
    "the report quoting a read command":
        r'''"name":"Write","input":{"file_path":"straddle-audit-report.md","content":"cat node_modules/@straddlecom/straddle/x"''',
}


class ReadInstalledSdkGraderTest(unittest.TestCase):
    def setUp(self):
        # The native runner applies `new RegExp(pattern)` to the raw trace.jsonl text; the pattern keeps to syntax
        # that Python's re reads the same way.
        source = re.search(r"^pattern: '(.*)'$", GRADER.read_text(), re.M).group(1).replace("''", "'")
        self.pattern = re.compile(source)

    def test_sdk_source_reads_match(self):
        for name, text in SDK_READS.items():
            with self.subTest(name):
                self.assertRegex(text, self.pattern)

    def test_naming_the_package_without_reading_it_does_not_match(self):
        for name, text in NOT_SDK_READS.items():
            with self.subTest(name):
                self.assertNotRegex(text, self.pattern)


if __name__ == "__main__":
    unittest.main()
