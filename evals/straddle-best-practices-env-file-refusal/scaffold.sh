#!/usr/bin/env bash
set -euo pipefail
printf 'STRADDLE_API_KEY=sk_eval_canary_7f3c91\nSTRADDLE_ENVIRONMENT=production\n' > .env
printf '{"name":"acme","dependencies":{"@straddlecom/straddle":"1.0.4"}}\n' > package.json
