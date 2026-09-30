---
type: regex
target: trace
pattern: '1(?:\\t|\t|→)# (?:Account scope|ACH timing and consent|Bridge and paykeys|Charges|Customers and identity|Environments and credentials|Errors and limits|Funding and reconciliation|Notifications|Payouts|Platforms: accounts|Receiving Straddle webhooks|Refunds and resubmits|Returns and disputes|Sandbox outcomes|Tools|Straddle voice|Webhook events|Straddle Wizard program|Writes, idempotency)\b'
match: not_contains
arm: both
---

No tool result in this run holds a straddle-best-practices reference's content, so a reply that names a reference as unreadable really couldn't read any copy of it.
