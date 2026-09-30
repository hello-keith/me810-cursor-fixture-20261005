---
type: llm
focus: { source: file, path: straddle-integration-report.md }
arm: with-only
---

PASS if the report lists the changed files (`dues/straddle_client.py`, `dues/payments.py`, `tests/test_straddle.py`) each with a one-line change, lists the operations wired with their SDK route and says no `Straddle-Account-Id` is sent for this direct integration, describes the webhook notification path, records no Sandbox write run, reports the repository test command with its result, lists the four planned Sandbox writes as not done because of the missing key or environment with zero Straddle API requests sent, and gives a next step.
FAIL if it claims a Sandbox write ran, contains a key or token value, omits the changed files or the not-done writes, or edits or restates a different plan hash.
