# Step 5: Report

- **Needs:** summaries from steps 2 to 4.
- **Tools:** none. Do not write a file unless the developer asks for one.
- **Next:** hand off to [straddle-plan](../../straddle-plan/SKILL.md) when the status is not `blocked`.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-setup","step":"05-report"}
```

## Classify

The status is `blocked` when any of these holds:

- no API key (a configuration failure, even though every other check ran)
- no environment selected, the API host unreachable, or an invalid saved context
- an environment other than Sandbox for integration work
- the integration type or SDK is unknown and the developer has not answered
- the only matching language is Python, which has no published Scalar SDK yet

The status is `ready_with_warnings` when nothing blocks but something is incomplete, for example authenticated verification `not run`, no acting account on a platform, fewer than two Sandbox accounts for a platform, a retired SDK installed, or a Docs MCP that exposes execution tools. Otherwise it is `ready`.

## Report

Write the report in this shape:

```markdown
# Straddle Setup report

Status: ready | ready_with_warnings | blocked

| Check | Result | Evidence |
| --- | --- | --- |
| Kit skills | straddle-setup 0.1.0 | skill metadata |
| Straddle Wizard | not installed / <version> | |
| Straddle CLI | <version> or missing | `straddle --version` |
| API key | present / missing (configuration failure) | `doctor` env_vars |
| Authenticated request (CLI) | passed / failed / not run | `straddle accounts list` |
| Environment | <base URL> | runtime_context |
| Integration type | account / saas / marketplace / unknown | runtime_context or developer |
| Acting account | <id> / none / not required | runtime_context |
| Sandbox accounts for A/B | <count> / unknown | |
| Docs MCP | registered, search passed / warning / missing | |
| API MCP discovery | passed / missing | summarize-openapi-specs |
| API MCP authenticated | passed / failed / not run | execute-request GET /v1/accounts |
| SDK | <package> <version> / choose one / Python unavailable | lockfile |

## Blocking
## Warnings
## Unknown, needs the developer
## Next actions
```

Next actions are exact, non-destructive steps the developer can choose, such as `export STRADDLE_API_KEY` in their own shell or following the connect-mcp guide. For a platform, the next Integrate action is creating or reusing the two Sandbox accounts after its preview and approval. Setup does not do it.

End with:

```markdown
## Verify before merging

- [ ] No API key, token, or `.env` content appears in this report or the conversation.
- [ ] Authenticated checks marked passed were actually executed in this run.
- [ ] The environment is Sandbox.
- [ ] Nothing was installed, configured, or created by Setup.
```

Then print the handoff on one line:

```text
STRADDLE_HANDOFF {"skill":"straddle-setup","status":"<status>","report":"<one-paragraph summary of the table and blockers>"}
```
