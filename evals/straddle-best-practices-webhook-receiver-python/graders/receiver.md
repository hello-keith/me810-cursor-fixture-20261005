---
type: llm
focus: { source: file, path: app/webhooks.py }
---

PASS if all hold: the handler verifies the signature before parsing or storing, over the raw body (for example `request.get_data()`), through the `svix` library with the request headers and a `whsec_` secret read from the environment (for example `STRADDLE_WEBHOOK_SECRET`), so that a delivery carrying `webhook-id`, `webhook-timestamp` and `webhook-signature` verifies; a failed verification returns `400`; a missing secret is a configuration error, never a skip; the event is stored before a `2xx`, a failed store returns a non-`2xx`, and a duplicate `webhook-id` or `event_id` is a no-op.
FAIL if it parses JSON before verifying, verifies against re-serialized JSON, implements manual verification despite Python having the `svix` library, introduces an SDK helper or `standardwebhooks` instead of `svix` for this new receiver, skips verification when the secret is missing, logs the secret, or returns `2xx` before storing.
