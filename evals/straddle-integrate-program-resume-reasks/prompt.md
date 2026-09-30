---
description: "The Wizard reopens a session whose history holds Integrate's Sandbox preview, the developer's yes, and a customer create interrupted before it finished. The reopen message says earlier approvals don't count, so Integrate shows the same preview again (same external ID and idempotency key), asks, sends nothing, writes a Status partial report at the plan's hash, and starts no Test work."
tags: [integrate, wizard-program, approval, resume, grant-bash-write]
plugins: ["../..", "env-fixture"]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
---
Straddle Wizard program: straddle-integrate → straddle-test → straddle-go-live. Start at straddle-integrate.
Run the listed steps in order in this one session: after each step's STRADDLE_HANDOFF, continue with the next listed step without waiting for the Wizard; stop and ask whenever a step needs the developer (plan approval, each Sandbox write).
This session was reopened by the Straddle Wizard. Approvals given before this message don't count: show every Sandbox write preview again and ask; a plan approval counts only as recorded in the plan file.
