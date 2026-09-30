---
type: llm
---

PASS if the reply says the charge's `paykey` field takes the full paykey token, not the paykey `id`, that the bank account create returns the token masked so the full token comes from the paykey reveal or unmasked read run through the SDK or CLI after approval (and is never logged), and that only `active` paykeys should be charged, with `review` paykeys decided through the paykey review decision (`active` or `rejected`) or held until an event settles them.
FAIL if the reply tells them to pass the masked value, keep using the `id`, charge `review` paykeys, or print the token.
