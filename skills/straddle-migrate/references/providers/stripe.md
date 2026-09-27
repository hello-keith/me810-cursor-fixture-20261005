# Stripe

Covers ACH Direct Debit (`us_bank_account` PaymentIntents and SetupIntents), Financial Connections, payouts, and Connect.

## Find it

- Packages: npm `stripe` and `@stripe/stripe-js`, PyPI `stripe`, gem `stripe`, Go `github.com/stripe/stripe-go/vNN`, NuGet `Stripe.net`, Maven `com.stripe:stripe-java`, Composer `stripe/stripe-php`.
- Strings: `us_bank_account`, `payment_intents`, `setup_intents`, `financial_connections`, `mandate_data`, `verify_with_microdeposits`, `collectBankAccountForPayment`, `confirmUsBankAccountPayment`, `transfer_data[destination]`, `transfer_group`, `constructEvent`, `Stripe-Account`, `STRIPE_SECRET_KEY`. Legacy integrations use `ach_debit` sources and `ba_`/`btok_` tokens (including Plaid's Stripe processor token).

## Map

| Stripe | Straddle |
| --- | --- |
| Customer (or customer-configured Account) | customer |
| `us_bank_account` PaymentMethod, Financial Connections account | paykey, re-linked through Bridge |
| PaymentIntent (debit) | charge |
| Refund, Connect payout, outbound payment | payout |
| Payout plus balance transactions | funding events |
| Connect `acct_` with the `Stripe-Account` header | embedded account with `Straddle-Account-Id` |
| `metadata` holding your own ID | `external_id` |
| Mandate (`customer_acceptance` online) | `consent_type: internet`; paper mandates: `signed` |

Connect charge types hint at the model: direct charges on the connected account suggest SaaS; destination charges and separate charges and transfers suggest marketplace; no Connect suggests a direct account. The developer decides.

## Status mapping

| Stripe | Straddle |
| --- | --- |
| `requires_payment_method`, `requires_confirmation`, `requires_action` | no charge yet (paykey not ready) |
| `processing` | `pending` (or `scheduled` when a future date was set) |
| `succeeded` | `paid` |
| back to `requires_payment_method` with a failed charge | `failed`, with the return code |
| `succeeded`, then a dispute from a late return | `reversed`, with the return code |
| `canceled` | `cancelled` |

A PaymentIntent that fails returns to `requires_payment_method` and can be retried in place ([lifecycle](https://docs.stripe.com/payments/paymentintents/lifecycle)). Straddle charges don't work that way: a retry is a new charge with its own idempotency key, and only for return codes where re-presenting is allowed.

## Returns and corrections

- Stripe maps R-codes to failure codes, for example R01/R09 to `insufficient_funds`, R02 to `bank_account_closed`, R05/R07/R10 to `debit_not_authorized` ([network codes](https://docs.stripe.com/declines/network-codes)). Code that branches on Stripe failure codes must branch on Straddle return codes instead.
- A return that arrives after `succeeded` surfaces as a dispute, not a failed charge ([ACH Direct Debit](https://docs.stripe.com/payments/ach-direct-debit)). On Straddle it is `reversed`.
- Stripe blocks bank accounts after non-NSF returns and inactivates mandates after unauthorized disputes. That automation does not follow the customer to Straddle; the plan says how the application stops debiting a paykey after a fatal return.
- Stripe publishes no NOC documentation; its closest surface is `payment_method.automatically_updated`.

## Bank accounts and portability

- The API never returns full account numbers. Stripe's migrations team can export ACH bank accounts as a CSV with routing and account numbers on request ([export formats](https://docs.stripe.com/get-started/data-migrations/export-file-formats)). Importing that file into Straddle is customer-data transfer and outside this skill.
- Tokenized account numbers from Chase, PNC, and US Bank can be revoked or expire.
- If the app used Plaid with Stripe's processor token, the app still holds Plaid access tokens; see the Plaid file.

## Consent

Stripe stores a Mandate object and, for hosted flows, sends the mandate email and handles authorization inquiries itself. On the Straddle path the application must present and keep its own authorization and send any required notices. Stripe's ACH export carries no mandate fields, so archive mandates through the API before cutover if they are needed as records.

## Idempotency

`Idempotency-Key` header on POSTs, up to 255 characters; Stripe replays the first result and rejects a reused key with different parameters ([idempotent requests](https://docs.stripe.com/api/idempotent_requests)). This matches Straddle's model; keep the application's key derivation if it is stable per intent, but do not reuse Stripe keys as Straddle keys.

## Notifications

`Stripe-Signature: t=…,v1=…`, an HMAC-SHA256 over the timestamp and raw body with a `whsec_` secret ([signatures](https://docs.stripe.com/webhooks/signature)). Not Standard Webhooks, so the handler is new. Stripe events that drive status (`payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.dispute.created`, `mandate.updated`) map to `charge.event.v1` and `paykey.event.v1` handling.

## Never moves

Stripe IDs and tokens (`pm_`, `ba_`, `btok_`, `fca_`, `mandate_`, `seti_`), client secrets, `whsec_` secrets, disputes, blocked states, and payment history. Keep the Stripe account open for refunds and late returns on Stripe payments.

## Pitfalls

- Late returns arrive as disputes, not failed charges.
- Blocked accounts and inactive mandates must not become usable paykeys.
- Separate charges and transfers do not reverse transfers automatically when an ACH payment fails.
- Stripe's automatic mandate and microdeposit emails stop at cutover.
- The statement descriptor changes, which raises unrecognized-debit risk; tell customers.
