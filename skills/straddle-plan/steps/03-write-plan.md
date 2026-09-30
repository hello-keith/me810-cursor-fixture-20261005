# Step 3: Write the plan

- **Needs:** summaries from steps 1 and 2.
- **Tools:** Read, Write, Edit for `straddle-integration-plan.md` only.
- **Next:** [04-review.md](04-review.md).

Print this once, right after reading this file and before reading the template or any reference:

```text
STRADDLE_PROGRESS {"skill":"straddle-plan","step":"03-write-plan"}
```

Write `straddle-integration-plan.md` at the repository root from [plan-template.md](../references/plan-template.md). Replace every placeholder with evidence, a developer decision, or `Unresolved`. Keep the account scope, notification, Sandbox writes, verification, and approval sections even when short.

The plan must cover:

- **Product flow and operations.** Customer, Bridge and paykey, then charge or payout, with the SDK method and API operation for each, and the Sandbox outcomes to test (`config.sandbox_outcome`).
- **Account scope.** Per operation, whether `Straddle-Account-Id` is sent, required, or omitted for this integration type, citing [account-scope.md](../../straddle-best-practices/references/account-scope.md). For SaaS and marketplace, how the application selects and switches the acting account, and a test that fails locally with zero requests when a required account is missing.
- **Two-account proof (SaaS and marketplace).** Sandbox accounts A and B, a charge or payout for each, evidence that each result belongs to the right account, and evidence that header-omitted calls stayed omitted.
- **Onboarding (SaaS and marketplace).** Two separate items: fast Sandbox account creation through the API for testing, and hosted iframe onboarding with `env=sandbox` and a required `externalId` for the customer-facing flow.
- **Notifications.** The chosen webhook, FIFO, or polling endpoint, created in the dashboard, and its handler as [Endpoint types](../../straddle-best-practices/references/receiving-webhooks.md#endpoint-types) describes: verification, duplicate-safe storage, and acknowledgement or commit for that type. For FIFO, record the signature scheme as an open question until a captured delivery confirms it. Cite [notifications.md](../../straddle-best-practices/references/notifications.md) for the choice. No status loop on resource reads.
- **Future Sandbox writes.** A table of every remote write Integrate or Test will make, each naming its executing tool: the SDK method or CLI command, or a permitted MCP operation. The fourteen operations in [writes-and-approval.md](../../straddle-best-practices/references/writes-and-approval.md) always name the SDK or CLI. Each row lists the environment, account, idempotency key source, external ID, and that it needs a preview and approval. A CLI create row includes `--idempotency-key`, taken from that command's `--help` in the installed CLI; if the installed CLI does not list the flag, the row names the SDK method instead. `--idempotent` never stands in for a key. A charge or payout's `paykey` takes the full paykey token, so include the `revealPaykey` or `getUnmaskedPaykey` row that obtains it, and never write the token itself into the plan.
- **Files and tests.** Each change names an existing file or a justified new one, the behavior it adds, and the test that proves it. Existing provider code stays unless the developer separately approves a migration.
- **Verification commands** the developer can run.

**Summary for step 4:** the plan path and each section's status.
