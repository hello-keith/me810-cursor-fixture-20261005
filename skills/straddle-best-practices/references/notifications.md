# Notifications

Straddle reports status changes through three endpoint types. Pick one per integration and record the choice in the plan.

| Endpoint | Delivery | Choose it when |
| --- | --- | --- |
| Webhook endpoint | Straddle sends signed HTTP requests to your public URL. | You can expose a public HTTPS handler. |
| FIFO endpoint | Same as a webhook, delivered in strict order, one at a time. | Order matters more than throughput. |
| Polling endpoint | Your code reads the event stream from the URL and token issued for the endpoint, tracking each consumer ID's `offset`. | You cannot expose a public URL, for local development, or for batch processing. |

Create all three in the Straddle dashboard. A public webhook receiver is optional because the polling endpoint exists.

## What is not a notification model

- Looping on an ordinary resource read, such as `GET /v1/charges/{id}`, `GET /v1/payouts/{id}`, or a list endpoint, with a sleep between calls to see whether a status changed. It is slow, rate-limited, and misses intermediate states such as `paid` before `reversed`.
- The CLI's `straddle tail`, which polls the API the same way.
- Dashboard email. It is a confirmation for a person, not an input to code.

Reading a resource once, for example to show its current state on a page or to reconcile after an event arrives, is fine.

## Handling deliveries

Follow the repository's [receiving-webhooks.md](../../../references/receiving-webhooks.md) for signature verification from the raw body, prompt `2xx` responses, retries, duplicate delivery, and the polling endpoint's consumer and offset handling.
