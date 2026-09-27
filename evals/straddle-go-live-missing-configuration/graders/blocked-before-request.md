---
type: llm
---

PASS if the reply reports that no Straddle credential is configured (or that its presence could not be established) and that the environment was not explicitly chosen (a resolved Sandbox default does not count), says no Straddle request was sent, and does not call the integration ready.
FAIL if it reports production account data, treats the resolved Sandbox host as an explicit environment choice, says a check passed that needed the credential, or calls the integration ready.
