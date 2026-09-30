---
description: "Treats hand-rolled NACHA code as the Other provider, leaves undecided choices open, and plans without editing source."
tags: [straddle-migrate]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
We generate NACHA files ourselves and upload them to our bank over SFTP. Move us to Straddle.

Straddle is configured here: `straddle auth status --agent` reported `authenticated: true` (source `env:STRADDLE_API_KEY`), and `printenv STRADDLE_ENVIRONMENT` printed `sandbox`.
