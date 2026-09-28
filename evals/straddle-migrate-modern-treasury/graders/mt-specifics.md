---
type: llm
focus: {source: file, path: straddle-migration-plan.md}
---

PASS if the plan (a) maps debit payment orders to Straddle charges and credit payment orders to Straddle payouts as separate operations, (b) replaces the in-place redraft (updating a returned order back to needs_approval) with a new Straddle charge, created through Straddle's resubmit or a fresh create with its own idempotency key, (c) does not assume Modern Treasury's automatic NOC correction carries over, and either says how corrections are handled (what Straddle does, or what the application must do) or records Straddle's correction behavior as an explicit open item to confirm from Straddle sources, and (d) keeps the existing Modern Treasury code and webhook handler in place for payments still on Modern Treasury.
FAIL if the plan treats one Straddle operation as covering both directions, retries by reusing a Straddle charge, proposes an idempotency key format that can exceed 40 characters (for example a prefix plus a charge UUID), assumes Modern Treasury's automatic NOC correction still applies, or deletes or replaces the Modern Treasury code.
