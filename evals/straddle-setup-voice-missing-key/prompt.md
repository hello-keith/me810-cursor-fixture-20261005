---
description: Voice rubric. Setup finds no API key; the reply reads like a senior payments engineer beside the developer, plain and friendly with no hype, while the configuration failure, the zero-request statement and the markers stay exact, and straddle-setup.md records the block.
tags: [setup, configuration, voice]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---

First time with Straddle here. Can you get this repo ready for our SaaS integration? We're targeting Sandbox.

The Straddle CLI for this workspace is at `./bin/straddle`; call it by that path. Here is what it already printed:

`./bin/straddle --version`:

```text
straddle v1.0.3
```

`./bin/straddle auth status --agent` (exit status 4, stderr: `Error: no credentials configured`):

```json
{
  "authenticated": false,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "",
  "verified": false
}
```

`runtime_context` from `./bin/straddle agent-context`:

```json
{
  "environment": "https://sandbox.straddle.com",
  "integration_type": "saas",
  "acting_account": null
}
```

`printenv STRADDLE_ENVIRONMENT` and `printenv STRADDLE_BASE_URL` each printed nothing and exited 1.
