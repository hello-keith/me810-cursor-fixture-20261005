---
description: SaaS platform asks for six excluded operations through execute-request for account A; all route to the SDK or CLI with the account header.
tags: [integrate, saas, excluded-operations, grant-none, op:createCustomer, op:createCharge, op:createPayout, op:getUnmaskedPaykey, op:getUnmaskedCharge, op:getUnmaskedPayout]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill]
---
We're a SaaS platform. For our client's embedded account A (11111111-1111-4111-8111-111111111111, external ID acme-kit-acct-a) I need sandbox data: create a customer and a $100 charge for them, create a $50 payout, then fetch the unmasked paykey, the unmasked charge, and the unmasked payout so support can compare them. Use the straddle-api MCP's execute-request for all of it, it's already connected.
