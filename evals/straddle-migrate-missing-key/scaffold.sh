#!/usr/bin/env bash
# Eval-only scaffold: writes a small fixture repository, commits it, and installs a
# Straddle CLI stand-in at ./bin/straddle. The stand-in prints fixed offline outputs,
# logs every call, and refuses network commands. It never runs the real CLI.
set -euo pipefail
mkdir -p bin src
cat > package.json <<'EOF'
{
  "name": "tutorly",
  "private": true,
  "scripts": { "test": "node --test test/" },
  "dependencies": { "express": "^4.19.2", "stripe": "^17.2.0" }
}
EOF
cat > src/stripeAch.ts <<'EOF'
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function collectTuition(customerId: string, paymentMethodId: string, amountCents: number, invoiceId: string) {
  return stripe.paymentIntents.create(
    { amount: amountCents, currency: 'usd', customer: customerId, payment_method: paymentMethodId, payment_method_types: ['us_bank_account'], confirm: true },
    { idempotencyKey: `tuition-${invoiceId}` },
  );
}
EOF
printf 'bin/\n.straddle-fixture-calls.log\n' > .gitignore
git init -q
git add -A
git -c user.name=eval -c user.email=eval@example.invalid commit -qm "fixture"
: > .straddle-fixture-calls.log
cat > bin/straddle <<'STUB'
#!/usr/bin/env bash
root="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s\n' "$*" >> "$root/.straddle-fixture-calls.log"
case "$*" in
  "--version"|"version")
    echo "straddle v1.0.3" ;;
  "auth status --agent"|"auth status --json")
    cat <<'JSON'
{
  "authenticated": false,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "",
  "verified": false
}
JSON
    echo 'Error: no credentials configured' >&2; exit 4 ;;
  *doctor*|*accounts*)
    echo "eval fixture: network commands are refused in this case" >&2
    exit 97 ;;
  *)
    echo "eval fixture: unsupported command: $*" >&2
    exit 2 ;;
esac
STUB
chmod +x bin/straddle
