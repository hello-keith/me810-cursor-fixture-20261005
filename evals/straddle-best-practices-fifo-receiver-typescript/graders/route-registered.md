---
type: llm
focus: { source: file, path: src/server.ts }
---

You see only src/server.ts. PASS if all hold: it imports the FIFO receiver from `./fifo` (with or without an extension) and registers it on `app` for `POST /webhooks/straddle/fifo`, where any path or mount prefix written in this file is that path or a leading part of it; and the route still gets the unparsed request bytes, because the app-wide `express.json()` is registered after the receiver, skips that path, or keeps the raw bytes (for example `express.json({ verify })` saving the buffer), or a raw parser for that path is registered before it.
FAIL if the receiver isn't imported or registered, is registered under a different path or prefix, or the app-wide `express.json()` runs on that path first without keeping the raw bytes, so the body reaching verification is already parsed.
