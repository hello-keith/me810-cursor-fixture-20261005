---
description: A payment takes the full paykey token the create returns in data.paykey, from an active paykey, not the paykey id.
tags: [best-practices, product-model, bridge, paykeys]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

We create a Straddle paykey from routing and account numbers with the bank account Bridge endpoint, save data.id from the response, and pass that id as the paykey field when we create charges. Charges fail validation. Also, some paykeys come back with status review. What's wrong, and how should we handle both?
