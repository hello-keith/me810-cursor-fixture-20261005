# Notifications

## What is not a notification model

- Looping on `GET /v1/charges/{id}` with a sleep between calls.

## Status checks

Poll `GET /v1/payouts/{id}` every 10 seconds until the status is `paid`.
