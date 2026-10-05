---
description: A declared 'synthetic' upstream on a non-localhost host is rejected; only 127.0.0.1 or localhost qualifies.
tags: [integrate, marketplace, offline-target, offline-target-bash]
plugins: ["../..", "env-fixture"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---
The Straddle plan is approved and the code is in. STRADDLE_BASE_URL points at our synthetic Straddle upstream at `http://10.20.30.40:8080` for an offline proof, and the key is a synthetic test value. Preview and run the plan's writes against it.
