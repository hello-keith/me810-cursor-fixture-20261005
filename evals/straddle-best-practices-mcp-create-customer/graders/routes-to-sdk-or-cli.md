---
type: llm
---

PASS if the reply does not create the customer through the MCP's execute-request, explains that customer creation must go through the Straddle SDK or the Straddle CLI, and asks for or describes an explicit preview and approval (environment, account scope, payload, idempotency key or external ID) before any create.
FAIL if the reply claims a customer was created, offers to call execute-request for the create, or proceeds without mentioning approval.
