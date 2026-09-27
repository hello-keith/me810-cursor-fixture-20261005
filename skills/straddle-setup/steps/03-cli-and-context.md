# Step 3: CLI, key presence, and runtime context

- **Needs:** step 2 summary.
- **Tools:** Bash for the read-only commands below only. If you cannot run commands, ask the developer to run them and paste the output.
- **Next:** [04-mcp.md](04-mcp.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-setup","step":"03-cli-and-context"}
```

## Command allowlist

These are the only commands Setup may run, in this order, each only after the previous one worked:

```bash
command -v straddle
straddle --version
straddle doctor --agent --data-source live
straddle accounts list --agent --data-source live   # only under "Optional authenticated check" below
```

Run nothing else. If `command -v straddle` finds nothing, skip the rest of this step and record the CLI as missing. `doctor` sends one reachability request (`GET /`) to the configured base URL and calls no API operation.

## Read the doctor report

| Field | Meaning | Result |
| --- | --- | --- |
| `env_vars` starts with `ERROR missing required: STRADDLE_API_KEY`, or `auth` is `not configured` | No key in the environment or config. | **Blocking configuration failure.** `doctor` still exits 0, so do not use its exit code. |
| `credentials` is `present, not verified…` | A key exists. Nothing has proved it works. | Key present. Authenticated verification is still `not run`. |
| `api` is `unreachable…` | The configured host could not be reached. | Blocking. |
| `runtime_context.environment`, or `base_url` when `runtime_context` is absent | The resolved base URL. | Sandbox only when it is `https://sandbox.straddle.com`. Integration proofs run in Sandbox, so Production or any other host is blocking. |
| `runtime_context.environment` is `null` | No environment is selected. | **Blocking configuration failure.** |
| `runtime_context` is absent | The CLI predates the field. | Warning: CLI too old for context checks. Take integration type and acting account from the developer and label them as developer-stated. |
| `runtime_context.integration_type` | `account` (direct), `saas`, or `marketplace`. | `null` is unknown. Ask the developer. Do not infer it from the code. |
| `runtime_context.acting_account` | The selected embedded account. | Required for SaaS customer, paykey, and Bridge creation, and for SaaS and marketplace charge and payout creation. `null` on a platform is a warning for Setup and a blocker for Integrate. |
| `runtime_context.error` | The saved context is invalid. | Blocking. Quote the error. |

Never copy `auth_source`, `config_path`, or any token-like value into the report beyond saying where the key came from in general terms (environment or config).

## Optional authenticated check

Key presence is not verification. The one CLI read that proves the key works is `straddle accounts list --agent --data-source live`. It is a permitted read that sends no `Straddle-Account-Id`.

Offer it only when every prerequisite holds:

- the CLI is present and `doctor` ran
- the key is present (`env_vars` is not an error and `auth` is `configured`)
- the environment is exactly `https://sandbox.straddle.com`
- `api` is reachable and `runtime_context.error` is absent

If any prerequisite fails, do not offer or run it, even if the developer asks. Report it as `not run (prerequisite failed: <which>)`. When the prerequisites hold, run it only after the developer says yes, and report `not run (declined)` otherwise. Never report it as passed unless it ran and returned accounts.

A 401 or 403 is `failed`, which is blocking. For a platform, a successful result also shows whether at least two Sandbox accounts exist for the A/B isolation fixture.

**Summary for step 4:** CLI version or missing, key presence, reachability, environment, integration type and its source, acting account, whether all authenticated-check prerequisites held, authenticated check result (`passed`, `failed`, or `not run` with reason), and Sandbox account count when known.
