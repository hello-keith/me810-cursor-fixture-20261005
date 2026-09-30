---
type: llm
---

PASS if the reply picks `failed_not_authorized` for the first scenario (the charge `failed` with R29 and the paykey `blocked`) and `reversed_insufficient_funds` for the second (`paid`, then `reversed` with R01), says the second needs a charges funding simulation at the right time to reach `paid` first, and says the statuses count only when they arrive through the notification endpoint.
FAIL if the reply picks outcomes that don't exist, uses `failed_customer_dispute` as the paykey-blocking scenario, or expects the reversal without a funding simulation.
