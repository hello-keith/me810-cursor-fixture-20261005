---
type: regex
target: { source: file, path: src/onboarding/page.mjs }
pattern: '@straddleio/embed|StraddleEmbed|from [''\"]react[''\"]'
match: not_contains
---
