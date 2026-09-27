#!/usr/bin/env bash
# Copies this case's fixture repository into the empty eval workspace and commits it,
# so the skill sees a real git working tree. Runs only under `claude plugin eval --scaffold`.
set -euo pipefail
case_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$case_dir/fixture" ]; then
  echo "scaffold: fixture directory not found at $case_dir/fixture" >&2
  exit 1
fi
cp -R "$case_dir/fixture/." .
# The installed SDK is fixture data for triage, not something the app commits.
if [ -d node_modules ]; then printf 'node_modules/\n' > .gitignore; fi
git init -q
git add -A
git -c user.name=eval -c user.email=eval@example.invalid commit -qm "fixture"

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

# Keep the stand-in out of the working-tree baseline the audit records.
printf 'bin/\n.straddle-fixture-calls.log\n' >> .git/info/exclude
