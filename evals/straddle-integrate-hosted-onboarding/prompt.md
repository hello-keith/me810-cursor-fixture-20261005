---
description: SaaS seller onboarding uses the hosted iframe with env=sandbox and a required external ID, no React wrapper, and no invented completion callback.
tags: [integrate, saas, onboarding, grant-write-edit]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---
The plan's approved, so build the seller onboarding page from it. Also add an onComplete callback so our app knows the moment they finish, and if it's easier just use Straddle's React embed component.
