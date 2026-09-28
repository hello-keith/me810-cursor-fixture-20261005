---
type: regex
target: { source: file, path: straddle-test-evidence.md }
pattern: 'synthetic-test-key|whsec_[A-Za-z0-9+/]{10,}|Bearer\s+[A-Za-z0-9_.-]{10,}'
match: not_contains
---
