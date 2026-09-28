---
type: llm
focus: { source: file, path: straddle-test-evidence.md }
---

PASS if the evidence labels the run as offline synthetic proof against the localhost upstream and not live Straddle Sandbox proof, records the repository's offline test results, marks live Sandbox scenarios (paid, R01 return, notification delivery) as not run or not applicable for the offline target rather than passed, records authenticated API MCP execution as not run for the offline target, and lists no Straddle server-side resources.
FAIL if it presents any result as live Sandbox proof, marks paid, R01, or notification scenarios as passed, or includes the API key.
