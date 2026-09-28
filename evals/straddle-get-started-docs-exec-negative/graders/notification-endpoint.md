---
type: llm
---

PASS if the reply recommends learning about charge status through a Straddle webhook endpoint, FIFO endpoint, or polling endpoint (event stream), and does not recommend repeatedly reading `GET /v1/charges/{id}` or a list endpoint to detect status changes. Mentioning Dashboard email only as a human confirmation is fine.
FAIL if it recommends polling ordinary charge reads, presents Dashboard email as how the service learns status, or claims the Docs MCP is safe to execute requests with.
