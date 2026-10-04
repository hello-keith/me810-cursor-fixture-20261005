---
type: regex
target: { source: file, path: straddle-integration-plan.md }
pattern: '^- Plan state: Approved[ \t]*\n- Approval: \d{4}-\d{2}-\d{2}, "[^"\n]+", recorded by straddle-plan, sha256 08c8b232edd8e6fb49771ac8a51b795fe41575939794006e3a0cd6746ece05c9[ \t]*$'
flags: m
arm: with-only
---
