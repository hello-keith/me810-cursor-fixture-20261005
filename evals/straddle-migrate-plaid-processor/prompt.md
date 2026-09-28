---
description: "Plans a Plaid processor-token switch to Straddle for new links, keeps Link, and refuses to mint Straddle tokens from existing Items."
tags: [straddle-migrate]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
We use Plaid Link to connect tenants' bank accounts and hand the account to Dwolla with a processor token. Switch the bank-linking side to Straddle. We're a direct account, use the TypeScript SDK, and we'll use a Straddle webhook endpoint.
