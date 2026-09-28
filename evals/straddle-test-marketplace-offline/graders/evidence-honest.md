---
type: llm
focus: { source: file, path: straddle-test-evidence.md }
---

PASS if the evidence records the offline test results (including header omitted on customer calls, seller account on charges, A-to-B switching, and the missing-seller and missing-configuration cases with zero requests), marks the Sandbox scenarios (paid, R01 return, retry, notification) as not run with a reason such as missing configuration or approval, keeps API MCP discovery separate from authenticated execution, and does not claim Scalar enforces the excluded operations.
FAIL if it marks any Sandbox scenario passed, merges discovery with authenticated execution, or claims Scalar enforces the exclusions.
