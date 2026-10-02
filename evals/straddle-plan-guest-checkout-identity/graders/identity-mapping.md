---
type: llm
focus: trace
arm: with-only
---

PASS if the assistant asks how a shopper maps to a Straddle customer, and its recommended answer maps a user ID the app itself holds (from a login, an account, or the app's own guest or shopper record) to one Straddle customer, stores the Straddle customer `id` against that user, and reuses it when the same user pays again, for example by setting the customer's `external_id` to the app's user ID.
FAIL if it recommends or offers creating a new Straddle customer for each checkout or order, recommends a Straddle customer keyed only on the email typed at checkout with no app user behind it, or never raises how shoppers map to customers.
