# Step 2: Inspect the repository

- **Needs:** step 1 summary.
- **Tools:** Read, Glob, Grep. No writes. Never open `.env*`, private keys, credential files, or paths the repository marks as sensitive, even if a search lists them.
- **Next:** [03-cli-and-context.md](03-cli-and-context.md).

Print:

```text
STRADDLE_PROGRESS {"skill":"straddle-setup","step":"02-repository"}
```

Read the repository's agent instructions, build files, dependency manifests, lockfiles, application entry points, and tests. Record only what the files show:

- language, framework, package manager, and test command
- an installed Straddle SDK and the exact version resolved in the lockfile or dependency tree, not just the declared range
- a retired SDK release older than the best-practices version table (for example PyPI `straddle` 0.5.x, or Go `github.com/straddleio/straddle-go`), which is a finding
- existing payment or bank-linking provider code that must keep working
- existing webhook or event handling code

Match the language to a released SDK from the best-practices version table. If several languages are present, record the choice as unknown instead of guessing.

**Summary for step 3:** language, framework, test command, installed SDK and version (or none), retired SDK findings, provider code paths, and the SDK choice or `unknown`.
