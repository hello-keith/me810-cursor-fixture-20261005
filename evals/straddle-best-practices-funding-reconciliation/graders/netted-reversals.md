---
type: llm
---

PASS if the reply says the lower deposit can contain a netted reversal: a `reversal` line among the funding event's payments counts against the deposit, either through its negative `funding_amount` or because its `reason` moves money opposite to the event's `direction`, while `credit` lines count toward it. It also matches the funding event's payments to the app's records by payment `id`. Naming netted fees as another cause is fine.
FAIL if the reply counts a `reversal` line toward a deposit as if it were a credit, or relies on `external_id` to match the funding event's payments, including matching by `external_id` first and falling back to `id`.
