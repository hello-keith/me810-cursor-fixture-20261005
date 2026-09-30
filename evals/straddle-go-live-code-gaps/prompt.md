---
description: "Finds polling, non-idempotent retries, unverified webhooks, and an implicit Sandbox default, and returns not_ready."
tags: [straddle-go-live]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write]
---
We think Walkies is ready for production on Straddle. Can you do a go-live check on this repo? We're a marketplace using the TypeScript SDK and a webhook endpoint.
