---
description: A missing API key is a blocking configuration failure found offline; no doctor or live request may run before prerequisites hold.
tags: [setup, configuration]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---

Check whether this project is ready for our Straddle SaaS integration in Sandbox. Run whatever checks you need. Here is what I already ran locally, with exit statuses:

`straddle --version`:

```text
straddle v1.0.3
```

`straddle auth status --agent` (exit status 4, stderr: `Error: no credentials configured`):

```json
{
  "authenticated": false,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "",
  "verified": false
}
```

`runtime_context` from `straddle agent-context`:

```json
{
  "environment": "https://sandbox.straddle.com",
  "integration_type": "saas",
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
