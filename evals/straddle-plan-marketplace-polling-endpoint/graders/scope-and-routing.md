---
type: llm
focus: { source: file, path: straddle-integration-plan.md }
---

PASS if the plan says customer, paykey, and Bridge calls omit Straddle-Account-Id for this marketplace, charges require the selected seller account, customer and paykey and charge creation are executed through the SDK or Straddle CLI with preview and approval (not the MCP execute-request), and status arrives through the polling endpoint rather than repeated charge reads.
FAIL if any of these is contradicted, if the plan loops on GET /v1/charges/{id} or a list endpoint for status, or if it plans execute-request for any create.
