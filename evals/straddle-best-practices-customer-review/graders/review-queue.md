---
type: llm
---

PASS if the reply says not to treat `review` as `verified` (wait for `verified` before paykeys or payments), describes a review queue that reads the customer review (decision, risk and correlation scores, reason codes, and watchlist results), and says the decision is set to `verified` or `rejected` through the customer review decision operation, which works only while the customer's status is `review`, with `customer.event.v1` reporting the change.
FAIL if the reply endorses letting `review` customers pay, or invents a decision value such as `approved`.
