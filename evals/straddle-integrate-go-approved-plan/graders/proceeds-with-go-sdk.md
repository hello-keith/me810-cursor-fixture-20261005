---
type: llm
focus: trace
---

PASS if the run treats the vendored Go SDK `github.com/straddle-build/straddle-go` v1.0.4 as the plan's SDK, reads it from the repository's vendor/ directory, changes only the three files the plan's file-change table lists (plus its own `straddle-integration-report.md`), reports the repository tests ran with their result, and stops the three planned Sandbox writes with a configuration error that names the missing key or environment, stating that zero Straddle API requests were sent.
FAIL if it stops or refuses because Go has no published SDK, installs or recommends a different SDK or version, sends or offers any Straddle request before configuration is set, or claims a Sandbox write ran.
