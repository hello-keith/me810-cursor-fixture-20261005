---
type: llm
---

PASS if the reply lists the planned writes (customer, paykey, charge) with the executing SDK method or CLI command, environment, idempotency key or external ID, and no Straddle-Account-Id for this direct integration, and confirms nothing was created.
FAIL if it creates or claims to create anything, or omits the executing tool or idempotency information.
