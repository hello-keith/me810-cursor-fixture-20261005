# Provider mapping

Read this file, then the one file for the provider being migrated. Each provider file tells you how to find the provider's footprint in a repository, how its objects, statuses, returns, consent and notifications map to Straddle, what never moves, and where migrations usually go wrong. It maps concepts and mechanisms, not Straddle method names: read the installed Straddle SDK and the Docs MCP for exact calls.

Provider facts come from each provider's public documentation, researched on 2026-09-27. Docs change, so confirm a detail against the linked source before code depends on it. When a file says a provider has no feature, it means the feature was not documented in the sources reviewed, not that it cannot exist. Every mapping table is a proposal for the plan, and the developer confirms it. Rows marked "proposal" are the least certain, because the provider's model has no direct counterpart.

| Provider | File |
| --- | --- |
| Stripe | [providers/stripe.md](providers/stripe.md) |
| Plaid | [providers/plaid.md](providers/plaid.md) |
| Moov | [providers/moov.md](providers/moov.md) |
| Modern Treasury | [providers/modern-treasury.md](providers/modern-treasury.md) |
| Dwolla | [providers/dwolla.md](providers/dwolla.md) |
| Paya (Paya Connect, now Nuvei) | [providers/paya.md](providers/paya.md) |
| Payliance | [providers/payliance.md](providers/payliance.md) |
| Other (hand-rolled NACHA, another processor) | [providers/other.md](providers/other.md) |

## Straddle vocabulary to map onto

These come from the public Straddle API contract. Use them exactly; do not invent statuses.

- **Payment statuses** (charges and payouts): `created`, `scheduled`, `validating`, `pending`, `on_hold`, `paid`, `failed`, `cancelled`, `reversed`.
- **`failed` vs `reversed`.** A return before the payment reached `paid` is `failed`; a return after `paid` is `reversed`. The Sandbox outcomes follow the same split (`failed_insufficient_funds` vs `reversed_insufficient_funds`). Return details are in the payment's status details; read the contract for the exact field.
- **`consent_type`** on a charge: `internet` (online and mobile authorization) or `signed` (written or PDF-signed agreement). There is no telephone value, so a provider's TEL flows need a decision.
- **Objects:** customer; paykey (a bank account tokenized through Bridge: the widget, `POST /v1/bridge/bank_account`, `POST /v1/bridge/plaid`, or `POST /v1/bridge/quiltt`); charge (debit); payout (credit); funding event (settlement to the account's bank); organization and embedded account for platforms, selected with `Straddle-Account-Id`.
- **Creates** take an `Idempotency-Key` header and an `external_id`.
- **Notifications** use a Straddle webhook, FIFO, or polling endpoint, signed with Standard Webhooks, per [receiving-webhooks.md](../../straddle-best-practices/references/receiving-webhooks.md). Events include `charge.event.v1`, `payout.event.v1`, `paykey.event.v1`, `customer.event.v1`.

## What every provider migration has in common

1. **Bank accounts do not transfer.** This is a product rule, not a technical limit. Some providers can hand back full bank details (Plaid's `/auth/get` returns account and routing numbers, Stripe's migrations team exports them on request, Modern Treasury shows them when its data privacy controls are off), and Plaid Items can mint Straddle processor tokens. Using any stored bank details, tokens, or Items for existing customers is customer-data migration, which this skill never does. Provider tokens are also scoped to their provider. Customers on the Straddle path link again through Bridge.
2. **Consent needs a decision.** Most existing authorizations name the old provider or its payment system, or at least came with that provider's descriptor. The plan records whether Straddle-path customers re-authorize, which `consent_type` applies, and who confirmed it (typically the developer's compliance owner). Default proposal: collect a new authorization on the Straddle path.
3. **Statuses and returns must be mapped explicitly.** Every provider status the application reacts to maps to a Straddle status in the plan, including the late-return case (`reversed`) and notification-of-change handling.
4. **In-flight payments finish where they started.** Payments already submitted, scheduled, or future-dated on the old provider stay there; returns and refunds for them keep flowing through the old provider for weeks (unauthorized returns can arrive up to 60 days later).
5. **Webhook handlers are rewritten, not ported.** Each provider signs differently (or not at all). The Straddle handler is a new route using Standard Webhooks; the old handler stays for in-flight payments.
6. **Polling becomes a notification endpoint.** Several providers encourage or require status polling or report queries. On Straddle that becomes a webhook, FIFO, or polling endpoint consumer, never a loop on `GET /v1/charges/{id}`.
7. **Provider-side automation must not be assumed to carry over.** Automatic NOC corrections, account blocking after returns, and provider-sent customer emails belong to the old provider. For each one the application relies on, check what Straddle does from the Straddle docs and contract, and write the result in the plan: covered by Straddle (with the source), or an application responsibility with a named owner.
