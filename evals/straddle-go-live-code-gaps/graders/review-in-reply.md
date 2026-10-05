---
type: regex
target: last_message
pattern: '^\**Status:\**[ \t]*not ready \([^\n]*\)[\s\S]*^[ \t]*[-*] \[ \] '
flags: m
arm: with-only
---

The final reply carries the review itself, from its `Status` line through the unchecked checklist, not only a pointer to `straddle-go-live-report.md`.
