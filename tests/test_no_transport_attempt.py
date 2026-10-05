import json
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GRADERS = sorted(REPO.glob("evals/*/graders/no-transport-attempt.md"))


def trace_line(text):
    """A Bash tool result as `claude plugin eval` writes it to trace.jsonl."""
    event = {"type": "user", "message": {"role": "user", "content": [
        {"type": "tool_result", "tool_use_id": "toolu_01", "content": text}]}}
    return json.dumps(event, ensure_ascii=False)


# Captured from real runs against a closed port (Python 1.0.5, Ruby 1.0.4, TS SDK, Node 22, Go, .NET 8).
REAL_ERRORS = {
    "python traceback": "  File \"/venv/lib/python3.12/site-packages/straddle/_base_client.py\", line 1125, in request\n"
                        "    raise APIConnectionError(request=request) from err\n"
                        "straddle.APIConnectionError: Connection error.",
    "python str(e) alone": "Connection error.",
    "python str(e) after output": "Listing customers\nConnection error.\n",
    "python repr(e)": "APIConnectionError('Connection error.')",
    "python JSON error body": '{"error": "Connection error."}',
    "ts sdk uncaught": "APIConnectionError: Connection error.\n"
                       "    at StraddleAPI.makeRequest (/repo/node_modules/@straddlecom/straddle/client.js:286:19)",
    "ts sdk cause": "  cause: TypeError: fetch failed",
    "node fetch": "Exit code 1\nTypeError: fetch failed\n    at node:internal/deps/undici/undici:15141:13",
    "node ECONNREFUSED": "  [cause]: Error: connect ECONNREFUSED 127.0.0.1:59999",
    "go dial": 'Post "http://127.0.0.1:9/v1/charges": dial tcp 127.0.0.1:9: connect: connection refused',
    "dotnet uncaught": "Unhandled exception. System.Net.Http.HttpRequestException: Connection refused (127.0.0.1:9)",
    "dotnet message": "Connection refused (127.0.0.1:9)",
    "ruby uncaught": "/repo/vendor/gems/gems/straddle-1.0.4/lib/straddle/internal/transport/pooled_net_requester.rb:187:"
                     "in `rescue in block in execute': Connection error. (Straddle::Errors::APIConnectionError)",
    "ruby inspect": "#<Straddle::Errors::APIConnectionError: Connection error.>",
}

# Exact trace.jsonl bytes from retained runs where the agent read SDK source and the old pattern failed the run.
SOURCE_LITERALS = {
    "python _exceptions.py (claude-eval-QnPuLx)":
        r'''APIConnectionError(APIError):\n77:    def __init__(self, *, message: str = \"Connection error.\", request: httpx.Request) -> None:\n81:class API''',
    "ts core/error.ts (claude-eval-fc3Z6x)":
        r'''essage, cause }) {\n76\t        super(undefined, undefined, message || 'Connection error.', undefined);\n77\t        // in some environment''',
    "ts client.ts comment (claude-eval-ain6QT)":
        r'''): Operation timed out (os error 60)\"\n262\t            // undici throws \"TypeError: fetch failed\" with cause \"ConnectTimeoutError: Connect Timeo''',
    "ruby errors.rb": trace_line('    93\t        response: nil,\n    94\t        message: "Connection error."\n    95\t      )'),
}


class NoTransportAttemptGraderTest(unittest.TestCase):
    def setUp(self):
        texts = {path.read_text() for path in GRADERS}
        self.assertTrue(GRADERS, "no no-transport-attempt graders found")
        self.assertEqual(len(texts), 1, "no-transport-attempt.md copies differ")
        source = re.search(r"^pattern: '(.*)'$", texts.pop(), re.M).group(1).replace("''", "'")
        # The native runner applies `new RegExp(pattern)` to the raw trace.jsonl text; the pattern keeps to syntax
        # that Python's re reads the same way.
        self.pattern = re.compile(source)

    def test_real_connection_errors_match(self):
        for name, text in REAL_ERRORS.items():
            with self.subTest(name):
                self.assertRegex(trace_line(text), self.pattern)

    def test_sdk_source_literals_do_not_match(self):
        for name, jsonl in SOURCE_LITERALS.items():
            with self.subTest(name):
                self.assertNotRegex(jsonl, self.pattern)


if __name__ == "__main__":
    unittest.main()
