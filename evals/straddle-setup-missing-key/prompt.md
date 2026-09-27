---
description: A missing API key is a blocking configuration failure even though doctor exits 0.
tags: [setup, configuration]
max_turns: 16
allowed_tools: [Read, Glob, Grep, Skill]
---

Check whether this project is ready for our Straddle SaaS integration. I can't run shell commands in this session, so here is the output of `straddle doctor --agent --data-source live`:

```json
{
  "api": "reachable (HTTP 404 at /)",
  "auth": "not configured",
  "auth_hint": "export STRADDLE_API_KEY=<your-key>",
  "auth_key_url": "https://dashboard.straddle.com",
  "base_url": "https://sandbox.straddle.com",
  "cache": {
    "hint": "Database not created yet; run 'straddle sync' to hydrate.",
    "status": "unknown"
  },
  "config": "ok",
  "env_vars": "ERROR missing required: STRADDLE_API_KEY",
  "runtime_context": {
    "acting_account": null,
    "environment": "https://sandbox.straddle.com",
    "integration_type": "saas"
  },
  "verify_mode": "normal operation"
}
```
