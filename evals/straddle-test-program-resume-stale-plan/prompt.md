---
description: "Resume from files alone, with no earlier chat: the migration plan was edited after its recorded approval, and the migration report is for the old hash. Test treats the plan as unapproved, writes blocked evidence with no plan hash, and starts no Go Live."
tags: [test, migration, wizard-program, resume, grant-bash-write]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---
Straddle Wizard program: straddle-migrate → straddle-test → straddle-go-live. Start at straddle-test.
