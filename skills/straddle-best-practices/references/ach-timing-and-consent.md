# ACH timing and consent

Every status, field, and value in backticks is checked against API contract 1.0.4 by `scripts/check-contract-tokens`. Facts marked "Observed in Sandbox" come from Sandbox runs, not from the contract or the docs. For details beyond this page, search the Docs MCP by concept, for example "same-day ACH", "consent types", "SEC codes", or "standing authorizations".

## What it is

Charges and payouts run on ACH (`payment_rail` `ach`, the only rail in API contract 1.0.4, although Straddle's docs also describe RTP and FedNow). ACH moves in batches on business days, so timing decides when a payment settles and how long a return can still arrive. Consent decides whether you may debit the account at all.

- **Payment date.** `payment_date` is a US Eastern calendar date. Today's Eastern date originates now, and a later date waits as `scheduled`. The rule and its UTC trap are in [Payment dates](writes-and-approval.md#payment-dates).
- **Consent.** Every charge says how the customer authorized it in `consent_type`: `internet` or `signed`. Payouts don't carry it.

## States and transitions

ACH windows, from Straddle's docs (US Eastern time):

| Window | Cut-off |
| --- | --- |
| Same-day ACH 1 | 9:00 AM |
| Same-day ACH 2 | 11:15 AM |
| Same-day ACH 3 | 2:15 PM |
| Standard, overnight | 7:00 PM |

Same-day ACH makes a payment effective the day it's sent, but its funding event still follows the account's `funding_time` ([funding-and-reconciliation.md](funding-and-reconciliation.md)). The contract has no field to choose a window.

How long each step takes:

- **Production:** Straddle funds in 24 hours, so a payment clears and the merchant is funded the next day. Returns run on their own clock after `paid`, from Straddle's docs: the customer's bank has two business days for most returns, and ACH debits stay reversible for up to 60 days, so `paid` → `reversed` can come weeks later.
- **Observed in Sandbox on 2026-09-30:** `created` → `scheduled` in about 5 seconds, `pending` about 50 seconds after creation, `paid` or `failed` about 2 minutes after creation, and a reversal about 5 minutes after `pending`. Sandbox processes simulated payments about once a minute. Never use these numbers as production timeouts.

Consent types and the ACH SEC codes they correspond to, from Straddle's docs:

| `consent_type` | When | SEC code |
| --- | --- | --- |
| `internet` | The customer authorized online or in your app, for example with a checkbox. | WEB (consumer debits) |
| `signed` | A signed agreement before the first payment, including e-signatures. | PPD for consumers, CCD for businesses |

Phone authorization (TEL) has no `consent_type` value. Ask Straddle before you take payments by phone. An account can use a consent type only when its capability is `active` (`internet` or `signed_agreement`, [platforms.md](platforms.md)).

For recurring charges, a standing authorization lets the customer approve future debits in advance. Nacha requires you to keep the authorization for two years after it ends, and to keep proof that the customer started each later payment when the authorization requires their action.

## What your app must handle

- Compute `payment_date` in US Eastern time, and show the customer when the debit happens.
- Show `pending` as "processing" and tell the customer the payment clears by tomorrow. Never promise same-day funds.
- Keep a charge's goods or access reversible until the dispute window has passed, when your risk allows.
- Set `consent_type` from how you really collected consent, and keep the evidence: the consent text, time, IP address (also sent as `device.ip_address`), and the customer's identity. It's what you upload as proof of authorization in a dispute ([returns-and-disputes.md](returns-and-disputes.md)).
- For subscriptions and saved bank accounts, store the standing authorization and its revocation, and stop debiting after an R07 (authorization revoked).

## Events and Sandbox outcomes

Timing shows up in the events you already handle: the `status_details.changed_at` of each `charge.event.v1` and `payout.event.v1`, and the `transfer_date` on funding events. Sandbox has no outcome for timing or consent: every `consent_type` behaves the same, and payments move on Sandbox's own schedule ([sandbox-outcomes.md](sandbox-outcomes.md)).
