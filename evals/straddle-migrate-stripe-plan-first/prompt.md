---
description: "Writes straddle-migration-plan.md listing every authorized additive change and stops for approval before any source edit."
tags: [straddle-migrate]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Migrate our Stripe ACH payments to Straddle. We're a direct account, use the TypeScript SDK, and we'll use a Straddle webhook endpoint. Put Straddle behind a feature flag.

Straddle is configured here: `straddle auth status --agent` reported `authenticated: true` (source `env:STRADDLE_API_KEY`), and `printenv STRADDLE_ENVIRONMENT` printed `sandbox`.
