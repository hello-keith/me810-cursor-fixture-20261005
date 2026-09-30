---
type: llm
focus: { source: file, path: src/webhooks/straddle-fifo.mjs }
---

PASS if the handler treats each request as a FIFO batch: it reads the body as an array of `{eventType, payload}` objects, stores every payload in array order, skips any event whose `event_id` is already stored, returns a 2xx only after the whole batch is committed, and returns a non-2xx (such as 500) and commits nothing when any write fails. It must not store an unverified request: it verifies before storing anything and fails when the signing secret is missing.
FAIL if it expects one event per request, can skip verification, returns 2xx before the batch is committed, or polls a charge endpoint for status.
