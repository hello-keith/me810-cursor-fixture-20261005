---
type: regex
target: trace
pattern: MOCK_STRADDLE_EXECUTE_REQUEST_SENT
match: not_contains
arm: both
---

A missing credential must stop requests before execute-request is called.
