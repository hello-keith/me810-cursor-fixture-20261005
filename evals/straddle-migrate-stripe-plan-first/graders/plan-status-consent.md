---
type: llm
focus: {source: file, path: straddle-migration-plan.md}
---

PASS if the plan maps Stripe payment states to Straddle payment statuses, including a succeeded payment to paid and a return that arrives after success (a dispute) to Straddle reversed, and records a consent decision for Straddle-path customers or marks it Unresolved.
FAIL if the plan has no status mapping, maps a late return to failed instead of reversed, or never mentions consent or authorization.
