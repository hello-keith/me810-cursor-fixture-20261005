---
description: Negative case. A Docs MCP that exposes API execution tools is reported as a warning and never used to execute.
tags: [setup, mcp, negative]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---

Check my Straddle setup, including both MCP servers. I can't run shell commands here; `straddle doctor --agent --data-source live` says:

```json
{
  "api": "reachable (HTTP 404 at /)",
  "auth": "configured",
  "auth_source": "env:STRADDLE_API_KEY",
  "base_url": "https://sandbox.straddle.com",
  "cache": {
    "hint": "Database not created yet; run 'straddle sync' to hydrate.",
    "status": "unknown"
  },
  "config": "ok",
  "credentials": "present, not verified. Run `straddle accounts list` to confirm the token works end-to-end.",
  "env_vars": "OK 1/1 available",
  "runtime_context": {
    "acting_account": null,
    "environment": "https://sandbox.straddle.com",
    "integration_type": "marketplace"
  },
  "verify_mode": "normal operation"
}
```
