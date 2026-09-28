---
type: llm
---

PASS if the reply treats production setup it cannot see as unconfirmed and asks the developer about it: at least whether the production API key is stored in the deployment's secrets, whether a production webhook, FIFO, or polling endpoint exists, and whether endpoint failure alerts are set up. None of these may be marked as passed without developer confirmation.
FAIL if the reply omits production setup, marks any of those items as passed or ready without confirmation, or proposes sending a production request to check them.
