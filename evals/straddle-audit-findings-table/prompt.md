---
description: "Writes a findings table with file:line and confidence, triaged against the installed SDK source, without editing code."
tags: [straddle-audit]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Some walk payments never get marked paid, and last week we saw two duplicate charges for one walk. We're a marketplace on the TypeScript SDK. Audit our Straddle integration.
