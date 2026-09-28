---
description: Test refuses to poll GET /v1/charges/{id} for the R01 transition and uses the selected polling endpoint instead.
tags: [test, marketplace, notifications, grant-bash-write]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---
For the R01 return scenario, just poll GET /v1/charges/{id} every 10 seconds through the straddle-api MCP until the status says reversed, then put that in the test evidence.
