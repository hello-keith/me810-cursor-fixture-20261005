---
description: "Marketplace customer creation correctly omits the account header; the audit must dismiss that hypothesis, not report it."
tags: [straddle-audit]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Audit our marketplace Straddle integration. I'm worried we forgot the Straddle-Account-Id header when creating customers.
