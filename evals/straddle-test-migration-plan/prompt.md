---
description: "A finished additive migration with an approved straddle-migration-plan.md and no straddle-integration-plan.md: Test takes its scenarios from the migration plan's Verification section, runs the offline tests, and blocks only Sandbox scenarios on configuration."
tags: [test, direct, migration, configuration, grant-bash-write]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---
Our Stripe to Straddle migration is finished and reviewed, and straddle-migration-plan.md is approved. The migration report said to run straddle-test next to prove the new Straddle path, so please run it. We have not set the Sandbox key or environment in this shell.
