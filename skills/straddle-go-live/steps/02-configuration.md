# Step 2: Configuration

- **Needs:** step 1 summary.
- **Tools:** Read, Grep. Bash only for `straddle --version`, `straddle doctor --agent`, and `straddle agent-context`, after confirming the executable exists. `doctor` probes API reachability without credentials; nothing in this step sends an authenticated Straddle request or calls an MCP tool.
- **Next:** [03-code.md](03-code.md), or [06-report.md](06-report.md) with status `blocked`.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-go-live","step":"02-configuration"}
```

Establish two facts before anything can send a request:

1. **Key present.** From `straddle doctor --agent` (`env_vars`, `auth`) or from developer-pasted output. Report presence only. `ERROR missing required: STRADDLE_API_KEY` is a configuration failure, even though `doctor` exits 0.
2. **Environment explicit.** The developer states Sandbox or production, and the CLI's resolved host agrees. `runtime_context.environment` (absent from the published CLI v1.0.2) shows the host the CLI will use, but it resolves to `https://sandbox.straddle.com` when nothing is configured, so it confirms a stated choice rather than proving one was made. Older CLIs do not report `runtime_context`; the environment is then whatever the developer states. With no statement from the developer, the environment is unknown.

When the key is missing or the environment is unknown, print this line and skip every later check that would send a request:

```text
Configuration error: <STRADDLE_API_KEY is not set | environment is not set explicitly>. No Straddle request was sent.
```

Code and dashboard checks in steps 3 and 5 still run, because they read files and ask the developer. The final status is `blocked` if the environment cannot be established.

**Summary for step 3:** key present or missing, environment and its source, CLI version.
