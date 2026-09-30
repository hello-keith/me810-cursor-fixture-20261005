# Receiving Straddle webhooks

Guidelines for writing, reviewing, or debugging code that consumes Straddle events from a webhook, FIFO, or polling endpoint. [Endpoint types](#endpoint-types) is the one full description of how each type delivers events and how to handle it; other skills link there. Load this reference whenever a Plan, Integrate, Test, Go Live, Migrate, or Audit step touches notification handling.

Adapted from the MIT-licensed `receiving-webhooks` skill in [svix/ai](https://github.com/svix/ai/blob/main/skills/receiving-webhooks/SKILL.md), rewritten for Straddle. The original license is in [`third-party-licenses.md`](third-party-licenses.md).

## How Straddle delivers events

A webhook is an HTTP POST from a source you don't control. Treat every request as untrusted until its signature is verified.

Straddle signs every webhook and FIFO delivery with the [Standard Webhooks](https://www.standardwebhooks.com) scheme. The two endpoint types send the same three values under different header prefixes, so a verifier must accept either:

| Concept | Webhook endpoint | FIFO endpoint | Purpose |
| --- | --- | --- | --- |
| Message ID | `webhook-id` | `svix-id` | Unique identifier for the delivery. Reuse it to drop duplicates. |
| Timestamp | `webhook-timestamp` | `svix-timestamp` | Send time, used for replay protection. |
| Signature | `webhook-signature` | `svix-signature` | Space-separated `v1,<signature>` entries. |

Each endpoint has its own signing secret, prefixed `whsec_`. It is not your API key. Read it from the environment on the server, never from a client bundle or source control.

Event payloads carry `event_type` (for example `charge.event.v1`), a unique `event_id`, `account_id` on platform deliveries (see [Routing events on a platform](#routing-events-on-a-platform) for direct accounts), and the full resource under `data`. The event catalog is the `webhooks` section of the Straddle API contract.

## Endpoint types

Straddle offers three endpoint types, all created in the Straddle dashboard. Choose one in the plan; never poll an ordinary API read to discover state changes.

### Webhook endpoint

One `POST` per event to your public HTTPS URL, signed with the `webhook-*` headers. Deliveries are independent and ordering is best effort. The rest of this reference, from [the non-negotiables](#the-non-negotiables) on, is the handler for this type: verify the raw body, persist, return `2xx` within seconds, and drop duplicates by `webhook-id` or `event_id`.

### FIFO endpoint

One `POST` per batch, in strict order, signed with the `svix-*` headers. The batch size is set per endpoint (default 100). A rejected batch is retried with growing backoff, and nothing newer is delivered until the oldest batch is accepted, so one rejected batch holds back every later status change while the backlog grows. A retried batch repeats events you may already have stored.

The body is whatever the endpoint's transformation returns. Svix hands the transformation `input.events`, the batch's `{payload, eventType}` objects in order, and sends the `requestBody` string it returns ([Svix FIFO endpoints](https://docs.svix.com/advanced-destinations/fifo-endpoints)). There is no universal wire shape: the receiver and the endpoint's transformation must agree. Before writing the parser, capture one real delivery or the dashboard's transformation test output. For example, the transformation configured on a Straddle SaaS Sandbox endpoint produced:

```json
{
  "data": [
    { "payload": { "event_id": "…", "event_type": "charge.event.v1", "account_id": "…", "data": { "id": "…", "status": "paid" } }, "eventType": "charge.event.v1" },
    { "payload": { "…": "…" }, "eventType": "payout.event.v1" }
  ]
}
```

Another endpoint's transformation can produce a different shape. The handler:

1. **Verifies the raw body** against the `svix-*` headers and the endpoint's signing secret before parsing or storing anything, as in [the non-negotiables](#the-non-negotiables).
2. **Stores every event in batch order**, reading each `payload` from where the transformation puts it.
3. **Drops duplicates by `event_id`**, so a retried batch stores nothing twice.
4. **Acknowledges all or nothing.** Return `2xx` only after the whole batch is committed. When any write fails, commit nothing and return `500`, so the batch is retried whole.

A handler that expects one event per request, or reads only `webhook-*` headers, rejects every batch and blocks the endpoint.

### Polling endpoint

Your code pulls events, so no public URL is needed. Use it when you cannot expose a public URL, for local development, or for batch processing. Read the endpoint's URL and token from server-side configuration.

The endpoint is a [Svix polling endpoint](https://docs.svix.com/advanced-destinations/polling-endpoints). Straddle's docs don't describe its wire format. The format below was observed on a Straddle SaaS Sandbox endpoint on 2026-09-30; items marked unconfirmed weren't observed there.

* **URL.** The dashboard gives a URL ending in `/consumer/{consumer_id}`. Replace that last segment with your consumer ID. The commit URL is the consumer URL plus `/commit`.
* **Auth.** `Authorization: Bearer <polling token>` on poll and commit. They aren't Straddle API calls, so they carry no API key and no `Straddle-Account-Id`.
* **Response.** `GET <consumer URL>` returns `{"data": [...], "done": <boolean>}`. Each item has an integer `offset`, plus `id`, `eventId`, `eventType`, `payload`, `channels` and `timestamp`. `payload` is the Straddle event (`event_id`, `event_type`, `account_id`, `data`). `done: false` means more events are waiting.
* **`starting_position`.** `starting_position=earliest` on a consumer with no committed offset started at offset 0. After a commit, a poll without the parameter resumed at the next offset. Svix's API also lists `latest`. Unconfirmed: `latest`, and where a new consumer starts when the parameter is omitted.
* **Lease.** A poll leases its batch to the consumer, and polls return `423 Locked` until that batch is committed. Svix says an uncommitted batch can be served again after the lease expires. Unconfirmed: how long the lease lasts.

The handler:

1. **Chooses its own consumer ID.** Each consumer keeps its own position. Give each independent reader its own ID, and never reuse another tool's.
2. **Expects a replay on a new consumer.** Observed in Sandbox, not a documented API contract: from `earliest`, a new consumer replayed the endpoint's whole retained history, for every account on the platform, not only this run's resources. The first batch of 50 in the observed run had 32 events from 3 other accounts. Route by `account_id` as [Routing events on a platform](#routing-events-on-a-platform) says, and project only events for resources your application created; store or skip the rest. Starting from `latest` or from a timestamp would avoid the replay, but neither has been tried on a Straddle endpoint.
3. **Stores every event in order**, dropping duplicates by `event_id`.
4. **Commits the last offset** after the batch is stored: `POST` `{"offset": N}`, where `N` is the last item's `offset`. It keeps polling while `done` is `false`.

A `423` means a missing commit, not a transient error to retry.

### Ordering status changes

Deliveries can arrive out of order ([Sandbox Pay by Bank troubleshooting](https://docs.straddle.com/guides/resources/sandbox-paybybank)). Order a resource's transitions by `data.status_details.changed_at`, the contract's time the status changed, not by arrival time or the `webhook-timestamp` or `svix-timestamp` header, which is the send time.

Two transitions can share a `changed_at`. Sandbox emitted `paid` and `reversed` for one charge with the identical value `04:13:41.3663282Z`. That was observed in Sandbox and is not a documented API contract, so handle a tie whether or not production produces one. On a tie, the event later in delivery order is the later transition: the higher polling offset, or the later position in a FIFO batch, with later batches after earlier ones. A webhook endpoint has no delivery order, so there a tie can't be settled from the deliveries. Keep both transitions in the history and don't infer an order from arrival.

When projecting status, an event whose `changed_at` is older than the current status's, or equal but earlier in delivery order, never replaces it. The same status can be delivered again under a new `event_id`, for example after a funding sweep (observed in Sandbox, not a documented API contract), and must change nothing.

## Routing events on a platform

Events delivered to a direct account arrived without `account_id` in Sandbox, where the account is implicit. That was observed in Sandbox and is not a documented API contract, so a direct account's handler must work whether or not the field is present. For a SaaS or marketplace platform, every event carries `account_id`, the embedded account the event belongs to. Route on that field. Do not infer the account from the endpoint URL, from the order events arrive in, or from IDs inside `data`. Reject an event that names an account your platform does not own.

## The non-negotiables

1. **Verify the signature on every request.** An unverified webhook is an anonymous internet POST. Anyone who learns your URL can forge events. Only act on payloads that pass verification.
2. **Verify against the raw request body.** The signature covers the exact bytes sent. Any framework that parses JSON and re-serializes it breaks verification. Read the unprocessed body.
3. **Return a `2xx` within seconds, but only after the event is safe.** A `2xx` tells Straddle the event is yours now; it will not be resent. Acknowledge only once the event is durably queued or its processing has been committed. Anything other than `2xx`, including `3xx` redirects, is treated as a failure and retried.
4. **Never treat a missing secret as "skip verification".** If the signing secret is not configured, fail the request with a configuration error. A handler that silently accepts unverified payments is worse than one that is down.

## Webhook handler shape

1. **Read the raw body.** Do not parse JSON before verification.
2. **Verify** with the selected Straddle SDK's webhook helper when it has one. Otherwise use the `standardwebhooks` library for your language. Pass the raw body, the three headers, and the endpoint's signing secret. When the helper reads only `webhook-*` names, copy a FIFO delivery's `svix-*` values onto them first. On failure return `400`.
3. **Persist, then acknowledge.** Write the verified event to a durable queue or table, or process it and commit, before responding. Only then return `2xx` (for example `204`). If the write fails, return `500` so Straddle retries. A `2xx` followed by a crash before persistence loses the event for good.
4. **Deduplicate.** Deliveries can repeat. Key the persisted record and your processing on `webhook-id` or the payload's `event_id` so a retry is a no-op.
5. **Branch on `event_type`** and process.

```ts
import { Webhook } from "standardwebhooks";

// rawBody must be the raw request body, not parsed JSON.
// secret is the endpoint's whsec_ signing secret from the environment.
if (!secret) {
  throw new Error("STRADDLE_WEBHOOK_SECRET is not configured");
}
const wh = new Webhook(secret);

let payload;
try {
  // Verifies the signature and the timestamp tolerance; throws on failure.
  payload = wh.verify(rawBody, req.headers);
} catch (err) {
  return res.status(400).send();
}

// payload is trusted. Make it durable before acknowledging.
try {
  await queue.enqueue({ id: req.headers["webhook-id"], payload });
} catch (err) {
  return res.status(500).send(); // not persisted; Straddle will retry
}
return res.status(204).send();
```

## Responding, retries, and auto-disable

* **Only `2xx` means success.** Every other code is treated as a failure and retried on a backoff schedule. Straddle's docs give eight attempts over about 27 hours: immediately, then after 5 seconds, 5 minutes, 30 minutes, 2 hours, 5 hours, 10 hours, and 10 hours.
* **Respond within the delivery timeout.** Keep the work before the response to verify, persist, respond. Everything slower runs from the queue after the `2xx`.
* **Use `4xx` to reject bad or forged requests** (failed verification returns `400`). Use `5xx` or timeouts only for transient failures you want retried.
* **Endpoints auto-disable after sustained failure.** Straddle's docs say an endpoint that fails for five consecutive days is disabled, and one success resets the clock. Keep the handler healthy and wire up failure notifications from the Straddle dashboard.
* **Replays come from the dashboard.** After an outage, resend one message or recover every failed message since a time from the endpoint's page. Replays are ordinary redeliveries, so deduplication handles them.
* **An IP allowlist is optional, never a substitute.** Straddle publishes the addresses webhooks come from; search the Docs MCP for the webhook IP allowlist instead of copying them, because they can change. Verify the signature either way.

## Manual verification (only when no library exists)

Prefer the SDK helper or `standardwebhooks`. If your language has neither, follow the scheme exactly and do not invent your own:

1. Strip the `whsec_` prefix from the secret and base64-decode the remainder to get the HMAC key.
2. Read `webhook-id`, `webhook-timestamp`, and `webhook-signature`, or their `svix-*` equivalents on a FIFO delivery.
3. Reject if the timestamp is more than five minutes from now.
4. Build the signed content as `{id}.{timestamp}.{body}` using the raw body bytes.
5. Compute HMAC-SHA256 of the signed content with the decoded key and base64-encode it.
6. Compare in constant time against each `v1,<sig>` entry in the signature header. Pass if any matches.

## Verification traps

* **Body parsed before verification.** Re-serialization changes the bytes. Use raw-body access.
* **Wrong secret.** Each endpoint has its own `whsec_` secret. Sandbox and production endpoints differ.
* **Secret in the wrong format.** Strip the prefix and base64-decode before use.
* **Replaying a captured payload with curl.** Verification rejects stale timestamps. Trigger a fresh delivery from the Straddle dashboard instead.
* **Reverse proxy stripping headers.** Confirm all three `webhook-*` or `svix-*` headers reach the handler.
* **Clock skew.** Unsynced server time fails the timestamp check.

## Checklist

* Signature verified on every request with the SDK helper or `standardwebhooks`
* Verification runs against the raw body
* Missing secret is a configuration error, never a bypass
* Failed verification returns `400`
* Event is durably queued or committed before the `2xx`; a failed write returns `500`
* Handler responds within the timeout; slow work runs from the queue afterwards
* Processing is idempotent on `webhook-id` or `event_id`
* Signing secret is server-side only
* FIFO: verification accepts the `svix-*` headers, and the parser matches the endpoint's transformation output from a captured delivery or the dashboard's transformation test
* FIFO: each request is parsed as a batch; every event is stored in order, duplicates are dropped by `event_id`, and `2xx` follows the whole batch's commit
* Polling: the last offset is committed after the batch is stored, and a `423` is treated as a missing commit
* Polling: events from other accounts or other applications' resources, replayed to a new consumer, are never projected onto yours
* Status is projected by `changed_at`, a tie goes to the later event in delivery order, and a re-delivered earlier status changes nothing
