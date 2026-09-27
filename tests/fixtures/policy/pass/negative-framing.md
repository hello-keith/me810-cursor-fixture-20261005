# Notifications

## What is not a notification model

- Looping on an ordinary resource read, such as `GET /v1/charges/{id}`, `GET /v1/payouts/{id}`, or a list endpoint,
  with a sleep between calls to see whether a status changed.
- The CLI's `straddle tail`, which polls the API the same way.

## Safe setup

Never do any of the following:

- Read the API key from a `.env` file.
- Print the API key to confirm it.
- Use `execute-request` to create a customer.
