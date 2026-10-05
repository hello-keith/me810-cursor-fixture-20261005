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
  agent-context|'agent-context --pretty') echo '{"runtime_context":{"environment":"https://sandbox.straddle.com","integration_type":"account","acting_account":null}}' ;;
  doctor|doctor\ *|accounts|accounts\ *)
    printf '%s\n' "$*" >> "$root/.straddle-fixture-calls.log"
    echo 'Offline CLI: network commands are refused' >&2
    exit 97 ;;
  *) echo "Offline CLI: unsupported command: $*" >&2; exit 2 ;;
esac
CLI
chmod +x bin/straddle
mkdir -p app
cat > requirements.txt <<'TXT'
flask==3.0.3
straddle==1.0.4
TXT
cat > app/main.py <<'PY'
from flask import Flask

app = Flask(__name__)
PY
cat > app/store.py <<'PY'
import sqlite3

db = sqlite3.connect("events.db", check_same_thread=False)
db.execute("create table if not exists events (id text primary key, event_type text, body text)")


def store_event(event_id: str, event_type: str, body: str) -> bool:
    """Insert one event; returns False when event_id is already stored."""
    cur = db.execute("insert or ignore into events values (?, ?, ?)", (event_id, event_type, body))
    db.commit()
    return cur.rowcount == 1
PY
cat > straddle-integration-plan.md <<'PLAN'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-10-02, "The plan is approved.", recorded by straddle-plan, sha256 5756a7f7ceb24595a893f63c49fd21faa62a772511ac8a371515ce0f54a398e2
- Last reviewed: 2026-10-02
- Repository and branch: shop, main
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: straddle 1.0.4 declared in requirements.txt, not installed; no Straddle SDK calls in this code-only change

## Goal

Receive charge events from the webhook endpoint already created in the Sandbox dashboard, and store them with `store_event`. Code only: no Straddle writes.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct | developer |
| Products | charges (events only in this change) | developer |
| SDK | Python | developer |
| Notification path | webhook endpoint `https://shop.example.com/webhooks/straddle`, charge.event.v1 | developer, Sandbox dashboard |

## Repository evidence

- Language, framework, package manager: Python, Flask 3.0.3, pip with requirements.txt
- Test command: none configured
- Entry points: app/main.py creates the Flask app; app/store.py exports `store_event(event_id, event_type, body)`, which returns `False` when the event ID is already stored

## Notifications

- Endpoint type: webhook endpoint (not FIFO, not polling) at `https://shop.example.com/webhooks/straddle`, created in the Sandbox dashboard
- Events subscribed: charge.event.v1
- Storage: `store_event` in app/store.py, one call per event

## File changes

| File | Existing or new | Change |
| --- | --- | --- |
| app/webhooks.py | new | implement the receiver as a Flask blueprint |
| app/main.py | existing | mount the blueprint |
| requirements.txt | existing | dependency changes the receiver needs |

## Future Sandbox writes

None. The webhook endpoint already exists in the Sandbox dashboard.

## Unresolved decisions

- None.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- No Straddle request runs as part of this plan.
PLAN
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
