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
mkdir -p consumer
cat > go.mod <<'MOD'
module example.com/ledger

go 1.22
MOD
cat > consumer/store.go <<'GO'
package consumer

import "context"

// Store saves events. SaveBatch inserts them in order in one transaction,
// skipping event IDs already stored. A duplicate-only batch succeeds; any write failure rolls back the batch and returns an error.
type Store interface {
	SaveBatch(ctx context.Context, events []Event) error
}

type Event struct {
	EventID   string
	EventType string
	AccountID string
	Body      []byte
}
GO
cat > straddle-integration-plan.md <<'PLAN'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-10-02, "The plan is approved.", recorded by straddle-plan, sha256 54dd43673b53bfd2db47ff6623ab1117b14554c94a910330d0db1145a56a8136
- Last reviewed: 2026-10-02
- Repository and branch: ledger, main
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: none; no Straddle SDK calls in this code-only change

## Goal

Pull events from the polling endpoint already created in the Sandbox dashboard, because the service can't expose a public URL, and store them with `Store.SaveBatch`. Code only: no Straddle writes.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct | developer |
| Products | events only in this change | developer |
| SDK | Go | developer |
| Notification path | polling endpoint; consumer URL in `STRADDLE_POLLING_URL`, token in `STRADDLE_POLLING_TOKEN` | developer, Sandbox dashboard |

## Repository evidence

- Language and module: Go 1.22, module example.com/ledger
- Test command: none configured
- Entry points: consumer/store.go defines `Store` with `SaveBatch`, which inserts events in order in one transaction and skips stored event IDs. A duplicate-only batch succeeds; any write failure rolls back the batch and returns an error.

## Notifications

- Endpoint type: polling endpoint, created in the Sandbox dashboard because the service can't expose a public URL
- Consumer URL and token: `STRADDLE_POLLING_URL` and `STRADDLE_POLLING_TOKEN` in the process environment
- Storage: `Store.SaveBatch` in consumer/store.go

## File changes

| File | Existing or new | Change |
| --- | --- | --- |
| consumer/consumer.go | new | implement the consumer as `Run(ctx context.Context, store Store) error` in package consumer |

## Future Sandbox writes

None. The polling endpoint already exists in the Sandbox dashboard.

## Unresolved decisions

- None.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- No Straddle request runs as part of this plan.
PLAN
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
