# Dwolla

Covers the Dwolla Balance API. Dwolla Connect (payments through your own bank to External Parties) is a separate product with colon-style event topics; if the code uses `/external-parties`, treat it as closest to a Straddle direct account.

## Find it

- Packages: npm `dwolla` and legacy `dwolla-v2`, PyPI `dwollav2`, gem `dwolla_v2`, Composer `dwolla/dwolla-php`, NuGet `Dwolla.Client`. No Go SDK.
- Strings: `api.dwolla.com`, `api-sandbox.dwolla.com`, `application/vnd.dwolla.v1.hal+json`, `/funding-sources`, `/transfers`, `/mass-payments`, `/on-demand-authorizations`, `/exchanges`, `X-Request-Signature-SHA-256`, `X-Dwolla-Topic`, `DWOLLA_KEY`, `DWOLLA_SECRET`, `DWOLLA_WEBHOOK_SECRET`, `dwolla-web.js`.

## Map

| Dwolla | Straddle |
| --- | --- |
| Main Account and its bank | the Straddle account; settlement becomes funding events |
| Verified personal or business Customer | customer (individual or business) |
| Unverified and receive-only Customers | customer; Dwolla's lighter tiers have no direct analog |
| `correlationId` | `external_id` |
| Bank funding source | paykey, re-linked through Bridge |
| Transfer from a Customer's bank to the merchant | charge |
| Transfer from the merchant to a Customer's bank; mass payment item | payout, each with its own idempotency key |
| Customer-to-Customer transfer | charge plus payout (marketplace) |

Dwolla has no connected accounts and no account-selecting header. A merchant collecting from and paying its own Customers suggests a direct account; Customer-to-Customer flows suggest a marketplace.

## Status mapping

| Dwolla transfer | Straddle |
| --- | --- |
| `pending` | `pending` |
| `processed` | `paid` |
| `failed` before `processed` | `failed`, with the return code |
| `failed` after `processed` | `reversed`, with the return code |
| `cancelled` | `cancelled` |

Dwolla's integration guide says `processed` is not necessarily final: a processed transfer may later fail. Unauthorized returns (R05, R07, R10, R11) can arrive long after administrative ones ([transfer failures](https://developers.dwolla.com/docs/transfer-failures)). One bank-to-bank payment can be several linked Dwolla transfers through the Dwolla balance; Straddle has one charge or payout per movement.

## Returns and corrections

Return details come from the transfer's `failure` link. After returns Dwolla may unverify or remove the funding source and suspend or deactivate the Customer, each with its own webhook. Code listening for those reactions gets no trigger for Straddle-path payments. Dwolla has no NOC object; it applies corrections and fires `customer_funding_source_updated`.

## Bank accounts and portability

The funding-source API returns bank name and fingerprint but no account or routing numbers. Dwolla discards processor tokens after use. Apps that linked through their own Plaid account still hold Plaid access tokens (see the Plaid file); apps using Dwolla's Open Banking have no Plaid Item and customers must re-link.

## Consent

Dwolla's on-demand authorization text says future payments "will be processed by the Dwolla payment system" ([on-demand authorization](https://developers.dwolla.com/docs/api-reference/transfers/create-an-on-demand-transfer-authorization)), and Customers accepted Dwolla's terms. Those do not carry over; collect a new authorization on the Straddle path.

## Idempotency

`Idempotency-Key` header on POSTs; a repeat with the same key and body returns the original resource, keys last 24 hours ([idempotency key](https://developers.dwolla.com/docs/api-reference/api-fundamentals/idempotency-key)).

## Notifications

`X-Request-Signature-SHA-256` is a hex HMAC-SHA256 of the body with the subscription secret, no timestamp ([working with webhooks](https://developers.dwolla.com/docs/working-with-webhooks)). Payloads are thin (IDs and links), so handlers call back for the resource; Straddle events carry the full resource. Dwolla requires a webhook subscription in production, so the old handler has a direct counterpart in the new Straddle route.

## Never moves

Customer PII and KYC documents, funding sources, processor or exchange tokens, on-demand authorizations, terms acceptances, balances, and transfer and event history (Dwolla keeps events for 30 days; export them for your records beforehand).

## Pitfalls

- Stored HAL URLs used as identifiers.
- Duplicate per-party webhooks and linked transfer legs break one-to-one reconciliation.
- Dwolla balance, `clearing`, `fees`, RTP, FedNow, wire, and push-to-debit have no equivalent here; list them as not migrated.
- Drain Dwolla balances to the bank before customers move.
