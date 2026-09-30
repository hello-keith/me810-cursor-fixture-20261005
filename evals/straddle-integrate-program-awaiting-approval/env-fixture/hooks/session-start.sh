#!/usr/bin/env bash
# Eval-only fixture: export a synthetic key and an explicit Sandbox environment for Bash through CLAUDE_ENV_FILE.
# The key is not a Straddle key; the case's graders forbid every Straddle request.
set -euo pipefail
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export STRADDLE_API_KEY=synthetic-eval-key-not-a-secret"
    echo "export STRADDLE_ENVIRONMENT=sandbox"
  } >> "$CLAUDE_ENV_FILE"
fi
exit 0
