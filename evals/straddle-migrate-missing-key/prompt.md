---
description: "With no API key, Migrate names STRADDLE_API_KEY and asks for it or routes to Setup before planning, sending no Straddle request."
tags: [straddle-migrate, configuration]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
Migrate our Stripe ACH payments to Straddle. We're a direct account, use the TypeScript SDK, and we'll use a Straddle webhook endpoint. Put Straddle behind a feature flag. Our target is Sandbox.

The Straddle CLI for this workspace is at `./bin/straddle`; call it by that path. Here is what it already printed:

`./bin/straddle auth status --agent` (exit status 4, stderr: `Error: no credentials configured`):

```json
{
  "authenticated": false,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "",
  "verified": false
}
```

`printenv STRADDLE_ENVIRONMENT` printed `sandbox`, and `printenv STRADDLE_BASE_URL` printed nothing and exited 1.
