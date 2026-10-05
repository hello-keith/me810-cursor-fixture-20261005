---
type: regex
target: { source: file, path: .dues-verify.txt }
pattern: '^Test Run Successful\.\nTotal tests: 5\n\s+Passed: 5\n'
flags: m
arm: with-only
---
