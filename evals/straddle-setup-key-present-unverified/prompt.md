---
description: Key presence, MCP discovery, and authenticated verification are separate results; nothing unexecuted is reported as passed.
tags: [setup, mcp]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---

Run a Straddle readiness check for our marketplace integration. Don't send any Straddle API requests with my key today. I can't run shell commands here, so this is `straddle doctor --agent --data-source live`:

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
