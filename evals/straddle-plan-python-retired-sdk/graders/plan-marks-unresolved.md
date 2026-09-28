---
type: regex
target: { source: file, path: straddle-integration-plan.md }
pattern: '(?:bank connection|bank account connection|Bridge)[^\n]{0,80}\bunresolved\b|\bunresolved\b[^\n]{0,80}(?:bank connection|bank account connection|Bridge)'
flags: i
---
