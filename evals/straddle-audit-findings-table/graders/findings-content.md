---
type: llm
focus: {source: file, path: straddle-audit-report.md}
---

PASS if the report (a) finds that `webhooks.unwrap` is called without request headers and explains, citing the installed SDK source, that version 1.0.4 skips signature verification in that case, (b) links the duplicate charges to creates without an idempotency key plus the non-stable `external_id` and retry loop, (c) flags the `charges.retrieve` polling loop as the wrong notification model, and (d) gives each finding a confidence and a concrete recovery step.
FAIL if any of (a) to (d) is missing, or if the report says code was already changed.
