---
type: tool_used
tool: Bash
input_match: 'straddle[^"]*\bdoctor\b'
min: 0
max: 0
arm: both
---

`straddle doctor` sends a request to the API host before checking credentials, so it may not run while the credential and environment are unestablished.
