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
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
