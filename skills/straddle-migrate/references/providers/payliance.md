# Payliance

Public documentation consists of a developer page, API reference PDFs, and an OpenAPI file with no descriptions. Unknowns are marked.

## Find it

- There are no official SDKs. Unofficial clients exist (a PHP bundle, a .NET client).
- Strings: `api.payliance.com`, `staging.api.payliance.com`, `sandbox.api.payliance.com`, `transfer.payliance.com` (SFTP), `api/v1/echeck/`, `echecktoken/`, `tokenizeddebit`, `queryreturns`, `querysettlements`, `UniqueTranId`, `AuthorizationId`, `CheckAmount`, `SecCode`, `WebType`, `BankAccountId`, `ValidationCode`, `_Settle.csv`, `_Return.csv`.

## Map

| Payliance | Straddle |
| --- | --- |
| Name and address sent on each transaction | customer (Payliance has no ACH customer object) |
| `BankAccountId` token or raw routing and account | paykey, re-linked through Bridge |
| `echeck/debit`, `tokenizeddebit` | charge |
| `echeck/credit`, `tokenizedcredit` | payout |
| `refund` (full amount of the original debit) | payout (judgment) |
| `UniqueTranId` | `external_id`, and the source of a stable idempotency key |
| `FutureDate` | `payment_date` |
| `SecCode` WEB | `consent_type: internet`; PPD and CCD written: `signed`; TEL, check conversion, and RCC codes have no equivalent |
| Merchant location key | embedded account (judgment); one location suggests a direct account |
| `querysettlements`, settlement files | funding events |

## Status mapping

| Payliance `Status` | Straddle |
| --- | --- |
| 1 Invalidated | rejected at creation (no Straddle payment) or `failed` |
| 2 Pending | `scheduled` or `pending` |
| 4 Sent to bank | `pending` |
| 16 Settled | `paid` |
| 8 Returned | `failed`, with the return code |
| 24 Settled then Returned (late return) | `reversed`, with the return code |
| 32 Voided | `cancelled` |

Statuses are from Payliance's ACH API reference (linked from the [developer page](https://payliance.com/developers/)). Validation failures come back synchronously in `ValidationCode` inside an HTTP 200 with `successful: false`.

## Returns and corrections

`queryreturns` reports `ReturnReason` (the R-code) and a status distinguishing returns after settlement, returns before settlement, and NOCs; a NOC has a zero `ReturnAmount` and carries the corrected value in `Addenda`. Returns are final only after the morning cutoff Payliance documents. Payliance's own blocks (prior unauthorized or fatal returns) don't follow customers; export return history into the application's own blocklist if it relies on them.

## Bank accounts and portability

`BankAccountId` tokens only work at Payliance, transaction responses show the last four digits, and there is no documented export. Customers re-link through Bridge.

## Consent

Payliance stores the SEC code, web type, and authorization date. Its authorization templates name the merchant, not Payliance, and it states no retention period. The plan records the compliance decision on re-authorization.

## Idempotency

There is no idempotency header. `UniqueTranId` is required and a duplicate is rejected rather than replayed; the documented safe retry is `retrieve` by `UniqueTranId`. On Straddle, derive the idempotency key and external ID from the same stable ID.

## Notifications

Payliance has no webhooks. Integrations poll `retrieve`, `queryreturns`, `querysettlements`, or read SFTP return and settlement files. On Straddle all of that becomes a notification endpoint consumer; keep the old polling only for payments still on Payliance.

## Never moves

`BankAccountId` tokens, transaction history, prefunded balances, and Payliance's block lists.

## Pitfalls

- Void or let finish future-dated debits (up to 30 days out) before customers move, so nobody is debited twice.
- Amounts are decimal dollars; Straddle uses integer cents.
- SFTP batch and loan-management-system integrations may leave no code in the repository; ask the developer.
