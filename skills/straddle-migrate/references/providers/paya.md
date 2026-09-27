# Paya (Paya Connect, now Nuvei)

Public documentation is thinner here than for the other providers; unknowns are marked.

## Find it

- There are no official SDK packages; integrations call REST directly or copy GitHub samples.
- Strings: `api.payaconnect.com`, `api.sandbox.payaconnect.com`, `/v2/transactions`, `/v2/accountvaults`, `/v2/contacts`, `/v2/postbackconfigs`, `developer-id`, `user-id`, `user-api-key`, `hash-key`, `ach_sec_code`, `product_transaction_id`, `account_vault_id`, `transaction_api_id`, `status_id`. Legacy Paya Services use SOAP (`ProcessSingleCheck`) or `api-cert.paya.com/ach/v1`.

## Map

| Paya Connect | Straddle |
| --- | --- |
| Contact | customer |
| `*_api_id` fields | `external_id` |
| ACH account vault | paykey, re-linked through Bridge |
| `action: debit` | charge |
| `action: credit`, `action: refund` | payout |
| `effective_date` | `payment_date` |
| `ach_sec_code` WEB | `consent_type: internet`; PPD and CCD written: `signed`; TEL and POP need a decision |
| Location (multi-location integrator) | embedded account (judgment: SaaS); a single merchant suggests a direct account |

## Status mapping

| Paya `status_id` | Straddle |
| --- | --- |
| 131 Pending Origination, 132 Originating, 133 Originated | `pending` |
| 134 Settled | `paid` |
| 136 Rejected, 301 Declined | `failed` |
| 201 Voided | `cancelled` |
| 331 Charged Back before 134 | `failed`, with the return code |
| 331 Charged Back after 134 | `reversed`, with the return code |
| 135 Reserved | undefined in Paya's docs; review manually |

Status codes are from Paya's transactions reference ([transactions](https://docs.payaconnect.com/developers/api/endpoints/transactions)). An HTTP success does not mean approval; the code checks `status_id`. Return reason IDs are numeric (2101 is R01); NOC reason codes exist (2201 and up) but Paya documents no NOC payload.

## Bank accounts and portability

Account vaults are scoped to Paya locations and show only the first six and last four digits; there is no documented vault export. Customers re-link through Bridge.

## Consent

Paya stores only the SEC code. The merchant keeps the authorization, and Paya's sample wording authorizes the merchant, not Paya. The processor's company ID changes with a new originator and some payer banks block unfamiliar IDs, so the plan records whether customers re-affirm and whether business payers must allowlist Straddle.

## Idempotency

There is no idempotency header. Paya's guidance after a timeout or server error is to check whether the request succeeded before retrying. On Straddle, every create sends an idempotency key.

## Notifications

Postbacks are form-encoded POSTs with a JSON string in `data`, authenticated only by optional Basic auth, with no documented signature ([postback configs](https://docs.payaconnect.com/developers/api/endpoints/postbackconfigs)). Integrations commonly poll transactions by status or run reports for chargebacks. On Straddle both become a signed notification endpoint.

## Never moves

Account vault tokens, credentials, postback configurations, transaction history, and in-flight transactions in statuses 131 to 133.

## Pitfalls

- Paya WEB partial refunds appear approved and are rejected days later; don't carry refund assumptions over.
- Credits need a separate CCD service in Paya; Straddle payouts don't.
- Carry forward any blocks the app keeps for accounts with fatal returns.
