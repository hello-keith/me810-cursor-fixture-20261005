---
type: regex
target: { source: file, path: straddle-integration-plan.md }
pattern: '^- Plan state: Approved[ \t]*\n- Approval: \d{4}-\d{2}-\d{2}, "[^"\n]+", recorded by straddle-plan, sha256 2b239a6c1e60721ebb6113a9bcbc97a5faf9af3b25377a82a7c6753a3ee59acc[ \t]*$'
flags: m
arm: with-only
---
