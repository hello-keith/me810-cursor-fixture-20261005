# Provider mapping

Use this to find a provider's footprint and to describe the Straddle equivalent in the plan. It maps concepts, not method names: read the installed Straddle SDK and the Docs MCP for exact calls. Nothing in the "Never moves" column is migrated by this skill.

| Provider | Search terms | Concepts to map | Straddle side | Never moves |
| --- | --- | --- | --- | --- |
| Stripe | `stripe`, `us_bank_account`, `PaymentIntent`, `SetupIntent`, `financial_connections`, `Payout`, `Account` (Connect) | ACH debit, bank linking, payouts, Connect accounts, webhooks | Charges, Bridge paykeys, payouts; Connect accounts suggest SaaS or marketplace but the developer decides; Straddle webhook, FIFO, or polling endpoint | Customers, PaymentMethods, mandates, charge history |
| Plaid | `plaid`, `link_token`, `public_token`, `processor_token`, `/auth/get` | Bank linking and account verification | Bridge paykey from a Plaid processor token for new links (`POST /v1/bridge/plaid`), or the Bridge widget | Existing access tokens and Items |
| Moov | `moov`, `transfers`, `bank-accounts`, `accounts` | Accounts, bank accounts, transfers | Customers or embedded accounts, paykeys, charges and payouts | Accounts, bank accounts, transfer history |
| Modern Treasury | `modern_treasury`, `moderntreasury`, `PaymentOrder`, `Counterparty`, `ExternalAccount`, `ExpectedPayment` | Counterparties, external accounts, payment orders | Customers, paykeys, charges (debits) and payouts (credits) | Counterparties, external accounts, ledgers |
| Dwolla | `dwolla`, `funding-sources`, `transfers`, `customers`, `webhook-subscriptions` | Customers, funding sources, transfers, webhooks | Customers, paykeys, charges and payouts, Straddle notifications | Customers, funding sources, transfer history |
| Paya | `paya`, `ach`, `sec_code`, `ccd`, `ppd`, `web` | ACH processing | Charges and payouts with the appropriate consent type | Stored bank details and history |
| Payliance | `payliance`, `ach`, `echeck` | ACH / eCheck processing | Charges and payouts | Stored bank details and history |
| Other | `nacha`, `ach`, `routing_number`, `account_number`, file-generation code, SFTP upload | Whatever the developer describes | Map each described flow to charges, payouts, paykeys, and notifications | Stored bank details, files, history |

## Rules that apply to every row

- A provider status-polling loop becomes a Straddle webhook, FIFO, or polling endpoint consumer, never a loop on `GET /v1/charges/{id}` or similar reads.
- Raw account and routing numbers already stored by the application are customer data. Do not write code that reads them to create Straddle paykeys.
- Customer, paykey, charge, and payout creation happen in application code through the SDK, with idempotency keys and external IDs. The skill does not run them.
- Webhook handlers for the old provider stay. The new Straddle handler is a separate route.
