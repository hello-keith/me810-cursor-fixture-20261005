---
type: regex
target: trace
pattern: '(?<!\x27)(?<!\\")(?:Connection error\.|TypeError: fetch failed|connect ECONNREFUSED [^\s"\\]+|dial tcp [^\s"\\]+: connect)'
match: not_contains
arm: both
---
