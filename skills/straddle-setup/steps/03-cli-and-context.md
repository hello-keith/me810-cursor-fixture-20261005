# Step 3: CLI, key presence, and runtime context

- **Needs:** step 2 summary.
- **Tools:** Bash for the read-only commands below only. If you cannot run commands, ask the developer to run them and paste the output.
- **Next:** [04-mcp.md](04-mcp.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-setup","step":"03-cli-and-context"}
```

Run these, each only after confirming the previous one worked:

```bash
command -v straddle
straddle --version
straddle doctor --agent --data-source live
```

Do not run any other `straddle` command in this step. `doctor` sends one reachability request (`GET /`) to the configured base URL and calls no API operation.

## Read the doctor report

| Field | Meaning | Result |
| --- | --- | --- |
| `env_vars` starts with `ERROR missing required: STRADDLE_API_KEY`, or `auth` is `not configured` | No key in the environment or config. | **Blocking configuration failure.** `doctor` still exits 0, so do not use its exit code. |
| `credentials` is `present, not verified…` | A key exists. Nothing has proved it works. | Key present. Authenticated verification is still `not run`. |
| `api` is `unreachable…` | The configured host could not be reached. | Blocking. |
| `runtime_context.environment` | The resolved base URL. | Ready only when it is `https://sandbox.straddle.com`. Integration proofs run in Sandbox, so Production or any other host is blocking. |
| `runtime_context.environment` is `null`, or `runtime_context` is absent | No environment is selected, or the CLI predates the field. | **Blocking configuration failure** when null. When the field is absent, record the CLI as too old for context checks and ask the developer for the environment. |
| `runtime_context.integration_type` | `account` (direct), `saas`, or `marketplace`. | `null` is unknown. Ask the developer. Do not infer it from the code. |
| `runtime_context.acting_account` | The selected embedded account. | Needed for SaaS and marketplace charges and payouts. `null` on a platform is a warning for Setup and a blocker for Integrate. |
| `runtime_context.error` | The saved context is invalid. | Blocking. Quote the error. |

Never copy `auth_source`, `config_path`, or any token-like value into the report beyond saying where the key came from in general terms (environment or config).

## Optional authenticated check

Key presence is not verification. Offer the developer one read that proves the key works in the selected environment:

```bash
straddle accounts list --agent --data-source live
```

Run it only after the developer says yes. It is a permitted read that sends no `Straddle-Account-Id`. For a platform, its result also shows whether at least two Sandbox accounts exist for the A/B isolation fixture. If the developer declines, report authenticated verification as `not run`, never as passed.

**Summary for step 4:** CLI version, key presence, reachability, environment, integration type, acting account, authenticated check result (`passed`, `failed`, or `not run`), and Sandbox account count when known.
