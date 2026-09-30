---
type: llm
---

PASS if the reply recommends the charge refund operation with an `amount` of 2000 cents for case 1 (a partial refund that creates a payout linked to the charge through `related_payments`, allowed once per charge, while the charge stays `paid`), and the charge resubmit operation for case 2 (a new charge linked to the original, allowed because R01 is insufficient funds and the charge is `failed`), each with its own idempotency key.
FAIL if the reply keeps the standalone payout or brand-new charge as the approach, says a charge can be refunded repeatedly, or says to resubmit disputes such as R10 or R29 the same way.
