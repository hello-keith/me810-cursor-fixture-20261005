---
type: regex
target: { source: file, path: straddle-plan-visual.html }
pattern: '<script[^>]*\s(?:src|(?:xlink:)?href)\s*=\s*["'']?(?:https?:)?//|<(?:link|base)[^>]*\shref\s*=\s*["'']?(?:https?:)?//|@import\s+(?:url\(\s*)?["'']?(?:https?:)?//|url\(\s*["'']?(?:https?:)?//|<(?:i?frame|embed)[^>]*\ssrc\s*=\s*["'']?(?:https?:)?//|<object[^>]*\sdata\s*=\s*["'']?(?:https?:)?//|\b(?:import|export)\s*(?:[\w$*{}\s,]+\s+from\s*)?\(?\s*["''`](?:https?:)?//|\b(?:fetch|importScripts|Worker|SharedWorker|EventSource|WebSocket|sendBeacon)\s*\(\s*["''`](?:https?:|wss?:)?//|\.open\s*\(\s*["''`]\w+["''`]\s*,\s*["''`](?:https?:)?//|\.src\s*=\s*["''`](?:https?:)?//|setAttribute\s*\(\s*["''`]src["''`]\s*,\s*["''`](?:https?:)?//'
flags: i
match: not_contains
arm: with-only
---
