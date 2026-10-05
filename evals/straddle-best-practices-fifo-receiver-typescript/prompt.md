---
description: "TypeScript receiver for a FIFO endpoint: svix-* headers verified with the svix library, the {data:[{payload,eventType}]} batch stored whole and in order."
tags: [best-practices, webhooks, fifo, grant-bash-write]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
---

We're a SaaS platform on Straddle. I created a FIFO endpoint in the Straddle Sandbox dashboard pointing at `https://api.example.com/webhooks/straddle/fifo`, with the dashboard's default transformation, subscribed to charge.event.v1 and payout.event.v1. I ran the dashboard's transformation test on a two-event batch and captured its output:

```json
{
  "data": [
    {
      "payload": {
        "event_type": "charge.event.v1",
        "event_id": "6f1c2a9e-4b7d-4e2a-9c31-0d8e5f7a1b23",
        "account_id": "0b8d3e4f-7a21-4c6e-8f95-2d1a6c9e3b47",
        "data": { "id": "9a7e1c3d-2f4b-4d8a-b6e5-1c0f9d2a7e84", "status": "paid", "amount": 2500, "external_id": "order_1042" }
      },
      "eventType": "charge.event.v1"
    },
    {
      "payload": {
        "event_type": "payout.event.v1",
        "event_id": "c2d4e6f8-1a3b-4c5d-8e7f-9a0b1c2d3e4f",
        "account_id": "0b8d3e4f-7a21-4c6e-8f95-2d1a6c9e3b47",
        "data": { "id": "3e5a7c9b-1d2f-4a6b-8c0e-5f7a9b1d3c26", "status": "pending", "amount": 2400, "external_id": "payout_311" }
      },
      "eventType": "payout.event.v1"
    }
  ]
}
```

Our Straddle integration plan for this receiver is approved. Write the Express route in src/fifo.ts and register it in src/server.ts. Store events with saveEvents from src/store.ts. Don't create anything in Straddle.

The Straddle CLI for this workspace is at `./bin/straddle`; use that path if you inspect the CLI.
