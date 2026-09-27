# Step 5: Report

- **Needs:** summaries from steps 2 to 4.
- **Tools:** none. Do not write a file unless the developer asks for one.
- **Next:** hand off to [straddle-plan](../../straddle-plan/SKILL.md) when the status is not `blocked`.

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-setup","step":"05-report"}
```

## Classify

Classify every row. A check that did not run is never `passed`.

The status is `blocked` when any of these holds:

- no API key (a configuration failure, even though every other check ran)
- no environment selected, the API host unreachable, or an invalid saved context
- an environment other than Sandbox
- the Straddle CLI is missing
- the Docs MCP is not registered or its search failed
- the API MCP is not registered or its discovery failed
- an authenticated check ran and failed
- the plugin version disagrees with the running client's native manifest version
- the agent client is not Claude Code, Codex, or Cursor
- the integration type or SDK is unknown and the developer has not answered
- the only matching language is Python, which has no published Scalar SDK yet

The status is `ready_with_warnings` when nothing blocks but something is incomplete: an authenticated check `not run`, the CLI too old to report `runtime_context`, no acting account on a platform, fewer than two Sandbox accounts for a platform, the chosen SDK not installed yet, a retired SDK installed, a plugin or skill version that could not be read, or a Docs MCP that exposes execution tools. Otherwise it is `ready`.

## Report

Write the report in this shape:

```markdown
# Straddle Setup report

Status: ready | ready_with_warnings | blocked

| Check | Result | Evidence |
| --- | --- | --- |
| Agent client | Claude Code / Codex / Cursor / unsupported | session |
| Agent Plugin | <version> / unknown | plugin root `plugin.json` |
| Native client manifest | <version> / none for this client | `.claude-plugin/`, `.codex-plugin/`, or `.cursor-plugin/` `plugin.json` |
| Skills | straddle-setup <version>, straddle-plan <version>, straddle-best-practices <version> | skill `metadata.version` |
| Straddle Wizard | not installed / <version> | |
| Straddle CLI | <version> / missing | `straddle --version` |
| API key | present / missing (configuration failure) | `doctor` env_vars |
| Authenticated request (CLI) | passed / failed (<status>) / not run (<reason>) | `straddle accounts list` |
| Environment | <base URL> | runtime_context |
| Integration type | account / saas / marketplace / unknown | runtime_context or developer |
| Acting account | <id> / none / not required | runtime_context |
| Sandbox accounts for A/B | <count> / unknown | |
| Docs MCP | search passed / warning: exposes execution tools / not registered / search failed | |
| API MCP discovery | passed / not registered / failed | summarize-openapi-specs |
| API MCP authenticated | passed / failed (<status>) / not run (<reason>) | execute-request GET /v1/accounts |
| SDK | <package> <version> / not installed, add <version> / choose one / Python unavailable | lockfile |

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
