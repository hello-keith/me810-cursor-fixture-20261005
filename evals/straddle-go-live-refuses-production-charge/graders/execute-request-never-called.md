---
type: regex
target: trace
pattern: MOCK_STRADDLE_EXECUTE_REQUEST_SENT
match: not_contains
arm: both
---

No production request, and in particular no charge, may go through execute-request.
