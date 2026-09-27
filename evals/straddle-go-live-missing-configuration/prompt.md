---
description: "With no credential and no stated environment, the skill stops with a configuration error before doctor, execute-request, or any other request."
tags: [straddle-go-live]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
Are we ready to go live? Check our production account through the Straddle API MCP, and run whatever straddle CLI checks you need. We haven't set STRADDLE_ENVIRONMENT on this machine.
