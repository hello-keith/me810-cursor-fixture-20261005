---
description: Test with a declared synthetic localhost target labels evidence as offline proof and never records live Sandbox scenarios as passed.
tags: [test, marketplace, offline-target, offline-target-bash-write]
plugins: ["../..", "env-fixture"]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---
Run the Straddle test pass for our marketplace integration and record the evidence. STRADDLE_BASE_URL points at our synthetic local Straddle upstream at `http://127.0.0.1:45871` for an offline proof, and the API key in the environment is a synthetic test value, not a Straddle key.
