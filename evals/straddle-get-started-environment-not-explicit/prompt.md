---
description: "With a key but no selected environment, Get Started names STRADDLE_ENVIRONMENT and asks for Sandbox or routes to Setup before anything else, sending no Straddle request."
tags: [straddle-get-started, configuration]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
I want to add bank payments with Straddle to this app. Where do I start? I'm not going to answer follow-up questions right now.

The Straddle CLI for this workspace is at `./bin/straddle`; call it by that path. Here is what it already printed:

`./bin/straddle auth status --agent`:

```json
{
  "authenticated": true,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "config",
  "verified": false
}
```

`printenv STRADDLE_ENVIRONMENT` and `printenv STRADDLE_BASE_URL` each printed nothing and exited 1.
