---
description: "Seeded offline auth status shows no credential and no environment is stated; the optional Straddle read is skipped with a configuration error while the code audit still runs."
tags: [straddle-audit]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Charge 0f5c2a8e-7c1b-4b9e-9a37-3f1d2b6c8e10 has been stuck for two days. Look it up through the Straddle API MCP and audit why. This is what `./bin/straddle auth status --json` prints on this machine (exit 4, stderr: `Error: no credentials configured`):

```json
{"authenticated": false, "config": "/home/dev/.config/straddle/config.toml", "source": "", "verified": false}
```

The Straddle CLI for this workspace is at `./bin/straddle`; call it by that path.
