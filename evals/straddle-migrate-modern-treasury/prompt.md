---
description: "Plans a Modern Treasury migration that splits debit and credit orders, replaces in-place redrafts, and takes over NOC handling."
tags: [straddle-migrate]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Replace our Modern Treasury payment orders with Straddle. We're a direct account, we use the TypeScript SDK, and we'll use a Straddle webhook endpoint.
