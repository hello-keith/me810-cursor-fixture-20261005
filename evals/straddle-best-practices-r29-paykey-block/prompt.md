---
description: An R29 return is handled as a dispute that blocks the paykey, with the one-time unblock gated on unblock_eligible.
tags: [best-practices, product-model, returns, disputes, paykeys]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

A customer's Straddle charge came back failed with status_details.code R29, and now every new charge on the same bank account fails right away with reason invalid_paykey. Our support team wants a button that clears whatever is blocking it so we can keep charging. What happened, and what should that button do?
