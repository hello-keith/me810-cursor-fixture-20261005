# Step 2: Configuration

- **Needs:** step 1 summary.
- **Tools:** Read, Grep. Bash only for `command -v straddle`, `straddle --version`, `straddle auth status --json`, and `straddle agent-context`, which read local configuration and send nothing. `straddle doctor` is not allowed in this step because it sends a request to the API host before it looks at credentials. No MCP call.
- **Next:** [03-code.md](03-code.md), or [06-report.md](06-report.md) with status `blocked`.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-go-live","step":"02-configuration"}
```

Establish two facts offline, before any command or tool that can reach Straddle:

1. **Credential present.** Run `straddle auth status --json` and read `authenticated` and `source`. It covers a key in `STRADDLE_API_KEY` and a key saved in the CLI configuration, reports presence without the value, and sends no request (its `verified: false` means exactly that). `authenticated: false` is a missing credential. When the CLI is absent, or the key that matters lives in a deployment the CLI cannot see, ask the developer whether the key is configured there and record the answer as developer-confirmed, or `unknown` if they cannot say. Never read `.env*` files or the CLI config file to find out.
2. **Environment explicit.** The developer states Sandbox or production. `straddle agent-context` reports `runtime_context.environment`, the host the CLI resolves; it falls back to `https://sandbox.straddle.com` when nothing is configured, so it is a resolved default, not proof that anyone chose an environment. Use it only to confirm that the resolved host matches what the developer stated. The published CLI v1.0.2 does not report `runtime_context`; there the developer's statement is the only source. With no statement from the developer, the environment is unknown.

When the credential is missing or unknown, or the environment is unknown, print this line and skip every later check that could reach Straddle, including `straddle doctor`:

```text
Configuration error: <no Straddle credential is configured | credential presence is unknown | environment is not set explicitly>. No Straddle request was sent.
```

Only when both facts are established may a later step use `straddle doctor --agent` for connectivity; it sends a request to the resolved host. Code and dashboard checks in steps 3 and 5 still run without these facts, because they read files and ask the developer. The final status is `blocked` if the environment or credential cannot be established.

**Summary for step 3:** credential present, missing, or unknown and its source, environment and its source, resolved CLI host, CLI version.
