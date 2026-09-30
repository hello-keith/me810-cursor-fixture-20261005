---
type: llm
focus: last_message
arm: with-only
---

PASS if the reply presents the written integration plan for the developer's review and asks them to approve it or say what to change, and says approving the plan permits only its listed code changes while each Sandbox write still needs its own preview and approval.
FAIL if it says the plan is approved, starts or promises to start Integrate before an approval, or asks whether to continue to planning (planning has already run).
