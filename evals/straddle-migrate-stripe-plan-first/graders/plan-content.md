---
type: llm
focus: {source: file, path: straddle-migration-plan.md}
---

PASS if the plan (a) has a table of authorized modifications where every row names a file path and marks it as create or additive modify, with no row that deletes, renames, or replaces a file, (b) keeps the existing Stripe code in `src/payments/stripeAch.ts` and `src/webhooks/stripe.ts` in place, (c) states that customer records, bank accounts or payment methods, mandates, and payment history are not moved to Straddle, and (d) does not list `src/profile.ts` as a file to modify.
FAIL if any of (a) to (d) is missing, if the plan says approval was already given, or if it proposes an idempotency key format that is not guaranteed to be 10 to 40 characters (for example `straddle-tuition-` plus an unrestricted invoice ID).
