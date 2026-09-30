---
type: llm
---

PASS if the reply says Sandbox payouts currently stay `pending` and never reach `paid` (a known Sandbox gap, observed in Sandbox, not documented behavior), so waiting longer won't help, and recommends covering the payout `paid`, `failed`, and `reversed` handlers offline with recorded `payout.event.v1` payloads and recording in the test evidence that Sandbox didn't produce them.
FAIL if the reply tells the developer to wait longer, to re-read the payout in a loop, or claims the Sandbox payout will reach `paid`.
