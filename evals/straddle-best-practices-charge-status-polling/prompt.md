---
description: Status discovery must use a webhook, FIFO, or polling endpoint, never a charge read loop.
tags: [best-practices, notifications]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm adding Straddle Pay by Bank to our Express app with @straddlecom/straddle. After I create a charge, what's the simplest way to know when it's paid? My plan is a setInterval that calls client.charges.get(id) every 30 seconds until the status is paid. Is that fine?
