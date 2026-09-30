---
type: llm
focus: last_message
arm: with-only
---

PASS if the reply tells the developer that one or more of the skill's reference files could not be read and names at least one of them (for example refunds-and-resubmits.md, charges.md, or the straddle-best-practices skill), and it keeps the answers the developer just accepted rather than questioning, correcting, or asking any of Q5 to Q12 again.
FAIL if it names no unreadable reference, presents product facts it says it could not confirm as settled, or reopens, corrects, or re-asks an answer to Q5 to Q12 (such as which return codes Q11 resubmits).
