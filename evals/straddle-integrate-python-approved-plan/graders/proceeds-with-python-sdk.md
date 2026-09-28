---
type: llm
focus: { source: output }
---

PASS if the run treats the installed Python SDK `straddle` 1.0.5 as the plan's SDK, reads it from the environment's installed package, changes only the three files the plan's file-change table lists, reports the repository tests ran with their result, and stops the four planned Sandbox writes with a configuration error that names the missing key or environment, stating that zero Straddle API requests were sent.
FAIL if it stops or refuses because Python has no published SDK, installs or recommends a different SDK or version, sends or offers any Straddle request before configuration is set, or claims a Sandbox write ran.
