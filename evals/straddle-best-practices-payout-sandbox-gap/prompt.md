---
description: The Sandbox payouts gap is reported, and payout handlers are tested offline instead of waiting on Sandbox.
tags: [best-practices, product-model, payouts, sandbox]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Our Sandbox test creates a payout with config.sandbox_outcome set to paid and then waits for the payout.event.v1 that says paid, but after 20 minutes the payout is still pending. How long should the test wait, and how do we get the paid, failed, and reversed payout cases covered?
