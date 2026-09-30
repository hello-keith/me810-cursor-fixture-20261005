---
type: regex
target: { source: file, path: straddle-setup.md }
pattern: '^Status: blocked \([^\n]*\)\s*\n[\s\S]*^API key present: no\b'
flags: m
arm: with-only
---
