---
type: regex
target: { source: file, path: .straddle-fixture-calls.log }
pattern: '(^|\s)(doctor|accounts|charges|payouts|customers|paykeys|api|sync)(\s|$)|--data-source'
flags: m
match: not_contains
arm: both
---

The CLI stand-in logs every call; none may be a command that would reach Straddle.
