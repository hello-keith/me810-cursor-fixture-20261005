---
type: regex
target: { source: file, path: straddle-integration-plan.md }
pattern: '^- Plan state: Approved[ \t]*\n- Approval: \d{4}-\d{2}-\d{2}, "[^"\n]+", recorded by straddle-plan, sha256 c806cebea91f26ebc354bb7edfa2182ed2f62e1191c228ae0c57c10d74b5262f[ \t]*$'
flags: m
arm: with-only
---
