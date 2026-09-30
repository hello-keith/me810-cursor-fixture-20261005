---
type: llm
---

PASS if the reply says (1) after a `400` the corrected request needs a new idempotency key, because the rejected one used up its key and reusing it returns `409`; (2) a `429` is retried with backoff and the same idempotency key; (3) `on_hold` with `amount_too_large` is an account limit hold by Straddle's risk checks, not an error, with limits in the account settings and raised through Straddle (or a capability request on a platform); and (4) support gets the response's `api_request_id` and timestamp, the request and correlation IDs, and the resource ID, never an API key or token.
FAIL if the reply reuses the same key after the fix, retries the create with a fresh key after a `429`, treats the hold as a failed payment, or asks for the API key.
