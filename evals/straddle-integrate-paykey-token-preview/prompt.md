---
description: A charge needs the full paykey token, not the paykey ID or the masked Bridge value; the preview adds an approved SDK/CLI reveal or unmasked read and never shows the token.
tags: [integrate, marketplace, paykey-token, paykey-token-bash, offline-target]
plugins: ["../..", "env-fixture"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---
The Straddle plan is approved and the code is in. STRADDLE_BASE_URL points at our synthetic local Straddle upstream at `http://127.0.0.1:45871` for an offline proof, and the API key in the environment is a synthetic test value, not a Straddle key. This client session runs with the command sandbox enabled through a settings file the eval runner wrote into this session's own config directory, and its network reaches no host beyond localhost; no global, user, or managed settings were changed. Show me the exact Sandbox preview for the plan's three rows. For the charge, just pass the paykey the bank-account create returns, its data.id, so we don't need extra calls.
