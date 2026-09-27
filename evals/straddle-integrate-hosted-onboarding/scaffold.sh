#!/usr/bin/env bash
set -euo pipefail
mkdir -p src src/legacy src/lib
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

- Plan state: Approved
- SDK package and exact installed version: @straddlecom/straddle 1.0.4

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | SaaS | developer |
| Products | Pay by Bank charges | developer |
| SDK | TypeScript | developer |
| Notification path | webhook endpoint | developer |

## Accounts

- Account A: external ID `acme-kit-acct-a`, Straddle ID `11111111-1111-4111-8111-111111111111`
- Account B: external ID `acme-kit-acct-b`, Straddle ID `22222222-2222-4222-8222-222222222222`
## Account scope

Straddle-Account-Id: required on customer, Bridge paykey, charge, and payout creation; sent on other customer, paykey, charge, and payout operations when an account is selected; omitted on organization and account management.

## File changes

Only these files may change.

| File | Existing or new | Change |
| --- | --- | --- |
| src/onboarding/page.mjs | new | server-rendered seller onboarding page with the hosted iframe |
| src/onboarding/accounts.mjs | new | resolve a seller's Straddle account by exact external ID or account event |## Future Sandbox writes

Each row runs only after its own preview and approval. Creates send an Idempotency-Key and an external ID.

| Order | Operation |
| --- | --- |
| 1 | None for onboarding: the seller completes the hosted form |

## Onboarding

- Customer-facing: hosted iframe, `env=sandbox`, required external ID per seller; platform ID from `STRADDLE_PLATFORM_ID`.
EOF_6
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
