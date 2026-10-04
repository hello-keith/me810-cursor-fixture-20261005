---
type: regex
target: trace
pattern: '"role":"assistant","content":\[\{"type":"text","text":"(?:[^"\\]|\\.)*configuration error'
flags: i
---

The configuration error may appear in any assistant reply in the run, not only the final message. The pattern reads only assistant text blocks, so skill files echoed in tool results or the skill load never match.
