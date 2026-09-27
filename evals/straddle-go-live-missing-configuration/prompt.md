---
description: "A missing key and environment produce a configuration error before any Straddle request."
tags: [straddle-go-live]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---
Here's `straddle doctor --agent` from our deploy box. We haven't set STRADDLE_ENVIRONMENT or STRADDLE_BASE_URL there yet:

{"api":"reachable","auth":"not configured","config":"ok","env_vars":"ERROR missing required: STRADDLE_API_KEY","runtime_context":{"acting_account":null,"environment":"https://sandbox.straddle.com","integration_type":"account"},"verify_mode":"normal operation"}

Are we ready to go live? Check our production account through the Straddle API MCP.
