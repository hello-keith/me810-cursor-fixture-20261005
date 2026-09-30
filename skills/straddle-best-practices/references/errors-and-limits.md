# Errors and limits

Every status, field, and header in backticks is checked against API contract 1.0.4 by `scripts/check-contract-tokens`. Facts marked "Observed in Sandbox" come from Sandbox runs, not from the contract or the docs. For details beyond this page, search the Docs MCP by concept, for example "API errors", "request ID", or "capability requests".

## What it is

Two kinds of "no" come back from Straddle. An error response means Straddle didn't do what you asked. A limit or a risk decision means Straddle accepted the payment and then held or failed it, which you see as a status, not an error.

Every error uses the response envelope:

- `response_type` is `error`.
- `error` has `status` (the HTTP code), `type`, `title`, and `detail`, plus `items` for per-field problems, each with `reference` (the field) and `detail`.
- `meta` has `api_request_id` and `api_request_timestamp`.

Observed in Sandbox: a refund above the charge amount returned `422` with `type` `/validation_error`, `title` "Validation Failed", and one `items` entry whose `reference` was `amount`. Straddle's docs show a different error body, with `code`, `message`, and `type` fields. The contract and Sandbox agree, so parse the contract shape.

## States and transitions

What each HTTP status means and what to do, from the contract:

| Status | Meaning | Do |
| --- | --- | --- |
| `400` | The request is invalid. | Fix it, then send it with a new idempotency key: the rejected request used up its key ([Idempotency](writes-and-approval.md#idempotency)). |
| `401` | No valid API key. | Configuration error. Stop ([environments-and-credentials.md](environments-and-credentials.md)). |
| `403` | The key can't do this, or can't act for this account. | Check the account scope ([account-scope.md](account-scope.md)). |
| `404` | The resource doesn't exist, in this environment or account. | Check the ID, environment, and `Straddle-Account-Id`. |
| `409` | Conflicts with an earlier request, such as an idempotency key reused with a different body. | Don't retry blindly. Look up the earlier request's result. |
| `422` | Valid syntax, but Straddle can't do it now, such as holding a `pending` charge. | Show `detail`. Don't retry unchanged. |
| `429` | Too many requests. | Back off with jitter, then retry with the same idempotency key. |
| `500`, `502`, `503`, `504` | Server error. | Retry with the same idempotency key, or look up the `external_id`. |

The contract publishes no rate-limit numbers or rate-limit headers. Keep request rates modest, don't fan out reads, and use events instead of repeated reads ([notifications.md](notifications.md)).

Limits on money are account settings, which `getAccountSettings` returns. `settings.charges` and `settings.payouts` each have `max_amount` (one payment), `daily_amount`, `monthly_amount`, and `monthly_count`. Straddle sets them. A payment over a limit isn't rejected: it's created and then held `on_hold` with `reason` `amount_too_large` and `source` `watchtower`, and Straddle decides whether it proceeds. The Sandbox outcome `on_hold_daily_limit` simulates this. A platform raises an embedded account's limits with `createCapabilityRequest` ([platforms.md](platforms.md)). A direct account asks Straddle.

Tracing: send `Request-Id` (one request) and `Correlation-Id` (all requests in one operation, such as checkout) as headers. Every response's `meta.api_request_id` identifies the request on Straddle's side.

## What your app must handle

- Parse `error.detail` and `error.items` for the message, and map each item's `reference` onto the matching field in your form. Never show a raw error body to a customer.
- Branch on the HTTP status: fix and re-key after `400`, look up after `409`, stop on `401` and `403`, and retry only `429` and server errors, with the same idempotency key.
- Treat `on_hold` with `amount_too_large` as a limit, not a failure. Tell the customer the payment is under review, and check your limits in the account settings before you promise large amounts.
- Log `api_request_id`, `api_request_timestamp`, your `Request-Id` and `Correlation-Id`, the resource `id`, the environment, and the acting account for every failed request.
- When you contact Straddle support, send those values. Never send an API key, a signing secret, a paykey token, or unmasked data.

## Events and Sandbox outcomes

Errors produce no events: nothing was created or changed. Limit holds do: `charge.event.v1` or `payout.event.v1` with `on_hold` ([webhooks.md](webhooks.md)). In Sandbox, `on_hold_daily_limit` produces the hold, and requests that break the status windows produce `422` ([sandbox-outcomes.md](sandbox-outcomes.md)).
