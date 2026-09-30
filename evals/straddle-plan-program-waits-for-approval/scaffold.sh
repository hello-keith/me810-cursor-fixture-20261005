#!/usr/bin/env bash
set -euo pipefail
mkdir -p src
printf 'node_modules/\n' > .gitignore
cat > package.json <<'JSON'
{ "name": "club-dues", "private": true, "type": "module", "scripts": { "test": "node --test" }, "dependencies": { "@straddlecom/straddle": "1.0.4" } }
JSON
cat > AGENTS.md <<'MD'
Run tests with `npm test`. Application code lives in src/.
MD
cat > README.md <<'MD'
# Club dues

Collects monthly membership dues for one sports club. Straddle Pay by Bank is being added as a direct integration. Nothing is wired yet.
MD
cat > src/server.mjs <<'JS'
import { createServer } from "node:http";

// TODO: collect a member's monthly dues by bank through Straddle.
createServer((req, res) => {
  res.statusCode = 501;
  res.end("not implemented");
}).listen(3000);
JS
cat > straddle-setup.md <<'MD'
# Straddle Setup report

Status: complete
Environment: https://sandbox.straddle.com, explicitly selected (env var)
Integration type: account
API key present: yes (env var), not verified
SDK: @straddlecom/straddle 1.0.4
Acting account: not required
Setup result: ready_with_warnings

| Check | Result | Evidence |
| --- | --- | --- |
| Authenticated request (CLI) | not run (developer asked for no Straddle request) | `straddle accounts list` |
| SDK | @straddlecom/straddle 1.0.4 | package-lock.json |

## Blocking

None.

## Warnings

- Authenticated checks not run.
MD
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
