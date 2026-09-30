---
type: llm
---

PASS if the reply says all three: (1) cancel works only while the charge is `created`, `scheduled`, or `on_hold`, and once it is `pending` nothing stops it (the customer needs a refund after `paid` instead); (2) the amount can be updated only while the charge is `created` or `on_hold`, not up to `paid`; (3) `paid` is not final, because a return can move it to `reversed` days later, so the app keeps handling the charge's events after `paid`.
FAIL if the reply endorses cancelling or editing up to `paid`, treats `paid` as final, or says to discover status by repeatedly reading the charge.
