---
type: regex
target: { source: file, path: straddle-integration-plan.md }
pattern: '^- Plan state: Approved[ \t]*\n- Approval: \d{4}-\d{2}-\d{2}, "[^"\n]+", recorded by straddle-plan, sha256 a59b22c8a8be9b200d1a79d3088ad3fc13acb7af119fa7dae8924cb7d548047c[ \t]*$'
flags: m
arm: with-only
---
