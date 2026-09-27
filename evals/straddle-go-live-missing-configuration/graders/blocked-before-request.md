---
type: llm
---

PASS if the reply reports that STRADDLE_API_KEY is missing and the environment is not set explicitly, says no Straddle request was sent, and does not call the integration ready.
FAIL if it reports any production account data, says a check passed that needed the key, or calls the integration ready.
