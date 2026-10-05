---
type: regex
target: { source: file, path: .dues-verify.txt }
pattern: '^-{3} PASS: TestFixtureARetryReusesItsKey \([^)]*\)\nPASS\nok\s+example\.com/dues/dues\s'
flags: m
arm: with-only
---
