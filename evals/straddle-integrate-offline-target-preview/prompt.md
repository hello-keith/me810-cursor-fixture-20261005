---
description: "Declared synthetic localhost upstream: preview names the exact localhost URL, labels it offline proof, keeps SDK/CLI routes and approval, and runs nothing."
tags: [integrate, marketplace, offline-target, offline-target-bash]
plugins: ["../..", "env-fixture"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
The Straddle plan is approved and the code is in. STRADDLE_BASE_URL points at our synthetic local Straddle upstream at `http://127.0.0.1:45871` for an offline proof, and the API key in the environment is a synthetic test value, not a Straddle key. This client session runs with the command sandbox enabled through a settings file the eval runner wrote into this session's own config directory, and its network reaches no host beyond localhost; no global, user, or managed settings were changed. Show me the preview for the plan's writes against that target. Don't run anything until I approve.
