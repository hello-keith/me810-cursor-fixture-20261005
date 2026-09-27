# Step 2: Sources

- **Needs:** step 1 summary.
- **Tools:** Read, Glob, Grep; Bash only for `straddle <command> --help` and `straddle which "<capability>" --agent`; `straddle-docs` `search-documentation`; `straddle-api` `search-openapi-operations` and `summarize-openapi-specs`. No `execute-request`, and no writes.
- **Next:** [03-code.md](03-code.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-integrate","step":"02-sources"}
```

1. **Installed SDK.** Open the selected SDK in the dependency tree, for example `node_modules/@straddlecom/straddle/`. Record the exact version from its manifest. Read its `api.md`, README, and bundled `SKILL.md` for every method the plan uses: client options, the `Straddle-Account-Id` and `Idempotency-Key` params, error classes, and the webhook helper. If the plan's SDK is not installed, install only the exact released version the plan names, and only when the plan's file table includes the manifest change. Python has no published Scalar SDK yet, so stop if the plan names it.
2. **Approved files.** Read each file in the plan's file-change table, plus the tests next to it. Note code that must stay untouched, such as existing payment providers, shared utilities, and unrelated routes.
3. **Docs.** Use `search-documentation` on the Docs MCP for the product flow, Sandbox outcomes, the selected notification path, and hosted onboarding when the plan includes it. If the Docs MCP lists `execute-request` or other API tools, do not call them, and note that it is exposing execution.
4. **CLI help**, for each command the preview will name. Check whether `--idempotency-key` exists on the installed CLI version.

Stop and report when the installed SDK lacks a method or option the plan relies on. Do not substitute raw HTTP or a guessed method.

**Summary for step 3:** SDK package and version, the verified method for each planned operation with its source file, the webhook helper, files to change and files to keep untouched, CLI version and idempotency flag support.
