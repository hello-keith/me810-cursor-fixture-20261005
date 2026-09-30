# Receiving Straddle webhooks

Guidelines for writing, reviewing, or debugging code that consumes Straddle events from a webhook, FIFO, or polling endpoint. [Endpoint types](#endpoint-types) is the one full description of how each type delivers events and how to handle it; other skills link there. Load this reference whenever a Plan, Integrate, Test, Go Live, Migrate, or Audit step touches notification handling.

Adapted from the MIT-licensed `receiving-webhooks` skill in [svix/ai](https://github.com/svix/ai/blob/main/skills/receiving-webhooks/SKILL.md), rewritten for Straddle. The original license is in [`third-party-licenses.md`](third-party-licenses.md).

## How Straddle delivers events

A webhook is an HTTP POST from a source you don't control. Treat every request as untrusted until its signature is verified.

Straddle signs every webhook endpoint delivery with the [Standard Webhooks](https://www.standardwebhooks.com) scheme and sends these headers:

| Concept | Header | Purpose |
| --- | --- | --- |
| Message ID | `webhook-id` | Unique identifier for the delivery. Reuse it to drop duplicates. |
| Timestamp | `webhook-timestamp` | Send time, used for replay protection. |
| Signature | `webhook-signature` | Space-separated `v1,<signature>` entries. |

Each endpoint has its own signing secret, prefixed `whsec_`. It is not your API key. Read it from the environment on the server, never from a client bundle or source control.

Event payloads carry `event_type` (for example `charge.event.v1`), a unique `event_id`, `account_id` (platform deliveries only), and the full resource under `data`. The event catalog is the `webhooks` section of the Straddle API contract.

## Endpoint types

Straddle offers three endpoint types, all created in the Straddle dashboard. Choose one in the plan; never poll an ordinary API read to discover state changes.

### Webhook endpoint

One `POST` per event to your public HTTPS URL, signed with the three headers above. Deliveries are independent and ordering is best effort. The rest of this reference, from [the non-negotiables](#the-non-negotiables) on, is the handler for this type: verify the raw body, persist, return `2xx` within seconds, and drop duplicates by `webhook-id` or `event_id`.

### FIFO endpoint

One `POST` per batch, in strict order. The batch size is set per endpoint (default 100). With the dashboard's default transformation (`format: "json"`, `data: input.events`), the body is a JSON array with one `{eventType, payload}` object per event, and `payload` is the event itself:

```json
[
  { "eventType": "charge.event.v1", "payload": { "event_id": "…", "event_type": "charge.event.v1", "account_id": "…", "data": { "id": "…", "status": "paid" } } },
  { "eventType": "payout.event.v1", "payload": { "…": "…" } }
]
```

A rejected batch is retried with growing backoff, and nothing newer is delivered until the oldest batch is accepted, so one rejected batch holds back every later status change while the backlog grows. A retried batch repeats events you may already have stored. The handler:

1. **Verifies the request before storing anything.** Which signature headers a FIFO delivery carries is not confirmed: an observed Sandbox delivery lacked at least one of `webhook-id`, `webhook-timestamp`, and `webhook-signature`. Do not assume the webhook scheme applies. Confirm it from a captured Straddle FIFO delivery before writing verification, and until then report FIFO verification as unconfirmed, never as passed. Never accept an unverified batch.
2. **Stores every event in array order**, reading each `payload` from the verified raw body.
3. **Drops duplicates by `event_id`**, so a retried batch stores nothing twice.
4. **Acknowledges all or nothing.** Return `2xx` only after the whole batch is committed. When any write fails, commit nothing and return `500`, so the batch is retried whole.

A handler that expects one event per request rejects every batch and blocks the endpoint.

### Polling endpoint

Your code pulls events, so no public URL is needed. Use it when you cannot expose a public URL, for local development, or for batch processing. Read the endpoint's URL and token from server-side configuration.

1. **Choose a consumer ID.** Each consumer keeps its own position, so give each independent reader its own ID.
2. **Poll with `starting_position`.** The response is a batch of events with offsets. The poll leases that batch to the consumer.
3. **Store every event in order**, dropping duplicates by `event_id`.
4. **Commit the last offset** after the batch is stored: `POST` `{"offset": N}` to the consumer's `…/commit` path.

Until the previous batch is committed, every poll returns `423 Locked`. A `423` means a missing commit, not a transient error to retry.

## Routing events on a platform

Straddle omits `account_id` from events delivered to a direct account, because the account is implicit. For a SaaS or marketplace platform, every event carries `account_id`, the embedded account the event belongs to. Route on that field. Do not infer the account from the endpoint URL, from the order events arrive in, or from IDs inside `data`. Reject an event that names an account your platform does not own.

## The non-negotiables

1. **Verify the signature on every request.** An unverified webhook is an anonymous internet POST. Anyone who learns your URL can forge events. Only act on payloads that pass verification.
2. **Verify against the raw request body.** The signature covers the exact bytes sent. Any framework that parses JSON and re-serializes it breaks verification. Read the unprocessed body.
3. **Return a `2xx` within seconds, but only after the event is safe.** A `2xx` tells Straddle the event is yours now; it will not be resent. Acknowledge only once the event is durably queued or its processing has been committed. Anything other than `2xx`, including `3xx` redirects, is treated as a failure and retried.
4. **Never treat a missing secret as "skip verification".** If the signing secret is not configured, fail the request with a configuration error. A handler that silently accepts unverified payments is worse than one that is down.

## Webhook handler shape

1. **Read the raw body.** Do not parse JSON before verification.
2. **Verify** with the selected Straddle SDK's webhook helper when it has one. Otherwise use the `standardwebhooks` library for your language. Pass the raw body, the three headers, and the endpoint's signing secret. On failure return `400`.
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

* **Only `2xx` means success.** Every other code is treated as a failure and retried on a backoff schedule.
* **Respond within the delivery timeout.** Keep the work before the response to verify, persist, respond. Everything slower runs from the queue after the `2xx`.
* **Use `4xx` to reject bad or forged requests** (failed verification returns `400`). Use `5xx` or timeouts only for transient failures you want retried.
* **Endpoints auto-disable after sustained failure.** Keep the handler healthy and wire up failure notifications from the Straddle dashboard.

## Manual verification (only when no library exists)

Prefer the SDK helper or `standardwebhooks`. If your language has neither, follow the scheme exactly and do not invent your own:

1. Strip the `whsec_` prefix from the secret and base64-decode the remainder to get the HMAC key.
2. Read `webhook-id`, `webhook-timestamp`, and `webhook-signature`.
3. Reject if `webhook-timestamp` is more than five minutes from now.
4. Build the signed content as `{id}.{timestamp}.{body}` using the raw body bytes.
5. Compute HMAC-SHA256 of the signed content with the decoded key and base64-encode it.
6. Compare in constant time against each `v1,<sig>` entry in `webhook-signature`. Pass if any matches.

## Verification traps

* **Body parsed before verification.** Re-serialization changes the bytes. Use raw-body access.
* **Wrong secret.** Each endpoint has its own `whsec_` secret. Sandbox and production endpoints differ.
* **Secret in the wrong format.** Strip the prefix and base64-decode before use.
* **Replaying a captured payload with curl.** Verification rejects stale timestamps. Trigger a fresh delivery from the Straddle dashboard instead.
* **Reverse proxy stripping headers.** Confirm all three `webhook-*` headers reach the handler.
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
* FIFO: each request is parsed as a batch; every event is stored in order, duplicates are dropped by `event_id`, and `2xx` follows the whole batch's commit
* FIFO: signature verification is confirmed from a captured Straddle FIFO delivery, not assumed
* Polling: the last offset is committed after the batch is stored, and a `423` is treated as a missing commit
