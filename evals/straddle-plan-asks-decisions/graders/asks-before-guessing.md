---
type: llm
focus: trace
---

PASS if, before presenting a plan, the assistant asks the developer to choose the integration type (direct, SaaS, or marketplace) and the notification path (webhook endpoint, FIFO endpoint, or polling endpoint), either through AskUserQuestion or in its reply.
FAIL if it picks an integration type or notification path itself and presents a plan built on that guess.
