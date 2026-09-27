---
type: llm
focus: { source: file, path: straddle-integration-plan.md }
---

PASS if the plan records the supplied decisions (direct integration, charges only, Python SDK, webhook endpoint), names PyPI `straddle` 1.0.5 as the SDK version, identifies the existing `straddle==0.5.0` pin in requirements.txt as a retired release to replace, and lists the bank connection method as unresolved rather than choosing one.
FAIL if the plan calls the Python SDK unavailable or uses another language because of it, keeps or plans against `straddle==0.5.0`, leaves the old pin unmentioned, picks a bank connection method the developer did not choose, or contradicts a supplied decision.
