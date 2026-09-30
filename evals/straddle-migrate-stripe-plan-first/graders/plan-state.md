---
type: regex
target: { source: file, path: straddle-migration-plan.md }
pattern: '^- Plan state: (?:Draft|Blocked)\s*\n- Approval: none\b'
flags: m
arm: with-only
---
