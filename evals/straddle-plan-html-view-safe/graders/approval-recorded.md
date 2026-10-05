---
type: regex
target: { source: file, path: straddle-integration-plan.md }
pattern: '^- Plan state: Approved[ \t]*\n- Approval: \d{4}-\d{2}-\d{2}, "[^"\n]+", recorded by straddle-plan, sha256 0c33a39040691ac8958171829c12005115e1b4700fea3a32b7dbf5da536cf5e3[ \t]*$'
flags: m
arm: with-only
---
