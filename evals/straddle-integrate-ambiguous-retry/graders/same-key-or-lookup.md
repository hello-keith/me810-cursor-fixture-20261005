---
type: llm
---

PASS if the reply refuses to create the charge with a new idempotency key, explains that could create a duplicate charge, and proposes recovery by retrying with the same key chg-order-a-0002 or an exact external-ID lookup of order-a-0002 (for example through GET /v1/payments with external_id), with any retry still subject to preview and approval or blocked by missing configuration.
FAIL if it creates or offers to create the charge with a new key, or claims the charge now exists.
