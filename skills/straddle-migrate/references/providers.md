# Provider mapping

Use this to find a provider's footprint and describe the Straddle equivalent in the plan. It maps concepts and names the provider mechanisms a migration must replace, not Straddle method names: read the installed Straddle SDK and the Docs MCP for exact calls. Nothing in a "Never moves" line is migrated by this skill. Provider facts were checked against each provider's public documentation on 2026-09-27 and can change; confirm against the provider's current docs when a detail matters.

## Straddle side, for every provider

- Bank linking becomes a Straddle paykey through Bridge: the Bridge widget, raw bank details (`POST /v1/bridge/bank_account`), or a Plaid processor token (`POST /v1/bridge/plaid`).
- Debits become charges, credits become payouts, each with an `Idempotency-Key` and a stable `external_id`.
- Provider webhooks become a Straddle webhook, FIFO, or polling endpoint, verified per [receiving-webhooks.md](../../straddle-best-practices/references/receiving-webhooks.md). The provider's signature scheme does not carry over.
- Connected, sub-, or originator accounts hint at SaaS or marketplace. The developer chooses the model.
- Only operations in the public Straddle API contract are used.

## Stripe

- **Find it:** `stripe` package, `us_bank_account`, `paymentIntents`, `setupIntents`, `financial_connections`, `payouts`, Connect `accounts`, `constructEvent`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`.
- **Replace:** PaymentIntent debits with charges; SetupIntent / Financial Connections linking with Bridge; Stripe payouts with Straddle payouts; the `Stripe-Signature` (`t=…,v1=…`, `whsec_` secret) handler with a new Straddle handler on its own route.
- **Idempotency:** Stripe takes an `Idempotency-Key` on POST ([docs](https://docs.stripe.com/api/idempotent_requests)). Keep the existing derivation logic if it is stable per intent; do not reuse Stripe keys as Straddle keys across providers.
- **Never moves:** Stripe customers, PaymentMethods, mandates, and charge history.

## Plaid

- **Find it:** `plaid` package, `linkTokenCreate`, `itemPublicTokenExchange`, `processorTokenCreate`, `authGet`, `access_token`, `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`.
- **Replace:** Plaid lists `straddle` as a processor for `/processor/token/create` once the Straddle integration is enabled in the Plaid Dashboard ([docs](https://plaid.com/docs/auth/partnerships/straddle/)). For new links, keep Plaid Link, create a Straddle processor token, and send it to `POST /v1/bridge/plaid` to get a paykey. If the app sends raw numbers from `/auth/get` to another processor, the Straddle path uses the processor token instead.
- **Never moves:** existing Items and access tokens. Creating processor tokens for already-linked customers is a transfer of existing customer data and stays outside this skill.

## Moov

- **Find it:** `moovfinancial/moov-*` SDKs (TypeScript, Go, Python, Ruby, .NET, Java, PHP), `api.moov.io`, `X-Moov-Version`, `/accounts/{accountID}/transfers`, `paymentMethodID`.
- **Replace:** transfers (`POST /accounts/{accountID}/transfers`, required `x-idempotency-key`, source and destination payment methods, `secCode`) with charges or payouts; Moov bank-account payment methods with paykeys ([docs](https://docs.moov.io/api/money-movement/transfers/create/)).
- **Never moves:** Moov accounts, bank accounts, payment methods, and transfer history.

## Modern Treasury

- **Find it:** `modern-treasury` / `modern_treasury` SDKs, `app.moderntreasury.com`, `PaymentOrder`, `Counterparty`, `ExternalAccount`, `ExpectedPayment`, `direction: debit|credit`.
- **Replace:** debit payment orders with charges and credit payment orders with payouts; counterparties and external accounts with customers and paykeys.
- **Idempotency:** Modern Treasury keys are route-independent and scoped per API key ([docs](https://docs.moderntreasury.com/platform/reference/idempotent-requests)). Straddle keys should be derived per operation intent so a key reused across routes does not collide.
- **Never moves:** counterparties, external accounts, ledgers, and payment history.

## Dwolla

- **Find it:** `dwolla-v2` package, `funding-sources`, `transfers`, `customers`, `webhook-subscriptions`, `X-Request-Signature-SHA-256`, `DWOLLA_KEY`, `DWOLLA_SECRET`.
- **Replace:** transfers between funding sources with charges or payouts; funding sources with paykeys; the Dwolla webhook handler (HMAC-SHA256 of the body in `X-Request-Signature-SHA-256`, unordered deliveries) with a Straddle handler ([docs](https://developers.dwolla.com/docs/working-with-webhooks)). Dwolla also takes an `Idempotency-Key` header ([docs](https://developers.dwolla.com/docs/api-reference/api-fundamentals/idempotency-key)).
- **Never moves:** Dwolla customers, funding sources, and transfer history.

## Paya (Paya Connect, now Nuvei)

- **Find it:** `payaconnect.com`, `/v2/transactions`, `/v2/accountvaults`, `account_vault_id`, `ach_sec_code`, `/v2/postbackconfigs`, `developer-id`, `user-api-key`.
- **Replace:** ACH `POST /v2/transactions` debits and credits with charges and payouts; account vaults with paykeys; postbacks with a Straddle notification endpoint. Paya postbacks authenticate with optional Basic auth rather than a signature ([docs](https://docs.payaconnect.com/developers/api/endpoints/postbackconfigs)), so the Straddle handler adds signature verification the old one never had.
- **Never moves:** account vault tokens, stored bank details, and history.

## Payliance

- **Find it:** `api.payliance.com`, `/api/v1/echeck/debit`, `/api/v1/echeck/credit`, `/api/v1/echecktoken/create`, `/api/v1/echeck/queryreturns`, `UniqueTranId`, SFTP settlement files.
- **Replace:** eCheck debits and credits with charges and payouts; eCheck tokens with paykeys; scheduled calls to `queryreturns` or `retrieve` and SFTP settlement parsing with a Straddle notification endpoint ([developer docs](https://payliance.com/developers/), which link the ACH API reference).
- **Never moves:** eCheck tokens, stored bank details, and history.

## Other

- **Find it:** `nacha`, `ach`, `routing_number`, `account_number`, fixed-width file builders, SFTP uploads, bank return-file parsers.
- **Replace:** each flow the developer describes with charges, payouts, paykeys, and a notification endpoint. File generation and SFTP code stay in place behind the switch.
- **Never moves:** stored bank details, generated files, and history.

## Rules for every provider

- A provider status-polling loop or scheduled status/returns query becomes a Straddle notification consumer, never a loop on `GET /v1/charges/{id}` or similar reads.
- Raw account and routing numbers the application already stores are customer data. Do not write code that reads them to create Straddle paykeys.
- Customer, paykey, charge, and payout creation happen in application code through the SDK, with idempotency keys and external IDs. The skill does not run them.
- Old provider webhook handlers stay. The Straddle handler is a separate route.
