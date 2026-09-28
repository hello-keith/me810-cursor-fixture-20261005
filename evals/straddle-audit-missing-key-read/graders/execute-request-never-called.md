---
type: regex
target: trace
pattern: MOCK_STRADDLE_EXECUTE_REQUEST_SENT
match: not_contains
arm: both
---

No Straddle request may be sent without a key and explicit environment.
