---
description: A charges integration subscribes to the lifecycle events it needs and handles every status, not only paid.
tags: [best-practices, product-model, webhooks]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

We're a direct Straddle account that creates customers, links bank accounts with Bridge, and charges them. Which webhook event types should our endpoint subscribe to, and what does each one mean for our app? Our current handler only looks for charge.event.v1 with status paid.
