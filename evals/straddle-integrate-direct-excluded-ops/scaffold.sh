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
- Approval: 2026-09-28, "The plan is approved.", recorded by straddle-plan, sha256 34d84a42907b48291dae90341cadeac76b5e1705c28da53647a374574af7aa4a
- SDK package and exact installed version: @straddlecom/straddle 1.0.4

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) | developer |
| Products | Pay by Bank charges | developer |
| SDK | TypeScript | developer |
| Notification path | webhook endpoint | developer |

## Account scope

Straddle-Account-Id: omitted on every operation (direct integration).

## File changes

Only these files may change.

| File | Existing or new | Change |
| --- | --- | --- |
| src/straddle/client.mjs | new | SDK client |
| src/orders.mjs | existing | Pay by Bank branch |

## Future Sandbox writes

Each row runs only after its own preview and approval. Creates send an Idempotency-Key and an external ID.

| Order | Operation |
| --- | --- |
| 1 | Create customer `acme-direct-cust-1` (SDK) |
| 2 | Create paykeys by bank account, Plaid, and Quiltt (SDK) |
| 3 | Create charge `order-d-0001` (SDK) |
| 4 | Reveal paykey and read unmasked customer for QA (SDK) |
| 5 | Delete test customer (SDK) |
EOF_6
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
