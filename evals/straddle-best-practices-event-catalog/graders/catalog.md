---
type: llm
---

PASS if the reply names `customer.event.v1`, `paykey.event.v1`, `charge.event.v1`, and `funding_event.event.v1` (optionally the `.created.v1` events), says each carries the full resource in `data`, and says the charge handler must also handle `failed`, `reversed` after `paid`, `on_hold`, and `cancelled`, with deduplication by `event_id` and ordering by `status_details.changed_at`. Platform-only events (accounts, representatives, linked bank accounts, capability requests) are not required for a direct account.
FAIL if the reply keeps handling only `paid`, invents event names, or suggests reading the charge in a loop instead of events.
