# Modern Treasury

## Find it

- Packages: npm `modern-treasury`, PyPI `modern-treasury` (import `modern_treasury`), gem `modern_treasury`, Go `github.com/Modern-Treasury/modern-treasury-go/v2`, Maven `com.moderntreasury:modern-treasury-java`. No NuGet package.
- Strings: `app.moderntreasury.com/api`, `paymentOrders.create`, `/api/payment_orders`, `/api/counterparties`, `/api/external_accounts`, `/api/returns`, `originating_account_id`, `receiving_account_id`, `plaid_processor_token`, `X-Signature`, `X-Webhook-ID`, `MODERN_TREASURY_API_KEY`, `MODERN_TREASURY_ORGANIZATION_ID`, `MODERN_TREASURY_WEBHOOK_KEY`.

## Map

| Modern Treasury | Straddle |
| --- | --- |
| Counterparty (plus legal entity) | customer with `external_id` |
| External account | paykey, re-linked through Bridge |
| Payment order, `direction: debit` | charge |
| Payment order, `direction: credit` to an external account | payout |
| `effective_date` | `payment_date` |
| `subtype` WEB | `consent_type: internet`; PPD and CCD with a written agreement: `signed`; TEL needs a decision |
| Internal account per customer or legal entity | embedded account (judgment: SaaS when each customer is the merchant, marketplace when the platform is) |
| Bank transactions and balance reports | funding events |

One `direction` field splits into two Straddle operations with different account-scope rules; the plan lists both.

## Status mapping

| Modern Treasury payment order | Straddle |
| --- | --- |
| `needs_approval`, `approved` | no Straddle equivalent; approval stays in the application before the charge is created |
| `processing`, `sent` | `pending` |
| `completed` | `paid` |
| `failed` | `failed` |
| `returned` before completion | `failed`, with the return code |
| `returned` after completion | `reversed`, with the return code |
| `denied`, `cancelled` | `cancelled` |
| `held` | `on_hold` (judgment) |
| `reversed` | no equivalent: Modern Treasury's `reversed` is an originator-initiated NACHA reversal, not a return |

Modern Treasury redrafts a returned order by updating the same order back to `needs_approval` ([update payment order](https://docs.moderntreasury.com/platform/reference/update-payment-order)), so one ID can carry several attempts. On Straddle each attempt is a new charge with its own idempotency key and external ID.

## Returns and corrections

- Returns are separate `return` objects with the R-code, linked to the payment order.
- A NOC arrives as a zero-amount return with `type: ach_noc`, and Modern Treasury updates the external account automatically ([NOC](https://docs.moderntreasury.com/payments/docs/notification-of-change-noc)). That automatic correction stops for Straddle-path payments; the plan says how corrections are handled.

## Bank accounts and portability

Verification is optional in Modern Treasury: unverified external accounts can be debited. Straddle requires a paykey. Full account numbers are hidden unless the organization turned off its data privacy controls, and Plaid processor tokens minted for Modern Treasury are bound to it. Customers re-link through Bridge.

## Consent

Modern Treasury has no mandate object; the merchant holds the debit authorization. For its own payments product it records acceptance of Modern Treasury's terms, which don't carry over. Authorizations that name the merchant and still match the terms may be reusable; the plan records the compliance decision.

## Idempotency

`Idempotency-Key` on POST and PATCH, up to 180 characters, scoped to the API key rather than the route, results kept for 24 hours ([idempotent requests](https://docs.moderntreasury.com/platform/reference/idempotent-requests)). The Node SDK generates a key when the app doesn't pass one, which can hide that the app never set its own; the Straddle path must derive keys from the payment intent.

## Notifications

`X-Signature` is a hex HMAC-SHA256 of the body with the webhook key, and there is no signed timestamp ([verifying webhooks](https://docs.moderntreasury.com/platform/docs/verifying-webhooks)). Events arrive in no guaranteed order. Modern Treasury's docs also allow polling payment status; on Straddle that becomes a notification endpoint.

## Never moves

Modern Treasury IDs, Plaid processor tokens, raw account numbers, legal-entity and KYC data, terms acceptances, payment, return, and NOC history, ledgers, expected payments, and approval rules.

## Pitfalls

- Debits on unverified accounts have no Straddle equivalent.
- Edits to protected payment-order fields fail silently with a success response; don't carry that assumption over.
- Modern Treasury ledgers are not replaced by Straddle; if the app posts ledger entries, the Straddle path needs its own reconciliation from Straddle events.
