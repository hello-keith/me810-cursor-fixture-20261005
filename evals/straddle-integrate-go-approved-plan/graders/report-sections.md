---
type: llm
focus: { source: file, path: straddle-integration-report.md }
arm: with-only
---

PASS if the report lists the changed files (`dues/straddle_client.go`, `dues/payments.go`, `dues/straddle_test.go`) each with a one-line change, lists the operations wired with their SDK route and says no `Straddle-Account-Id` is sent for this direct integration, describes the webhook notification path, records no Sandbox write run, reports the repository test command with its result, lists the three planned Sandbox writes as not done because of the missing key or environment, makes clear in any wording that no Straddle request was sent (such as "Sandbox writes run: None", "not reached" or "no request was sent"), and gives a next step.
FAIL if it claims a Sandbox write ran, contains a key or token value, omits the changed files or the not-done writes, or edits or restates a different plan hash.
