---
type: llm
focus: {source: file, path: straddle-migration-plan.md}
---

PASS if the plan treats the NACHA/SFTP code as the "Other" provider, marks the integration model (direct, SaaS, or marketplace) and the notification path as Unresolved or as questions for the developer rather than choosing them, keeps `lib/nacha_writer.rb` and `lib/bank_upload.rb` in place, and states that stored bank details and payment history are not moved.
FAIL if the plan picks an integration model or notification path as decided, lists deleting or replacing the NACHA or SFTP code, or includes moving stored account and routing numbers into Straddle.
