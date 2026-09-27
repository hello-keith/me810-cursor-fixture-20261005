#!/usr/bin/env bash
set -euo pipefail

# Eval-only CLI stand-in at ./bin/straddle: fixed offline outputs, every call logged,
# network commands refused. It never runs the real CLI or opens a connection.
mkdir -p bin
: > .straddle-fixture-calls.log
cat > bin/straddle <<'STUB'
#!/usr/bin/env bash
root="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s\n' "$*" >> "$root/.straddle-fixture-calls.log"
case "$*" in
  "--version"|"version")
    echo "straddle v1.0.3" ;;
  "auth status --json"|"auth status --agent")
    cat <<'JSON'
{
  "authenticated": false,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "",
  "verified": false
}
JSON
    echo 'Error: no credentials configured' >&2; exit 4 ;;
  "agent-context"|"agent-context --pretty")
    cat <<'JSON'
{
  "schema_version": "4",
  "cli": { "name": "straddle", "version": "v1.0.3" },
  "runtime_context": {
    "environment": "https://sandbox.straddle.com",
    "integration_type": "account",
    "acting_account": null
  }
}
JSON
    ;;
  *doctor*|*accounts*|*charges*|*payouts*|*customers*|*paykeys*|*api*|*data-source*|*sync*)
    echo "eval fixture: network commands are refused in this case" >&2
    exit 97 ;;
  *)
    echo "eval fixture: unsupported command: $*" >&2
    exit 2 ;;
esac
STUB
chmod +x bin/straddle
