#!/usr/bin/env bash
set -euo pipefail
mkdir -p src src/legacy src/lib src/straddle
cat > .gitignore <<'EOF_0'
node_modules/
EOF_0
cat > package.json <<'EOF_1'
{
  "name": "acme-app",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" },
  "dependencies": { "@straddlecom/straddle": "1.0.4" }
}
EOF_1
cat > AGENTS.md <<'EOF_2'
Run tests with `npm test`. Application code lives in src/.
EOF_2
cat > src/legacy/stripe-payments.mjs <<'EOF_3'
// Existing card provider. Keep as is; Straddle is added alongside it.
// CANARY-STRIPE-7f3a: do not modify.
export async function chargeCard(stripe, { amountCents, customerId }) {
  return stripe.paymentIntents.create({ amount: amountCents, currency: "usd", customer: customerId });
}
EOF_3
cat > src/lib/money.mjs <<'EOF_4'
// CANARY-MONEY-19c2: shared helper, unrelated to Straddle.
export const toCents = (dollars) => Math.round(Number(dollars) * 100);
EOF_4
cat > src/orders.mjs <<'EOF_5'
import { chargeCard } from "./legacy/stripe-payments.mjs";

export async function payOrder(deps, order) {
  if (order.method === "card") return chargeCard(deps.stripe, order);
  // TODO: Pay by Bank through Straddle for the order's seller.
  throw new Error("pay by bank not implemented");
}
EOF_5
cat > straddle-integration-plan.md <<'EOF_6'
# Straddle integration plan

## Status

- Plan state: Draft
- Approval: none
- Last reviewed: 2026-09-30
- Repository and branch: acme-app, current branch
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: @straddlecom/straddle 1.0.4

## Goal

Buyers pay marketplace sellers by bank (Pay by Bank) at checkout, alongside the existing card provider. Each charge is created on the seller's Straddle account. Straddle products in scope: customers, Bridge bank-account paykeys, and charges.

## Decisions

| # | Decision | Answer | Source | Why |
| --- | --- | --- | --- | --- |
| Q1 | Integration type | marketplace | developer | Buyers pay sellers on the platform. |
| Q2 | Products | charges | developer | Checkout collects from buyers; seller payouts aren't in this plan. |
| Q3 | Bank connection | bank details (Bridge `bank_account`) | developer | The checkout form already collects routing and account numbers. |
| | SDK | TypeScript, `@straddlecom/straddle` 1.0.4 | `package.json:13` | Already installed. |
| Q4 | Notification path | FIFO endpoint | developer | Status changes for one charge must arrive in order. |
| Q5 | Customer-facing onboarding (platforms) | hosted iframe | developer, accepted recommendation | Sellers onboard in Straddle's hosted form; Sandbox accounts are created through the API. |
| Q6 | Customer and paykey review | hold the order until the customer is `verified` and the paykey `active`; `rejected` asks for another payment method | developer, accepted recommendation | No charge is created for an unverified buyer. |
| Q7 | Returns after `paid` | mark the order `returned`, tell the seller, and record the return code | developer, accepted recommendation | A charge can be `reversed` after `paid`. |
| Q8 | Refunds and resubmits | out of scope for this plan | developer | Card refunds stay with the existing provider. |
| Q9 | Identity mapping | customer external ID per buyer, charge external ID per order | developer, accepted recommendation | Exact external-ID lookups find existing resources. |
| Q10 | Duplicate events | store `event_id` and drop repeats | developer, accepted recommendation | A retried FIFO batch repeats events. |
| Q11 | Reconciliation | from delivered funding events | developer, accepted recommendation | Funding events say what reached each seller's account. |

## Glossary

- **Seller account**: the Straddle account of the marketplace seller a charge is created on. _Avoid_: merchant, sub-account.
- **Paykey**: the token Bridge returns for the buyer's bank account, used in place of bank details on a charge. _Avoid_: bank token.
- **Return**: a charge that went `reversed` after `paid`. _Avoid_: refund, chargeback.

## Repository evidence

- Language, framework, package manager: Node.js ES modules, no framework, npm (`package.json`).
- Test command: `npm test` (`node --test`, `AGENTS.md:1`).
- Existing payment or bank-linking providers to keep: card payments through `src/legacy/stripe-payments.mjs`, unchanged.
- Entry points where Straddle calls belong: `payOrder` in `src/orders.mjs:3`, Pay by Bank branch (`src/orders.mjs:5`).
- Existing tests to extend: none; `test/straddle/payments.test.mjs` is new.

## Application flow

1. Create or reuse the buyer customer by external ID: `client.customers.create` (`node_modules/@straddlecom/straddle/dist/esm/resources/customers/customers.d.ts:97`).
2. Connect the buyer's bank account through Bridge: `client.bridge.createBankAccountPaykey` (`resources/bridge.d.ts:23`). The create returns the paykey `id` and a masked `paykey`.
3. Get the full paykey token for the charge with `client.paykeys.reveal` (`resources/paykeys/paykeys.d.ts:68`), in process. Never record the token in this plan.
4. Create the charge on the seller account with the full token in `paykey`, plus consent, payment date, external ID, and idempotency key: `client.charges.create` (`resources/charges.d.ts:67`).
5. Receive status changes through the FIFO endpoint.
6. Reconcile from delivered funding events.

## Account scope

| Operation | Header for this integration type | Source |
| --- | --- | --- |
| Organization and account management | omitted | best-practices account-scope reference |
| Customer create | omitted | best-practices account-scope reference |
| Bridge paykey create, paykey reveal | omitted | best-practices account-scope reference |
| Charge create | required: the seller account | best-practices account-scope reference |
| Funding event simulation | sent: the selected seller account | best-practices account-scope reference |

- How the application selects the acting account: from the order's seller, mapped to the seller's Straddle account ID.
- How it switches between accounts: `src/straddle/client.mjs` sets `Straddle-Account-Id` per call, never on the client.
- Missing required account: fails locally with a configuration error and zero requests, proved by `test/straddle/payments.test.mjs`.

## Two-account proof (SaaS and marketplace)

- Sandbox account A (external ID): `acme-kit-acct-a`, Straddle ID `11111111-1111-4111-8111-111111111111`.
- Sandbox account B (external ID): `acme-kit-acct-b`, Straddle ID `22222222-2222-4222-8222-222222222222`.
- Charge or payout for each, with the evidence that proves the account on each result: charge `order-a-0001` on A and `order-b-0001` on B; each charge's FIFO event carries its `account_id`.
- Header-omitted operations verified omitted: customer, paykey, organization, and account calls.

## Onboarding (SaaS and marketplace)

- Sandbox testing: accounts created through the API after preview and approval.
- Customer-facing: hosted iframe with `env=sandbox` and a required `externalId`; account resolved through the notification path or an exact external-ID lookup.

## Notifications

- Endpoint type and events subscribed: FIFO endpoint `POST /webhooks/straddle/fifo` on the app's public HTTPS URL; `customer.event.v1`, `paykey.event.v1`, `charge.event.v1`, `funding_event.created.v1`, `funding_event.event.v1`.
- Signature verification helper and raw-body access (FIFO: `svix-*` headers): `client.webhooks.unwrap` (`resources/webhooks.d.ts:11`) on the raw body, always passing the request's `svix-*` headers, since it skips verification without them.
- FIFO body shape, from a captured delivery or the dashboard's transformation test output: captured from the dashboard's transformation test output before the parser is written.
- Duplicate handling (event ID storage): store each `event_id`; drop repeats.
- Acknowledgement: `2xx` after the whole batch commits, `500` otherwise so the batch is retried whole.
- Status transitions to record, including `paid` then `reversed` with `R01`, ordered by `changed_at` with delivery order breaking a tie (best-practices receiving-webhooks reference, Ordering status changes): `created`, `scheduled`, `pending`, `paid`, `on_hold`, `failed`, `cancelled`, `reversed`.

## Lifecycle handling

| Resource | Status or event | What the app does | Decision | Reference |
| --- | --- | --- | --- | --- |
| Customer | `review`, `rejected` | `review` holds the order; `rejected` asks for another payment method | Q6 | `customers-identity.md` |
| Paykey | `review`, `rejected`, `blocked` (R29) and the one-time unblock, `inactive` | `review` holds the order; `rejected`, `blocked` and `inactive` ask for another bank account | Q6 | `bridge-and-paykeys.md` |
| Charge | `paid` | marks the order paid | Q1 | `charges.md` |
| Charge | `failed`, and `reversed` after `paid` (R01, disputes) | `failed` marks the order unpaid; `reversed` marks it `returned`, tells the seller, records the code | Q7 | `returns-and-disputes.md` |
| Charge | `on_hold`, `cancelled` | `on_hold` shows the order as held; `cancelled` marks it unpaid | Q6 | `charges.md` |
| Funding event | `charge_deposit`, `charge_reversal` | records the movement against the seller's account | Q11 | `funding-and-reconciliation.md` |
| Account (platforms) | `onboarding`, `active`, `rejected` | charges only on an `active` seller account | Q5 | `platforms.md` |

## Configuration

- `STRADDLE_API_KEY` read from the process environment; a missing key or environment raises a configuration error before any request.
- Environment: Sandbox (`https://sandbox.straddle.com`), from `STRADDLE_ENVIRONMENT`.

## File changes

Only these files may change.

| File | Existing or new | Change | Behavior proved | Test |
| --- | --- | --- | --- | --- |
| src/straddle/client.mjs | existing | SDK client factory that reads `STRADDLE_API_KEY` and `STRADDLE_ENVIRONMENT` and sets `Straddle-Account-Id` per call | missing key or account fails before any request | `test/straddle/payments.test.mjs` |
| src/straddle/payments.mjs | existing | `payOrder` creates the charge for the seller account through `client.charges.create` | header per seller account; same idempotency key on retry | `test/straddle/payments.test.mjs` |
| src/straddle/fifo.mjs | new | FIFO receiver: verifies, stores the batch in order, drops duplicates, maps statuses | duplicate dropped; `2xx` only after the batch commits | `test/straddle/fifo.test.mjs` |
| test/straddle/payments.test.mjs | new | client and charge tests with a stubbed SDK | the rows above | itself |
| test/straddle/fifo.test.mjs | new | receiver tests fed recorded batches | the row above | itself |

## Future Sandbox writes

Each row runs later, in Integrate or Test, only after its own preview and approval. Creates send an Idempotency-Key and an external ID.

| Order | Operation | Executing tool | Account | External ID | Idempotency key source |
| --- | --- | --- | --- | --- | --- |
| 1 | Reuse or create organization `acme-kit-org` | SDK `client.organizations.create` | omitted (organization) | `acme-kit-org` | `org-` + external ID |
| 2 | Reuse or create accounts A and B under that organization | SDK `client.accounts.create` | omitted (account management) | `acme-kit-acct-a`, `acme-kit-acct-b` | `acct-` + external ID |
| 3 | Create buyer customer, sandbox outcome `verified` | SDK `client.customers.create` | omitted | `acme-kit-buyer-1` | `cust-` + external ID |
| 4 | Create bank-account paykey for the buyer, sandbox outcome `active` | SDK `client.bridge.createBankAccountPaykey` | omitted | `acme-kit-buyer-1-bank` | `pk-` + external ID |
| 5 | Reveal the buyer paykey's full token for the charges, in process and never printed | SDK `client.paykeys.reveal` | omitted | none (a read) | none (a read) |
| 6 | Create charge for seller A, sandbox outcome `paid` | SDK `client.charges.create` | account A | `order-a-0001` | `chg-` + external ID |
| 7 | Create charge for seller B, sandbox outcome `reversed_insufficient_funds` | SDK `client.charges.create` | account B | `order-b-0001` | `chg-` + external ID |
| 8 | Simulate the charges funding sweep for account B, after `order-b-0001` is `pending` | SDK `client.fundingEvents.simulate` | account B | none (a simulation) | `sim-acme-kit-acct-b` |

## Verification

- Repository tests and the test command: `npm test`.
- Retry with the same idempotency key: a repeated charge create with `chg-order-a-0001` returns the first charge.
- Two-account proof (SaaS and marketplace): `order-a-0001` on account A and `order-b-0001` on account B, each event's `account_id` checked.
- Notification proof (one signed event received, duplicate ignored): one FIFO batch verified and stored, then the same batch again stores nothing new.
- Payout handlers, refund payouts included (`paid`, `failed`, `reversed`): none; payouts aren't in this plan.

Sandbox scenarios: the rows of the scenario matrix in the best-practices `sandbox-outcomes.md` (What your app must handle) for each lifecycle this plan covers.

| Scenario | Create with | Must observe through the notification path | Proves |
| --- | --- | --- | --- |
| Happy path | customer `verified`, paykey `active`, charge `paid` | `paid` | Fulfillment |
| Return after paid | charge `reversed_insufficient_funds`, with the funding sweep row | `paid`, then `reversed` with R01 | Clawback after fulfillment |

## Unresolved decisions

- None.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- Existing provider code stays unless a separate migration plan authorizes it.
- Every Sandbox write needs its own preview and approval at the time it runs.
- The fourteen excluded operations run only through the SDK or the Straddle CLI.
EOF_6
cat > src/straddle/client.mjs <<'EOF_7'
// Straddle SDK client (implemented by Integrate).
export {};
EOF_7
cat > src/straddle/payments.mjs <<'EOF_8'
// Straddle payments (implemented by Integrate).
export {};
EOF_8
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
