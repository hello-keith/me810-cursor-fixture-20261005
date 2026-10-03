---
type: regex
target: { source: file, path: straddle-integration-plan.md }
pattern: '^- Plan state: Approved[ \t]*\n- Approval: \d{4}-\d{2}-\d{2}, "[^"\n]+", recorded by straddle-plan, sha256 80635e87994208cb135564c1078aa5eaf4a1bf45fc6844950b8440a9be5ff75d[ \t]*$'
flags: m
arm: with-only
---
