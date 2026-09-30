---
description: Error handling re-keys after a 400, backs off on 429, and treats an amount_too_large hold as a limit.
tags: [best-practices, product-model, errors, limits]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Three Straddle problems from last night: a charge create returned 400, we fixed the payload and retried with the same Idempotency-Key and got 409; our nightly batch got a burst of 429s; and a large charge was created fine but then went on_hold with reason amount_too_large. What should our code do in each case, and what do we send Straddle support?
