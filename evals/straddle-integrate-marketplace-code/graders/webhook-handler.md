---
type: llm
focus: { source: file, path: src/webhooks/straddle-fifo.mjs }
---

PASS if the handler verifies the signature from the raw request body using the SDK's webhooks.unwrap with the request headers passed (or the standardwebhooks library), fails when the signing secret is missing, persists or queues the event keyed by webhook-id or event_id before returning a 2xx, returns a non-2xx (such as 500) when persisting fails, and treats a duplicate delivery as a no-op.
FAIL if it parses JSON before verification, can skip verification, returns 2xx before the event is persisted, or polls a charge endpoint for status.
