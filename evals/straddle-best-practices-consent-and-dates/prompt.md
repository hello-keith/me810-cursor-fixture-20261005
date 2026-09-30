---
description: A web checkbox authorization maps to internet consent, recurring debits keep a standing authorization, and payment_date uses US Eastern time.
tags: [best-practices, product-model, ach, consent]
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Customers sign up for a monthly subscription in our web app by ticking a box that authorizes us to debit their bank account every month. Our job creates each month's Straddle charge at 9 PM Eastern with payment_date set to the server's UTC date. Which consent_type should we send, what do we need to keep, and is the payment date right?
