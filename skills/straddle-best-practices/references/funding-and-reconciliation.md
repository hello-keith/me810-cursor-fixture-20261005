# Funding and reconciliation

Every status, field, and operation in backticks is checked against API contract 1.0.4 by `scripts/check-contract-tokens`. Facts marked "Observed in Sandbox" come from Sandbox runs, not from the contract or the docs. For details beyond this page, search the Docs MCP by concept, for example "funding events", "reconciliation", or "payments search".

## What it is

A funding event is money actually moving between Straddle and the account's linked bank account. It nets many payments into one bank transfer, so your bank statement shows funding events, not individual charges and payouts.

| `event_type` | `direction` | Moves |
| --- | --- | --- |
| `charge_deposit` | `deposit` | Collected charges, into your account. |
| `charge_reversal` | `withdrawal` | Charges returned after `paid`, out of your account. |
| `payout_withdrawal` | `withdrawal` | Funds for payouts, out of your account before they're sent. |
| `payout_return` | `deposit` | Failed or returned payouts, back into your account. |

A funding event has `id`, `amount` (cents), `payment_count`, `transfer_date`, `trace_ids`, `trace_numbers`, `status`, `status_details`, `status_history`, and `linked_bank_account_details`. Each charge and payout lists the funding events that included it in `funding_ids`. Production funding events carry their ACH trace in `trace_numbers` and `trace_ids`. Sandbox sends no real ACH file, so Sandbox funding events omit `trace_numbers` and often have no trace in `trace_ids` either (see [Events and Sandbox outcomes](#events-and-sandbox-outcomes)).

`listFundingEventPayments` breaks a funding event into its payments. Each has `payment_type`, `payment_amount`, `funding_amount` (the part of the payment in this event), `reason` (`credit`, `debit`, `reversal`, or `failed`), `status`, `external_id`, `trace_ids`, and `metadata` when you send `include_metadata`. `funding_amount` is signed: a `reversal` line is negative. The response doesn't return `external_id`, though the contract marks it required, so join its payments on payment `id`.

## States and transitions

A funding event uses the payment statuses: typically `created`, then `pending` while the transfer is in flight, then `paid`. Its timing comes from the account's `funding_time`, which Straddle sets in the account settings (`immediate`, `next_day`, `one_day`, `two_day`, `three_day`, `four_day`, or `five_day`). Straddle funds within one business day by default:

- Charges are funded after they settle, so a `charge_deposit` follows `paid`, and weekends and holidays push it later.
- Payouts are funded before they're sent: the `payout_withdrawal` comes first.
- A return is funded later and never edits the original deposit: in its own `charge_reversal` or `payout_return`, or, observed in Sandbox, netted into a later `charge_deposit`.

Reconciliation keys, from Straddle's docs:

- The funding event `id` appears in the ACH addenda on your bank statement. Use it as the primary key between the bank line and Straddle.
- Trace numbers are a backup, because some banks don't show them.
- The contract has no fee field. Straddle's docs say platform fees may be netted into funding events, so reconcile the bank amount to the funding event `amount`, and the payments to its `funding_amount` lines.

For reporting across payments, `listPayments` searches charges and payouts together. It filters by `payment_type`, `payment_status`, `status_reason`, `status_source`, `external_id`, `funding_id`, `customer_id`, `paykey_id`, amount and date ranges (`min_effective_at`, `max_effective_at`, and others), and `is_refund`, `has_refund`, `is_resubmit`, and `has_resubmit`. Build your exports from it, or use the exports in the Straddle dashboard.

## What your app must handle

- Record each payment's `funding_ids` as they arrive, and treat a payment as settled in your books only when its funding event is.
- On each funding event, fetch its payments once with `listFundingEventPayments`, match them to your records by payment `id` (the response has no `external_id`), and post the event `amount` against the bank line by funding event `id`.
- Expect a `reversed` charge to come back as a `charge_reversal` withdrawal or as a negative `reversal` line inside a later `charge_deposit`, and a `payout_withdrawal` before a payout is sent. Keep enough funds in the linked bank account for both.
- Net each funding event's payments against its `direction`, using the size of `funding_amount`, which is signed (a netted `reversal` is negative). A line counts toward the event `amount` when its `reason` moves money the event's way (`credit` for a `deposit`; `debit` or `reversal` for a `withdrawal`), against it when it moves money the other way, and not at all when it's `failed`. So in a `charge_deposit` the `credit` lines add and a netted `reversal` subtracts, and in a `charge_reversal` the `reversal` lines make up the withdrawal. The net equals the event `amount` unless a fee was netted in.
- Expect payments with `funding_amount` `0` and `reason` `failed` inside a deposit, and one payment spread across events.
- Key on the funding event `id`. Use trace numbers as the backup key: production funding events carry them in `trace_numbers` and `trace_ids`, and `listFundingEvents` results also have `trace_number`. Sandbox funding events lack them, so guard for missing traces when you run against Sandbox.
- Reconcile by business day, not by calendar day, and allow for funding timing that differs per account.

## Events and Sandbox outcomes

- `funding_event.created.v1` when a funding event is created, and `funding_event.event.v1` on creation and every change, with the full `status_history` ([webhooks.md](webhooks.md)).
- Sandbox: `simulateFundingEvent` with `funding_event_job_type` `charges` or `payouts` makes a funding event for the account's unfunded activity. It's account-wide, so it includes other testers' payments on the same account.
- Observed in Sandbox on 2026-09-30: a charges simulation made a `charge_deposit` that was `pending` with the next day's `transfer_date`. It held 10 payments: paid charges and charges still `pending` as `credit` with their full amount, and failed charges as `failed` with `funding_amount` `0`. No `charge_reversal` appeared within 15 minutes of the reversals. A payouts simulation made a `payout_withdrawal` that stayed `pending` ([payouts.md](payouts.md#events-and-sandbox-outcomes)).
- Observed in Sandbox on 2026-10-02 (TypeScript SDK 1.0.4), from a back office that lists funding events and their payments:
  - Funding event list and retrieve responses omitted `trace_numbers`, though the contract and the SDK types mark it required, so code that trusted the types crashed reading its length. Some events had TraceId in `trace_ids`, a key the contract doesn't name, and others had no trace in either. Sandbox sends no real ACH file, so this is Sandbox only.
  - `funding_amount` was signed: a `reversal` line was negative in a `charge_reversal`, and inside a `charge_deposit` too, where it was netted against the `credit` lines instead of arriving as a separate `charge_reversal`.
  - `listFundingEventPayments` returned no `external_id`. Join its payments to your records by payment `id`.
- The simulation's timing decides whether a reversal outcome reaches `paid` first. See [sandbox-outcomes.md](sandbox-outcomes.md#funding-and-account-simulations).
