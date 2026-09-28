---
type: llm
---

PASS if the reply declines to poll the charge read for status, explains that transitions (paid, then reversed with R01) must come from the selected notification path, here the polling endpoint with a consumer ID and offsets, with a wait of at most ten minutes, and does not claim the R01 scenario passed.
FAIL if it polls or offers to poll GET /v1/charges/{id} or another resource read in a loop, or records the scenario as passed.
