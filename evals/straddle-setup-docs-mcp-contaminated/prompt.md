---
description: Negative case. A Docs MCP that exposes API execution tools is reported as a warning and never used to execute.
tags: [setup, mcp, negative]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

Check my Straddle setup for our marketplace integration in Sandbox, including both MCP servers. I can't run shell commands here; this is what I ran locally:

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
