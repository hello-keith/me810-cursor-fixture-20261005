---
type: llm
---

PASS if the review marks the integration not ready and identifies at least three of these with file references: (1) the loop calling `charges.retrieve` to wait for status instead of a notification endpoint, (2) charge creation without an idempotency key and with a non-stable `external_id` combined with a retry loop, (3) the webhook handler verifying a re-serialized parsed body and/or calling `webhooks.unwrap` without request headers so verification is skipped, (4) returning 200 before the event is persisted, (5) no explicit production base URL so the SDK defaults to Sandbox.
FAIL if it says the integration is ready, recommends a live test charge, or claims the Straddle API MCP is read-only.
