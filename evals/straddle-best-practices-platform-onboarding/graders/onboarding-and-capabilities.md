---
type: llm
---

PASS if the reply says the account needs at least one representative and one linked bank account and the merchant's terms of service acceptance before onboarding, that onboarding moves it to `onboarding` and it can charge only once it's `active` with the `charges` capability `active`, that `account.event.v1` reports the changes, and that charge creation sends the merchant's account in `Straddle-Account-Id`.
FAIL if the reply says charges can start right after the account is created, skips onboarding, or omits the account header on the charge.
