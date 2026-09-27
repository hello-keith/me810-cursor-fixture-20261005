#!/usr/bin/env bash
# Eval-only scaffold: installs a Straddle CLI stand-in at ./bin/straddle.
# The stand-in prints fixed offline outputs, logs every call, and refuses
# network commands. It never runs the real CLI or opens a connection.
set -euo pipefail
mkdir -p bin
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
  "agent-context"|"agent-context --pretty")
    cat <<'JSON'
{
  "schema_version": "4",
  "cli": {
    "name": "straddle",
    "version": "v1.0.3"
  },
  "runtime_context": {
    "environment": "https://sandbox.straddle.com",
    "integration_type": "saas",
    "acting_account": null
  }
}
JSON
    ;;
  *doctor*|*accounts*)
    echo "eval fixture: network commands are refused in this case" >&2
    exit 97 ;;
  *)
    echo "eval fixture: unsupported command: $*" >&2
    exit 2 ;;
esac
STUB
chmod +x bin/straddle
