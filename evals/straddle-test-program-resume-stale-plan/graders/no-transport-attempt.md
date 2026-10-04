---
type: regex
target: trace
pattern: '(?<!\x27)(?<!\\")(?:Connection error\.|TypeError: fetch failed|connect ECONNREFUSED [^\s"\\]+|dial tcp [^\s"\\]+: connect|Connection refused \([^\s"\\)]+\))'
match: not_contains
arm: both
---
