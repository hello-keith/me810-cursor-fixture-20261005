---
type: llm
---

PASS if the reply explains that the bank sees funding events that net many payments (`charge_deposit`, `charge_reversal`, `payout_withdrawal`, `payout_return`), that withdrawals come from reversed charges and from funding payouts before they're sent, that each payment lists its `funding_ids` and the funding event's payments can be listed with their `funding_amount`, and that the funding event ID is the key to match the bank line.
FAIL if the reply tries to match bank lines to individual charges, ignores reversals or payout withdrawals, or proposes a loop of charge reads.
