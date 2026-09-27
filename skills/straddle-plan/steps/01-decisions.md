# Step 1: Decisions

- **Needs:** the developer's request, and the Setup report when one exists.
- **Tools:** Read, Glob, AskUserQuestion. No writes.
- **Next:** [02-sources.md](02-sources.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-plan","step":"01-decisions"}
```

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md). If `straddle-integration-plan.md` exists, read it and keep decisions that are still valid.

Collect these answers before planning. Use what the developer already said or what Setup confirmed. Ask for the rest in one short batch. The framework or language alone does not answer any of them.

| Decision | Choices |
| --- | --- |
| Integration type | direct (`account`), SaaS, or marketplace |
| Products | Pay by Bank charges, payouts, or both; Bridge bank connection method |
| SDK | TypeScript, Ruby, C#, or Go. Python is not available until the Scalar Python SDK is published on PyPI. |
| Notification path | webhook endpoint, FIFO endpoint, or polling endpoint |
| Platform onboarding (SaaS and marketplace) | the customer-facing path is hosted iframe onboarding; confirm it, and confirm Sandbox accounts will be created through the API for testing |

If the developer asks for Python, say it is not published yet, and offer to plan with one of the four available SDKs or to stop. Do not plan `pip install straddle`, which installs the retired 0.5.0 package.

If the developer asks to be notified by polling a charge or payout read, explain that the polling endpoint is the supported way to pull events and offer it. Do not plan a read loop.

If the developer will not choose an integration type or SDK, print `STRADDLE_ABORT` with that reason and stop. Other open questions go into the plan's unresolved list.

**Summary for step 2:** each decision and whether it came from the developer, Setup, or remains unresolved.
