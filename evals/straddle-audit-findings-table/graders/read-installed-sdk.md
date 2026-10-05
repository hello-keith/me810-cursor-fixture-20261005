---
type: regex
target: trace
pattern: '"name":"(?:Read|Grep)","input":\{(?:"[\w-]+":(?:"(?:[^"\\]|\\.)*"|[^,{}"]*),)*"(?:file_path|path)":"(?:[^"\\]|\\.)*?node_modules/@straddlecom/straddle/|"name":"Bash","input":\{"command":"(?:(?:[^"\\]|\\.)*?(?:;|&&|\\n|\$\(|\bdo\s|\bthen\s))?\s*(?:(?:cat|sed|head|tail|grep)\b(?:[^;|&"\\]|\\[^n])*?\s(?:\x27|\\")?(?:[^\s"\x27\\;|&]*/)?node_modules/@straddlecom/straddle/|cd\s+(?:\x27|\\")?(?:[^\s"\x27\\;|&]*/)?node_modules/@straddlecom/straddle(?:/[^\s"\x27\\;|&]*)?(?:\x27|\\")?\s*(?:;|&&|\\n)(?:(?:(?!\bcd\s)(?:[^"\\]|\\.))*?(?:;|&&|\\n|\$\(|\bdo\s|\bthen\s))?\s*(?:cat|sed|head|tail|grep)\b)'
arm: both
---

The run reads the installed SDK source: a Read `file_path` or Grep `path` inside `node_modules/@straddlecom/straddle/`, or a Bash command that runs `cat`, `sed`, `head`, `tail` or `grep` either on a path inside the package or after `cd` into it. Listing the package, a piped `| head`, or grepping `package-lock.json` for the package name is not a read.
