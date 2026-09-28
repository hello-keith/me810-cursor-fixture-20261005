# Step 6: Evidence and handoff

- **Needs:** every earlier summary that exists for this run.
- **Tools:** Write for `straddle-test-evidence.md` only.
- **Next:** none. The developer reviews the evidence.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-test","step":"06-evidence"}
```

Write `straddle-test-evidence.md` at the repository root, replacing any earlier copy, in this shape:

```markdown
# Straddle test evidence

- Status: passed | failed | partial | blocked
- Run: <run ID>, <date>
- Integration type: <direct | saas | marketplace>
- Environment: sandbox, <base URL> | configuration error: <what is missing>
- Target: Straddle Sandbox | offline synthetic localhost <base URL>: offline synthetic proof, not live Straddle Sandbox proof
- SDK: <package> <version>. CLI: <version or not used>
- Notification path: <webhook | FIFO | polling endpoint>

## Offline checks
| Check | Result | Source |

## Sandbox scenarios
| Scenario | Result (passed, failed, not run, not observed) | Evidence |

## Discovery and authenticated execution
| Check | Result |
| API MCP discovery (summarize-openapi-specs) | passed / failed / not run |
| Authenticated read (<operation>) | <status> / not run: <reason> |

## Excluded operation routing
| Operation | Executing tool |

## Server-side resources
| Resource | ID | External ID | Acting account | Created, reused, or observed |

## Findings for Integrate
```

Sanitize before writing:

- Resource IDs, external IDs, statuses, return codes, event IDs, and HTTP status codes are fine.
- Never write keys, signing secrets, bearer tokens, polling tokens, unmasked or revealed values, bank numbers, or customer personal data. Summarize them as `present` or `redacted`.

Write "None" for empty sections. Do not describe a scenario that did not run as passed. For an offline synthetic target, the server-side resources section lists synthetic upstream records only, and notification and lifecycle scenarios such as `paid`, the `R01` return, or delivered events are `not run: offline synthetic target`.

Tell the developer the status and the path, then print:

```markdown
## Verify before merging

- [ ] Every passed row in the evidence ran in this run.
- [ ] Discovery and authenticated execution are reported separately.
- [ ] Status transitions came from the notification path, not resource polling.
- [ ] The evidence file contains no secret or unmasked data.
```

Then print on one line:

```text
STRADDLE_HANDOFF {"skill":"straddle-test","status":"<passed|failed|partial|blocked>","report":"<one-paragraph summary including straddle-test-evidence.md and the scenarios not run>"}
```
