---
type: llm
---

PASS if the reply (a) identifies TypeScript and names `@straddlecom/straddle` as the matching published SDK, and (b) asks the developer to choose or confirm the integration model among direct account, SaaS, and marketplace instead of declaring one as decided (mentioning that the README looks marketplace-like is fine if it is framed as a question), and (c) asks or lists as open the notification path (webhook endpoint, FIFO endpoint, or polling endpoint).
FAIL if the reply states the integration model as settled without asking, recommends a different SDK, recommends polling charge reads for status, or claims it created or configured anything.
