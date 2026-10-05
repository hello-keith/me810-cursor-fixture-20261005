---
type: regex
target: { source: file, path: .straddle-fixture-calls.log }
pattern: '(^|\s)(doctor|accounts)(\s|$)'
flags: m
match: not_contains
arm: both
---
