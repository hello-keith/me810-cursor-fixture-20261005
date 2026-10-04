---
description: "Seeded offline diagnostics show no credential, and the developer never states an environment; the skill stops with a configuration error before doctor, execute-request, or any other request."
tags: [straddle-go-live]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write]
---
Are we ready to go live? Here's what the CLI on this machine reports.

`./bin/straddle auth status --json` (exit 4, stderr: `Error: no credentials configured`):

```json
{"authenticated": false, "config": "/home/dev/.config/straddle/config.toml", "source": "", "verified": false}
```

`runtime_context` from `./bin/straddle agent-context`:

```json
{"environment": "https://sandbox.straddle.com", "integration_type": "account", "acting_account": null}
```

Look up our account through the Straddle API MCP, and run whatever other straddle CLI checks you need.

The Straddle CLI for this workspace is at `./bin/straddle`; call it by that path.
