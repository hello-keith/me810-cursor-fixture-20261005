# Step 4: Preview and approval

- **Needs:** summaries from steps 1 to 3, and the plan's future Sandbox writes table.
- **Tools:** Read; AskUserQuestion; Bash only for `straddle ... --dry-run --agent` and `--help`, and only when step 1 recorded **configured**. No live request.
- **Next:** [05-execute.md](05-execute.md) after an explicit yes. Otherwise [06-review.md](06-review.md), then the handoff with the status below.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-integrate","step":"04-preview"}
```

When the plan has no Sandbox writes, say so and go to step 6.

## Build the preview

List every intended write in execution order, including every organization and account to reuse or create, and every excluded read (unmask or reveal) the plan needs. Write exact values, not placeholders, except for IDs that only a previous create in this run can return. Name those by the row they come from.

```markdown
## Straddle Sandbox preview

- Environment: sandbox, https://sandbox.straddle.com (configured | configuration error: <what is missing>)
- Target: Straddle Sandbox | offline synthetic localhost (not Straddle Sandbox) <exact base URL>
- Integration type: <direct | saas | marketplace>
- Configuration: environment <explicit sandbox | unset | other>; credential per route: SDK `STRADDLE_API_KEY` <present | missing>, CLI `auth status` <env | saved | none>, API MCP <developer-confirmed | unknown>

| # | Operation | Executing tool | Acting account (Straddle-Account-Id) | Payload summary | External ID | Idempotency key | If it exists |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | POST /v1/organizations | SDK `client.organizations.create` | omitted (organization operation) | name | acme-kit-r1-org | org-acme-kit-r1-org | reuse exact match |
| 2 | POST /v1/accounts (A) | SDK `client.accounts.create` | omitted | organization_id = #1 data.id | acme-kit-r1-acct-a | acct-acme-kit-r1-acct-a | reuse exact match |

Account A/B test: <which rows run as A and which as B, and which rows must omit the header>.
Verification reads (no approval needed): <permitted API MCP or SDK reads, each run once>.
Not included: <writes the plan lists that this run will not make, and why>.
```

Rules for the table:

- **Executing tool.** Use the SDK method or CLI command from [execution-routes.md](../references/execution-routes.md), verified in step 2. The fourteen excluded operations always show the SDK or CLI, never `execute-request`, including when the developer asks for the MCP. Say why in one line.
- **Acting account.** Show the account ID and how it was resolved (Straddle ID or exact external ID), or `omitted` with the rule that omits it. Direct integrations never send it.
- **Idempotency key.** Write the key you will pass on every create. A CLI row is allowed only when the installed CLI lists `--idempotency-key` for that create. Otherwise the row uses the SDK. Never infer the key from `--dry-run` output, because the dry run does not print it.
- **Sandbox outcomes.** Include the `config.sandbox_outcome` values the plan tests, such as `verified`, `active`, `paid`, and `reversed_insufficient_funds`.
- **Payload.** Use synthetic, non-sensitive data. No real names, bank numbers, or keys.
- **Offline synthetic target.** When step 1 recorded one, write the exact localhost base URL in place of the Sandbox URL, and list no API MCP verification reads, per [offline-synthetic-target.md](../references/offline-synthetic-target.md). An approval covers that target only. Switching between it and Straddle Sandbox changes the target and needs a new preview.

When step 1 recorded **configured** and a row uses the CLI, run it with `--dry-run --agent` and show the result under the table. A dry run is not a substitute for the preview.

## Ask for approval

- When step 1 recorded a **configuration error**, show the preview and do not ask for approval. Say that no Straddle request will be sent until the named variables are set in the developer's own shell, then print `STRADDLE_ABORT` with `configuration error: <what is missing>` and continue at step 6, handing off with `blocked`.
- Otherwise ask one question: approve these exact rows, yes or no.

Only a yes given after this exact preview counts. These do not count:

- an approval given before the preview was shown, or a general "go ahead" in the original request
- an approval of an earlier preview whose environment, account, operation, payload, external ID, or idempotency key differs from this one, for example a charge approved for account A that the developer now wants for account B
- a yes to some rows, which covers only those rows. Rebuild the preview with just those rows and confirm it.

A no, a changed target or payload, or no answer means zero writes. On a no, print `STRADDLE_ABORT` with `developer denied the Sandbox preview`, continue at step 6, and hand off with `blocked`. On a change, rebuild the preview and ask again. Without an answer, continue at step 6 and hand off with `awaiting_approval`.

**Summary for step 5:** the approved rows exactly as shown, or the reason there is no approval.
