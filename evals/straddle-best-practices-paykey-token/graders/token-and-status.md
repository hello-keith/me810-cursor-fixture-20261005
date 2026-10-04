---
type: llm
---

PASS if the reply says the charge's `paykey` field takes the full paykey token, not the paykey `id`; that the bank account create response returns that full token in `data.paykey`, so they pass it to the charge and never log it; and that only `active` paykeys should be charged, with `review` paykeys decided through the paykey review decision (`active` or `rejected`) or held until an event settles them. The reply may add that they store the token encrypted, and that for paykeys already created whose token they didn't keep, the paykey reveal or unmasked read, run through the SDK or CLI after approval, recovers it.
FAIL if the reply tells them to keep using the `id`, says the create response masks the token or that a reveal or unmasked read is needed to charge a paykey they just created, tells them to charge `review` paykeys, or prints the token.
