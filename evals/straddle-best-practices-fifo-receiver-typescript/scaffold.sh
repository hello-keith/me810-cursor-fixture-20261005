#!/usr/bin/env bash
set -euo pipefail
mkdir -p bin
: > .straddle-fixture-calls.log
printf '%s\n' '.straddle-fixture-calls.log' > .gitignore
cat > bin/straddle <<'CLI'
#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
for arg in "$@"; do
  if [[ "$arg" == --help || "$arg" == -h ]]; then
    echo 'Offline CLI: --version, auth status --agent, agent-context'
    exit 0
  fi
done
while [[ "${1:-}" == --agent || "${1:-}" == --json || "${1:-}" == --no-input || "${1:-}" == --yes ]]; do shift; done
case "$*" in
  --version|version) echo 'straddle v1.0.3' ;;
  'auth status --agent'|'auth status --json') echo '{"authenticated":false,"source":null,"verified":false}' ;;
  agent-context|'agent-context --pretty') echo '{"runtime_context":{"environment":"https://sandbox.straddle.com","integration_type":"saas","acting_account":null}}' ;;
  doctor|doctor\ *|accounts|accounts\ *)
    printf '%s\n' "$*" >> "$root/.straddle-fixture-calls.log"
    echo 'Offline CLI: network commands are refused' >&2
    exit 97 ;;
  *) echo "Offline CLI: unsupported command: $*" >&2; exit 2 ;;
esac
CLI
chmod +x bin/straddle
mkdir -p src
cat > package.json <<'JSON'
{
  "name": "acme-platform",
  "private": true,
  "type": "module",
  "dependencies": { "@straddlecom/straddle": "1.0.4", "express": "4.21.2" }
}
JSON
cat > src/server.ts <<'TS'
import express from "express";

export const app = express();
app.use(express.json());

app.listen(3000);
TS
cat > src/store.ts <<'TS'
export type StoredEvent = { eventId: string; eventType: string; accountId: string; body: unknown };

// Inserts every event in one transaction, in the given order, skipping event IDs already stored.
// Throws and inserts nothing when any write fails.
export async function saveEvents(events: StoredEvent[]): Promise<void> {
  throw new Error("wire to the database");
}
TS
cat > straddle-integration-plan.md <<'PLAN'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-10-02, "The plan is approved.", recorded by straddle-plan, sha256 c0a668651832a3cabda2549904c316a3ed0c213b8016d44b8af089fe2cb7bef5
- Last reviewed: 2026-10-02
- Repository and branch: acme-platform, main
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: @straddlecom/straddle 1.0.4 declared in package.json, not installed; no Straddle SDK calls in this code-only change

## Goal

Receive the platform's charge and payout events from the FIFO endpoint already created in the Sandbox dashboard, and store them with `saveEvents`. Code only: no Straddle writes.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | SaaS platform | developer |
| Products | charges, payouts (events only in this change) | developer |
| SDK | TypeScript | developer |
| Notification path | FIFO endpoint `https://api.example.com/webhooks/straddle/fifo`, default transformation, charge.event.v1 and payout.event.v1 | developer, Sandbox dashboard |

## Repository evidence

- Language, framework, package manager: TypeScript, Express 4.21.2, npm with package.json
- Test command: none configured
- Entry points: src/server.ts creates the Express app; src/store.ts exports `saveEvents`, which stores events in one transaction, in order, skipping stored event IDs, and throws without storing anything when a write fails

## Notifications

- Endpoint type: FIFO endpoint at `https://api.example.com/webhooks/straddle/fifo`, created in the Sandbox dashboard with its default transformation
- Events subscribed: charge.event.v1, payout.event.v1
- Delivery shape, from the dashboard's transformation test on a two-event batch: `{"data":[{"payload":{...},"eventType":"..."}]}`
- Storage: `saveEvents` in src/store.ts

## File changes

| File | Existing or new | Change |
| --- | --- | --- |
| src/fifo.ts | new | implement the FIFO receiver route |
| src/server.ts | existing | register the FIFO route |
| package.json | existing | dependency changes the receiver needs |

## Future Sandbox writes

None. The FIFO endpoint already exists in the Sandbox dashboard.

## Unresolved decisions

- None.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- No Straddle request runs as part of this plan.
PLAN
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
