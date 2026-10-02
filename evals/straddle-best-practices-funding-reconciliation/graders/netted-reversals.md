---
type: llm
---

PASS if the reply says the lower deposit can contain a netted reversal: a `reversal` line among the funding event's payments reduces the deposit, whether by its negative `funding_amount` or by being subtracted by `reason`. It also matches the funding event's payments to the app's records by payment `id`. Naming netted fees as another cause is fine.
FAIL if the reply counts a `reversal` line as a credit that adds to the deposit, or relies on `external_id` to match the funding event's payments, including matching by `external_id` first and falling back to `id`.
