---
type: regex
target: { source: file, path: straddle-migration-report.md }
pattern: '^Status: awaiting_approval(?: \([^\n]*\))?\s*\nPlan: straddle-migration-plan\.md\s*\nPlan hash: none\b'
flags: m
arm: with-only
---
