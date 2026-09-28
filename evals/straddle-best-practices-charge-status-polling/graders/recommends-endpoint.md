---
type: llm
---

PASS if the reply advises against repeatedly reading the charge to discover status and recommends a Straddle webhook endpoint, FIFO endpoint, or polling endpoint (an event stream read with a consumer ID and offset).
FAIL if the reply endorses the setInterval charge read loop, proposes any other repeated GET on charges or payments to detect status, or presents Dashboard email as the way the code learns about status changes.
