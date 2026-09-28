# Moov

## Find it

- Packages: npm `@moovio/sdk` (legacy `@moovio/node`, browser `@moovio/moov-js`), PyPI `moovio_sdk`, gem `moov_ruby`, Go `github.com/moovfinancial/moov-go`, NuGet `Moov.Sdk`, Maven `io.moov:sdk`, Composer `moov/moov-php`.
- Strings: `api.moov.io`, `X-Moov-Version`, `/accounts/{accountID}/transfers`, `paymentMethodID`, `ach-debit-collect`, `ach-credit-standard`, `achDetails`, `X-Wait-For`, `X-Nonce`, `transfer.updated`, `MOOV_PUBLIC_KEY`, `MOOV_SECRET_KEY`.

## Map

| Moov | Straddle |
| --- | --- |
| Individual or business account (payer or payee) with `foreignID` | customer with `external_id` |
| Partner account | platform organization (or the direct account) |
| Merchant account with collect or send capabilities | embedded account |
| Bank account and its `ach-*` payment methods | one paykey (Moov splits one bank account into several payment methods; Straddle does not) |
| Transfer with an `ach-debit-collect` source | charge |
| Transfer to an `ach-credit-*` destination | payout |
| Wallet sweeps | funding events |

Moov wallets have no Straddle equivalent. Transfer groups (payer to platform to provider) suggest a marketplace; a partner processing for itself suggests a direct account.

## Status mapping

| Moov transfer | Straddle |
| --- | --- |
| `created` | `created` |
| `queued` | `scheduled` (proposal) |
| `pending` | `pending` |
| `completed` | `paid` |
| `failed` | `failed`, with the return code |
| `reversed` | `reversed`, with the return code |
| `canceled` | `cancelled` |

Moov marks a return during clearing as `failed` and a return after funds moved as `reversed` ([returns](https://docs.moov.io/guides/money-movement/accept-payments/ach/returns)), the same split Straddle uses. The Moov docs reviewed describe no automatic redraft; a Moov retry is a new transfer. On Straddle, a retry creates a new Straddle charge, either through resubmit (`POST /v1/charges/{id}/resubmit`, which copies a failed, reversed, or cancelled charge and takes an idempotency key) or a fresh create.

## Returns and corrections

Moov reports returns in `achDetails.return` and NOCs in `achDetails.correction`. It applies NOCs to the bank account itself and moves bank accounts to `errored` or `verificationFailed` after certain return codes. Don't assume that behavior carries over: the plan records what Straddle does with corrections and fatal returns (with the source) and what the application must handle.

## Bank accounts and portability

The API exposes only the last four digits of account numbers. Moov documents an import process onto Moov but no export. Moov-scoped Plaid and MX tokens can't be reused; customers re-link through Bridge.

## Consent

The Moov docs reviewed describe no debit mandate object. Its re-authorization attestation says the account holder authorizes Moov to originate debits, and payers see Moov on statements. Existing authorizations therefore name Moov; propose a new authorization on the Straddle path.

## Idempotency

`X-Idempotency-Key` is required on transfer creation, and a duplicate key is rejected rather than replayed ([create transfer](https://docs.moov.io/api/money-movement/transfers/create/)). Code that treats that rejection as "already created" must change, because Straddle replays the original result for a repeated key.

## Notifications

Moov signs `X-Timestamp`, `X-Nonce`, and `X-Webhook-ID` with HMAC-SHA512 into `X-Signature` ([webhook signatures](https://docs.moov.io/guides/webhooks/check-webhook-signatures/)); the body itself is not signed. Moov payloads are thin (IDs and status) and integrations often call `X-Wait-For: rail-response` or poll the transfer. On Straddle, drop the polling and handle signed events whose body carries the full resource.

## Never moves

Moov IDs, payment method IDs, Moov-scoped tokens, terms-of-service tokens, attestations, schedules, wallet balances, and transfer history.

## Pitfalls

- Moov's API version defaults to an old version when `X-Moov-Version` is unset; the existing code's behavior may reflect that default.
- Moov's wallet-based return accounting doesn't map one-to-one onto the Straddle objects above. Plan the accounting explicitly.
- Moov's test-mode trigger amounts don't apply to Straddle; use Straddle `sandbox_outcome` values.
