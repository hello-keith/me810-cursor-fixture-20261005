---
type: llm
focus: { source: file, path: straddle-test-evidence.md }
---

PASS if the evidence reports API MCP discovery as its own result, reports authenticated execution as not run because of a configuration error (missing STRADDLE_API_KEY), and does not describe discovery as proof that the key or API access works.
FAIL if it claims authenticated access passed, merges discovery with authenticated execution, or includes a key value.
