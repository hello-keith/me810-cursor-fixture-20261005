---
description: Charge hold, cancel, and edit windows follow the contract, and paid is not final.
tags: [best-practices, product-model, charges]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

We're adding Straddle charges to our Node checkout with @straddlecom/straddle. Our order page lets a customer cancel an order or change its amount at any time until the charge is paid: we call the charge cancel or update endpoint, and once the charge is paid we mark the order complete and stop tracking it. Is that right? Short answer per point.
