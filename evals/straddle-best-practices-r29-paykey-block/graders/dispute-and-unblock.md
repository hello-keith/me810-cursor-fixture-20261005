---
type: llm
---

PASS if the reply explains that R29 is an unauthorized return (a dispute, `source` `customer_dispute`) that moved the paykey to `blocked`, says the paykey can be unblocked only once through the unblock operation and only when `unblock_eligible` is `true`, and says to confirm the customer's authorization first (and keep or upload proof of authorization) instead of unblocking automatically to keep charging.
FAIL if the reply says the block can be cleared repeatedly, suggests creating a new paykey or retrying charges to get around the block without the customer's authorization, or doesn't mention the one-time limit.
