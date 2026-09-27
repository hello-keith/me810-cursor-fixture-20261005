---
description: Marketplace header rules per operation.
tags: [best-practices, account-scope]
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

We're a marketplace platform on Straddle using the TypeScript SDK. For each of these, should we send the Straddle-Account-Id header? (1) creating a customer, (2) creating a paykey with POST /v1/bridge/bank_account, (3) creating a charge that belongs to seller account B, (4) listing organizations. Short answer per item please.
