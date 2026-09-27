---
description: Key presence, MCP discovery, and authenticated verification are separate results; nothing unexecuted is reported as passed.
tags: [setup, mcp]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---

Run a Straddle readiness check for our marketplace integration in Sandbox. Don't send any Straddle API requests with my key today. I can't run shell commands here; this is what I ran locally:

`straddle --version`:

```text
straddle v1.0.3
```

`straddle auth status --agent`:

```json
{
  "authenticated": true,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "env:STRADDLE_API_KEY",
  "verified": false
}
```

`runtime_context` from `straddle agent-context`:

```json
{
  "environment": "https://sandbox.straddle.com",
  "integration_type": "marketplace",
  "acting_account": null
}
```

`printenv STRADDLE_ENVIRONMENT`:

```text
sandbox
```

`printenv STRADDLE_BASE_URL`:

```text
(no output; exit status 1)
```
