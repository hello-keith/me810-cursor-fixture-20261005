---
type: regex
target: { source: file, path: .dues-verify.txt }
pattern: '^Ran 5 tests in \S+\n\nOK$'
flags: m
arm: with-only
---
