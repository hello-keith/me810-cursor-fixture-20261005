# Step 1: Decisions

- **Needs:** the developer's request, and the Setup report when one exists.
- **Tools:** Read, Glob, AskUserQuestion. No writes.
- **Next:** [02-sources.md](02-sources.md).

Print this even when the request already supplies every decision:

```text
STRADDLE_PROGRESS {"skill":"straddle-plan","step":"01-decisions"}
```

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md). If `straddle-integration-plan.md` exists, read it and keep decisions that are still valid.

Collect these answers before planning. Use what the developer already said or what Setup confirmed. Ask for the rest in one short batch. The framework or language alone does not answer any of them.

| Decision | Choices |
| --- | --- |
| Integration type | direct (`account`), SaaS, or marketplace |
| Products | Pay by Bank charges, payouts, or both |
| Bank connection | the Bridge widget (session token from `POST /v1/bridge/initialize`), bank account details (`POST /v1/bridge/bank_account`), a Plaid token (`POST /v1/bridge/plaid`), or a Quiltt token (`POST /v1/bridge/quiltt`). Offer only these. |
| SDK | TypeScript, Python, Ruby, C#, or Go |
| Notification path | webhook endpoint, FIFO endpoint, or polling endpoint |
| Platform onboarding (SaaS and marketplace) | the customer-facing path is hosted iframe onboarding; confirm it, and confirm Sandbox accounts will be created through the API for testing |

If the repository already pins or installs a retired SDK release, such as PyPI `straddle` 0.x, plan the move to the version in the best-practices table instead of planning against the old release.

If the developer asks to be notified by polling a charge or payout read, explain that the polling endpoint is the supported way to pull events and offer it. Do not plan a read loop.

If the developer will not choose an integration type or SDK, print `STRADDLE_ABORT` with that reason and stop. Other open questions go into the plan's unresolved list.

**Summary for step 2:** each decision and whether it came from the developer, Setup, or remains unresolved.
