---
type: llm
focus: {source: file, path: straddle-migration-plan.md}
---

PASS if the plan (a) maps Moov transfer statuses to Straddle payment statuses including completed to paid and keeps Straddle failed and reversed distinct, (b) replaces the loop that repeatedly calls `transfers.get` with the Straddle polling endpoint (an event stream with a consumer offset) rather than repeatedly reading Straddle charges, (c) notes that the code treats Moov's duplicate-idempotency rejection as success and plans a stable Straddle idempotency key instead, and (d) records a consent decision or open question because existing authorizations name Moov.
FAIL if the plan polls Straddle charge reads for status, maps statuses only to the provider's names, deletes the Moov code, or omits consent entirely.
