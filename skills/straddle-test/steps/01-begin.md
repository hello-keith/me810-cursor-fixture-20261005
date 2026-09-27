# Step 1: Begin

- **Needs:** the developer's request, `straddle-integration-plan.md`, and the Integrate report when one exists.
- **Tools:** Read, Glob, Grep; Bash only for the configuration presence checks in Integrate's [step 1](../../straddle-integrate/steps/01-begin.md) and `straddle --version`. No writes, and no Straddle request.
- **Next:** [02-offline.md](02-offline.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"01-begin"}
```

Read [straddle-best-practices](../../straddle-best-practices/SKILL.md) and the plan. When there is no approved plan, or the repository has no Straddle integration code, print `STRADDLE_ABORT`, write the evidence file with status `blocked`, and hand off to Plan or Integrate.

Run the configuration presence checks from Integrate's step 1 and record **configured** or **configuration error** with exactly what is missing. Never print a value.

## Select scenarios

Take the scenarios from the plan's verification section, and confirm them with the developer when the plan is unclear. Only the plan's integration type and notification path apply.

| Scenario | Proves | Needs Sandbox writes |
| --- | --- | --- |
| Configuration | a missing key or environment fails before any request, with zero requests | no |
| Account scope | the header is present or omitted per operation for the integration type, and a missing required account fails locally with zero requests | no |
| A/B switching (SaaS, marketplace) | requests for accounts A and B each carry the right account, and header-omitted calls stay omitted | offline first, then Sandbox |
| Success | a charge or payout with `config.sandbox_outcome: paid` reaches `paid` | yes |
| Failure and return | a charge with `reversed_insufficient_funds` reaches `paid`, then `reversed` with return code `R01` | yes |
| Retry | repeating a create with the same idempotency key, or exact external-ID reuse, returns the same resource instead of a duplicate | yes |
| Onboarding (platforms) | the API-created account A or B is resolved by exact external ID or the notification path and used in an account-scoped payment. The form-created proof waits for Onboarding V2. | yes |
| Notification | every transition arrives through the selected webhook, FIFO, or polling endpoint, verified, persisted once, with a prompt `2xx` where deliveries arrive | yes |

A webhook receiver is not required: a polling endpoint is a complete notification path.

**Summary for step 2:** plan decisions, configuration result, acting accounts A and B, and the selected scenarios.
