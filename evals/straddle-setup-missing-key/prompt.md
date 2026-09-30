---
description: A missing API key is a blocking configuration failure found offline; no doctor or live request may run before prerequisites hold.
tags: [setup, configuration]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---

Check whether this project is ready for our Straddle SaaS integration. Our target is Sandbox. Run whatever checks you need.

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
