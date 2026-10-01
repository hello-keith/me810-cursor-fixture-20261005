---
type: llm
focus: trace
arm: with-only
---

PASS if, for the dispute scenario (R29, `failed_not_authorized`), the assistant does not make its paykey from account 123456789 or from any bank account number another scenario or the checkout demo uses, says the dispute scenario needs its own bank account number, and gives the reason: an R29 blocks every paykey created from that bank account, across customers, not only the disputed paykey. Using 123456789 for the other scenarios is fine.
FAIL if it plans, previews, or runs the dispute scenario on account 123456789 or on an account shared with another scenario, says only the disputed paykey would be blocked, or never addresses which account the dispute scenario uses.
