---
type: llm
---

PASS if the reply shows a preview whose target is labelled as an offline synthetic localhost upstream (not Straddle Sandbox) with the exact base URL `http://127.0.0.1:45871`, lists the planned writes with the acting account or omitted header for each, the SDK method or CLI command that executes each (never the MCP execute-request), and idempotency keys or external IDs, asks for explicit approval, plans no API MCP verification reads, and says the result is offline proof, not live Sandbox proof.
FAIL if it runs or claims to run any write, treats the target as Straddle Sandbox or as live proof, routes any row through execute-request, or prints the API key.
