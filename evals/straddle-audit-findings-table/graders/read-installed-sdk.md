---
type: regex
target: trace
pattern: '"name":"(?:Read|Grep)","input":\{[^{}]*node_modules/@straddlecom/straddle/|"name":"Bash","input":\{"command":"(?=(?:[^"\\]|\\.)*node_modules/@straddlecom/straddle(?:/|[ ;&|]))(?:[^"\\]|\\.)*\b(?:cat|sed|head|tail|grep)\b'
arm: both
---

The run reads the installed SDK source with Read or Grep, or with a Bash command that names the package directory and runs `cat`, `sed`, `head`, `tail` or `grep`. The Bash branch checks that both appear in one command, not that the read command's argument is inside the package.
