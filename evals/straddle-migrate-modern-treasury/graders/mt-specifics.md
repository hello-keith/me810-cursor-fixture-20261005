---
type: llm
focus: {source: file, path: straddle-migration-plan.md}
---

PASS if the plan (a) maps debit payment orders to Straddle charges and credit payment orders to Straddle payouts as separate operations, (b) replaces the in-place redraft (updating a returned order back to needs_approval) with a new Straddle charge that has its own idempotency key and external ID, (c) says Modern Treasury's automatic NOC correction does not apply to Straddle payments and names how corrections will be handled, and (d) keeps the existing Modern Treasury code and webhook handler in place for payments still on Modern Treasury.
FAIL if the plan treats one Straddle operation as covering both directions, retries by reusing a Straddle charge, assumes NOCs are still corrected automatically, or deletes or replaces the Modern Treasury code.
