---
type: llm
focus: { source: file, path: src/onboarding/page.mjs }
---

PASS if, tracing the code in this file, every hosted-form iframe URL it renders carries `env=sandbox` and `external.id` set to the seller's stored external ID. Accept a literal query string, `URL.searchParams.set`, or `URLSearchParams`, but only when the value that reaches the rendered URL is actually `sandbox` (a literal, or a variable that can only hold `sandbox` at that point because another value throws or stops rendering) and the external ID is required (rendering fails without it).
FAIL if the environment value could be anything other than `sandbox` (for example a production default or an unvalidated pass-through), if `external.id` is missing, optional, or a placeholder, or if the parameters appear only in comments, docs, or text that never reaches the iframe URL.
