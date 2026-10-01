---
type: llm
focus: last_message
arm: with-only
---

PASS if the reply tells the developer that one or more of the skill's reference files could not be read and names at least one of them (for example refunds-and-resubmits.md, charges.md, or the straddle-best-practices skill), and it keeps the answers the developer just accepted rather than questioning, correcting, or asking any of Q5 to Q12 again.
The skill's own planning step states two product rules without needing a reference: every customer create sends `phone` in E.164, and `config.balance_check` is `enabled`. Stating either as a settled Decisions row (citing `customers-identity.md` or `charges.md` as its source is fine) is a rule the skill gave, not an unconfirmed product fact.
FAIL if it names no unreadable reference, presents as settled a new product fact that only an unreadable reference would supply and that is neither one of those two rules nor part of an answer the developer accepted (such as return codes, timing, webhook event names, or other required fields), or reopens, corrects, or re-asks an answer to Q5 to Q12 (such as which return codes Q11 resubmits).
