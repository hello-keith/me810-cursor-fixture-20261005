#!/usr/bin/env bash
set -euo pipefail
mkdir -p src
cat > package.json <<'JSON'
{
  "name": "acme-marketplace",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" },
  "dependencies": { "@straddlecom/straddle": "1.0.4", "express": "4.21.2" }
}
JSON
cat > src/server.ts <<'TS'
import express from "express";

const app = express();
app.use(express.json());

app.post("/orders/:id/pay", async (req, res) => {
  // TODO: collect payment for the order from the buyer's bank account.
  res.status(501).json({ error: "not implemented" });
});

app.listen(3000);
TS
cat > AGENTS.md <<'MD'
Run tests with `npm test`. Keep handlers in src/.
MD
npm install --ignore-scripts --no-audit --no-fund --silent @straddlecom/straddle@1.0.4
