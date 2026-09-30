---
description: "Plans a Moov transfer migration with a full status mapping, the duplicate-key semantics change, and a polling endpoint instead of transfer polling."
tags: [straddle-migrate]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Move our Moov ACH collections to Straddle. We're a SaaS platform where each studio is its own account, we use the TypeScript SDK, and we want a Straddle polling endpoint because we can't expose a public URL.

Straddle is configured here: `straddle auth status --agent` reported `authenticated: true` (source `env:STRADDLE_API_KEY`), and `printenv STRADDLE_ENVIRONMENT` printed `sandbox`.
