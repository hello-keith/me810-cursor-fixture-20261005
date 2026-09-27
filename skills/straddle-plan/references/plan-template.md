# Straddle integration plan

## Status

- Plan state: Draft | Approved | Blocked
- Last reviewed:
- Repository and branch:
- Straddle skills version:
- API contract version: 1.0.4, or the version the installed SDK targets
- SDK package and exact installed version:

## Goal

The business outcome, who uses it, and the Straddle products in scope.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) / SaaS / marketplace | developer / Setup |
| Products | charges / payouts / both | |
| Bank connection | Bridge widget / Plaid / Quiltt / bank details | |
| SDK | TypeScript / Python / Ruby / C# / Go | |
| Notification path | webhook endpoint / FIFO endpoint / polling endpoint | |
| Customer-facing onboarding (platforms) | hosted iframe | |

## Repository evidence

- Language, framework, package manager:
- Test command:
- Existing payment or bank-linking providers to keep:
- Entry points where Straddle calls belong:
- Existing tests to extend:

## Application flow

Numbered, using the installed SDK's method names with their source file. Remove steps that do not apply.

1. Create or reuse the customer by external ID.
2. Connect a bank account through Bridge and receive a paykey.
3. Create the charge or payout with consent, payment date, external ID, and idempotency key.
4. Receive status changes through the chosen notification path.
5. Reconcile from delivered events.

## Account scope

| Operation | Header for this integration type | Source |
| --- | --- | --- |
| | sent / required / omitted | best-practices account-scope reference |

- How the application selects the acting account:
- How it switches between accounts:
- Missing required account: fails locally with a configuration error and zero requests, proved by:

## Two-account proof (SaaS and marketplace)

- Sandbox account A (external ID):
- Sandbox account B (external ID):
- Charge or payout for each, with the evidence that proves the account on each result:
- Header-omitted operations verified omitted:

## Onboarding (SaaS and marketplace)

- Sandbox testing: accounts created through the API after preview and approval.
- Customer-facing: hosted iframe with `env=sandbox` and a required `externalId`; account resolved through the notification path or an exact external-ID lookup.

## Notifications

- Endpoint type and events subscribed:
- Signature verification helper and raw-body access:
- Duplicate handling (event ID storage):
- Prompt `2xx`, or for a polling endpoint, consumer ID and offset storage:
- Status transitions to record, including `paid` before `reversed` with `R01`:

## Configuration

- `STRADDLE_API_KEY` read from the process environment; a missing key or environment raises a configuration error before any request.
- Environment: Sandbox (`https://sandbox.straddle.com`).

## File changes

| File | Existing or new | Change | Behavior proved | Test |
| --- | --- | --- | --- | --- |
| | | | | |

## Future Sandbox writes

Each row runs later, in Integrate or Test, only after its own preview and approval.

| Order | Operation | Executing tool | Account | External ID | Idempotency key source |
| --- | --- | --- | --- | --- | --- |
| | | SDK method / CLI command / permitted MCP operation | | | |

## Verification

- Repository tests:
- Sandbox success outcome:
- Sandbox failure or return outcome:
- Retry with the same idempotency key:
- Two-account proof:
- Notification proof (one signed event received, duplicate ignored):

## Unresolved decisions

- None yet.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- Existing provider code stays unless a separate migration plan authorizes it.
- Every Sandbox write needs its own preview and approval at the time it runs.
- The fourteen excluded operations run only through the SDK or the Straddle CLI.
