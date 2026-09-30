---
description: Sandbox scenarios pick the sandbox_outcome values that exercise a dispute block and a return after paid.
tags: [best-practices, product-model, sandbox]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

For our Straddle Sandbox tests we need two scenarios: a charge disputed as unauthorized that also blocks the customer's bank account, and a charge that is paid and then returned for insufficient funds. Which config.sandbox_outcome values do we use, and what should each test expect to see?
