# Plaid

Two different integrations hide behind "Plaid": **Auth/Link with a processor** (Plaid links the account, another company moves money) and **Plaid Transfer** (Plaid moves money). Establish which one the code uses first.

## Find it

- Packages: npm `plaid`, `react-plaid-link`; PyPI `plaid-python`; gem `plaid`; Go `github.com/plaid/plaid-go/vNN/plaid`; Maven `com.plaid:plaid-java`. There is no official NuGet package.
- Strings: `linkTokenCreate`, `itemPublicTokenExchange`, `processorTokenCreate`, `authGet`, `transferAuthorizationCreate`, `transferCreate`, `transferEventSync`, `TRANSFER_EVENTS_UPDATE`, `Plaid-Verification`, `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`, `cdn.plaid.com/link`.

## Auth/Link with a processor

- Plaid lists `straddle` as a processor for `/processor/token/create` ([processors](https://plaid.com/docs/api/processors/)), once the Straddle integration is enabled in the Plaid Dashboard ([Plaid and Straddle](https://plaid.com/docs/auth/partnerships/straddle/)). Straddle creates a paykey from that token with `POST /v1/bridge/plaid`.
- For **new** links the Straddle path keeps Plaid Link and requests a `straddle` processor token instead of (or beside) the old processor's token. That is additive code and in scope.
- For **existing** Items, the same access token can mint a `straddle` processor token without the customer re-linking. That uses stored customer data to create Straddle paykeys, so it is customer-data migration: this skill never implements it. Record it in the plan's Not moved section.
- Straddle uses Plaid Auth, Identity, and Balance. Items created before the switch may lack Identity consent.
- Revoking an Item with `/item/remove` kills every processor token minted from it, including Straddle's.

## Plaid Transfer

| Plaid Transfer | Straddle |
| --- | --- |
| `/transfer/authorization/create` then `/transfer/create`, `type: debit` | charge (no separate authorization step) |
| `type: credit`, refunds | payout |
| Ledger sweeps | funding events |
| Transfer for Platforms originator | embedded account; Plaid's platform product is SaaS-shaped |
| `idempotency_key` in the body; `/transfer/create` idempotent on `authorization_id` | `Idempotency-Key` header |

Status mapping ([reading transfers](https://plaid.com/docs/api/products/transfer/reading-transfers/)):

| Plaid Transfer | Straddle |
| --- | --- |
| `pending`, `posted` | `pending` |
| `settled` (credit) or `funds_available` (debit) | `paid` |
| `failed` | `failed` |
| `returned` | `failed` or `reversed` depending on whether the payment had reached `paid`, with the return code |
| `cancelled` | `cancelled` |

Plaid allows at most two retries, only for R01 and R09, marked with "Retry 1" and "Retry 2" descriptions; R10 can't be resubmitted. That convention does not port: a Straddle retry is a new charge. Plaid's Transfer docs describe no NOC object.

## Consent

Without Plaid's Transfer UI, the merchant already collects and keeps NACHA proof of authorization for at least two years. Whether that authorization must be re-collected for Straddle is a compliance decision; default proposal is a new authorization on the Straddle path.

## Notifications

`TRANSFER_EVENTS_UPDATE` carries no transfer ID; the app calls `/transfer/event/sync` with a cursor to read events ([reconciling transfers](https://plaid.com/docs/transfer/reconciling-transfers/)). Webhooks are verified with an ES256 JWT in `Plaid-Verification` that includes the body's SHA-256 ([webhook verification](https://plaid.com/docs/api/webhooks/webhook-verification/)). The Straddle handler is a new Standard Webhooks route; the event-sync cursor code has no Straddle equivalent beyond the polling endpoint's consumer offset.

## Never moves

Access tokens, link and public tokens, other processors' tokens, raw numbers and tokenized account numbers, and Plaid transfer, event, and sweep history. Refunds and late returns on Plaid Transfer payments stay on Plaid.

## Pitfalls

- Do not remove Items whose Straddle paykeys are live.
- Tokenized account numbers (Chase, PNC, US Bank) break when consent is revoked or expires; the next debit returns R04.
- Items from Database Auth and some micro-deposit flows have no live connection, so identity and balance checks may be weaker.
- Plaid Transfer amounts are decimal strings; Straddle amounts are integer cents.
