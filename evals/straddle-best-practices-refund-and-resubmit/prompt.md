---
description: Partial refunds and resubmits use the right operation, status, linking, and one-per-payment rule.
tags: [best-practices, product-model, refunds, resubmits]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Two support cases on Straddle: (1) a customer wants $20 back from a $100 charge that is paid, and (2) another customer's $50 charge failed with code R01. We plan to create a new $20 payout to the customer for the first, and create a brand-new $50 charge for the second. Is there a better way, and what do we need to watch for?
