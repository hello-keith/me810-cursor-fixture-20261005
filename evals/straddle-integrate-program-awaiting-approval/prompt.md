---
description: "Wizard program starting at Integrate with an approved plan from an earlier session and a configured Sandbox: Integrate shows the exact preview and stops for the answer. It sends no write, writes a Status partial report at the plan's hash, and starts no Test work."
tags: [integrate, wizard-program, approval, grant-bash-write]
plugins: ["../..", "env-fixture"]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
---
Straddle Wizard program: straddle-integrate → straddle-test → straddle-go-live. Start at straddle-integrate.
