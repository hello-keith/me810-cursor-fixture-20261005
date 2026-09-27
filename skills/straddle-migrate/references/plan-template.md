# Straddle migration plan

Status: draft | approved
Provider: `<provider>`
Integration model: `<direct / SaaS / marketplace / Unresolved>`
SDK: `<package and version / Unresolved>`
Notification path: `<webhook endpoint / FIFO endpoint / polling endpoint / Unresolved>`
Switch: `<flag or setting name, default>`

## Current provider footprint

| Call site | Flow | Provider API |
| --- | --- | --- |
| `path:line` | | |

## Flows in scope

| Flow | Straddle operation | Account scope | Doc citation |
| --- | --- | --- | --- |

## Authorized modifications

Only these files change. Each change is additive.

| # | Path | Change | What is added | Flow / call site |
| --- | --- | --- | --- | --- |
| 1 | | create / modify (additive) | | |

## Blocked

Files that need a change but had uncommitted work, or changes this skill does not make (delete, rename, replace).

## Not moved

Customer records, bank accounts, provider tokens, mandates, and payment history stay with `<provider>`. This plan does not export, copy, or re-create them in Straddle.

## Verification

- Test command: `<command>`
- New tests: `<paths>`
- Sandbox proof: run straddle-test after review.

## Unresolved

## Approval

`<date>`, developer's words, rows approved. Any later change to this file voids this entry.
