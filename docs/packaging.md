# Straddle Agent Plugin packaging

This repository is one Straddle plugin for Claude Code, Codex and Cursor. Each client reads its own manifest. Claude Code and Cursor load the MCP servers from `mcp.json`, which uses the [Agent Plugins 1.0.0](https://github.com/agentplugins/agent-plugins-spec) MCP form. Codex drops the credential from that form, so Codex's manifest declares the servers in Codex's own form instead, and the root `plugin.json` leaves out the Agent Plugins `$schema` that would make Codex ignore that manifest (see [MCP servers and credentials](#mcp-servers-and-credentials)).

Native installation in each client has not been accepted yet. The commands below are the intended install paths, and they stay unverified until the ME-666 clean-profile checks pass in Claude Code, Codex and Cursor.

## Files

| File | Read by | Contents |
| -- | -- | -- |
| `plugin.json` | The validator, `scripts/kit-release`, the release workflow and the Wizard | Name, version, description, author, homepage, repository, license: the Agent Plugins 1.0.0 metadata fields, without `$schema`. |
| `mcp.json` | Claude Code and Cursor, through their manifests' `mcpServers` | The `straddle-api` and `straddle-docs` servers, and the `straddle-api` `Authorization` header. |
| `.claude-plugin/plugin.json` | Claude Code | Metadata and `mcpServers: "./mcp.json"`. Skills load from `skills/`. |
| `.claude-plugin/marketplace.json` | Claude Code and Codex marketplaces | One plugin entry, `straddle`, with source `./`. |
| `.codex-plugin/plugin.json` | Codex | The whole Codex manifest: metadata, `skills`, both MCP servers in Codex's form with `bearer_token_env_var` on `straddle-api`, and the `interface` block with PNG assets. The privacy and terms URLs are Straddle's published [Privacy Policy](https://legal.straddle.com/legal/legal/privacy-policy) and [Straddle Services Agreement](https://legal.straddle.com/legal/legal/straddle-services-agreement), both listed in `legal.straddle.com/sitemap.xml`. |
| `.cursor-plugin/plugin.json` | Cursor | Metadata, `logo`, and the `STRADDLE_API_KEY` variable prompt. |
| `assets/` | Codex and Cursor | `logo.svg` is the published Straddle docs mark (`straddle-openapi/assets/favicon.svg` at `d571b47`). `logo.png` (512 px) and `icon.png` (256 px) are rendered from it with `@resvg/resvg-js` 2.6.2. |
| `evals/` | `claude plugin eval` | Eval cases per skill, plus MCP mocks. |
| `scripts/validate-package` | CI and authors | Package validation and the skill policy lint. |
| `scripts/kit-release` | CI and the release cut | Builds the checksummed plugin archive, and generates and checks `kit/manifest.yaml`. See [Release manifest and plugin archive](#release-manifest-and-plugin-archive). |
| `kit/release-inputs.json` | `scripts/kit-release` | Hand-maintained release facts: released CLI, SDK, contract and hosted MCP records, the Wizard artifact and the plugin versions it accepts, client observations and the open publication gates. |
| `kit/manifest.yaml` | Release acceptance (ME-659), and published with each plugin release. The Wizard doesn't read it. | Generated at the release cut. Every version and digest, minimum CLI and SDK versions, and install, update, remove and validation instructions per client. Between releases it describes the last cut, not the current source. |
| `.github/workflows/release.yml` | GitHub Actions, on a `v*` tag push | The plugin release cut. See [Plugin releases](#plugin-releases). |
| `third_party/LICENSES.md` | Maintainers | Every vendored third-party file and its license. A skill that vendors a file also carries the notice in its own `references/third-party-licenses.md`, so skills-only installs keep it. |

The version is `0.1.0` in `plugin.json`, all three native manifests, and both version fields in `.claude-plugin/marketplace.json`. Clients stay on a release until the version changes, so bump every copy together. The validator fails when they differ.

## MCP servers and credentials

`mcp.json` uses the Agent Plugins MCP form: a top-level `$schema` and `"type": "streamable-http"` for both servers, which Claude Code reads as `http`. `straddle-api` declares `Authorization: Bearer ${STRADDLE_API_KEY}`. That is a placeholder, never a key: each client fills it from the caller's environment. The file carries no credential or account ID.

| Server | URL | Credential |
| -- | -- | -- |
| `straddle-api` | `https://mcp.scalar.com/mcp/d5d1b1c2-ae5b-432d-b795-4fcb31cfdedd` | The caller's Straddle API key as a bearer token, supplied through the client. |
| `straddle-docs` | `https://straddle-build-straddle-openapi.apidocumentation.com/mcp` | None. The skills use it for documentation search only; API execution stays on `straddle-api` under the skills' existing rules, whatever tools the docs server lists. |

Registering the plugin's servers and authenticating `straddle-api` are separate steps. All three clients read the key from `STRADDLE_API_KEY`, the same environment variable the SDKs and the CLI read. The API MCP can still list tools and summarize the specification without a valid key, so discovery succeeding does not prove authenticated access; only an authorized Straddle operation does.

* **Claude Code.** Set `STRADDLE_API_KEY` in the environment Claude Code starts from. Claude Code expands `${STRADDLE_API_KEY}` in `mcp.json`'s header from that environment. When the variable is unset, Claude Code does not fail: it sends the literal text `Bearer ${STRADDLE_API_KEY}`. Treat an unset key as missing configuration and set it before starting Claude Code. The separate client-level command in the [published setup guide](https://straddle-build-straddle-openapi.apidocumentation.com/connect-mcp) is not needed with the plugin installed.
* **Codex.** Codex removes an `Authorization` header from Agent Plugins MCP config, and reads a root `plugin.json` that has the Agent Plugins `$schema` in that format, taking its servers from `mcp.json` and ignoring those in `.codex-plugin/plugin.json`. So the root has no `$schema`, and `.codex-plugin/plugin.json` declares both servers in Codex's form, with `"bearer_token_env_var": "STRADDLE_API_KEY"` on `straddle-api`. Set `STRADDLE_API_KEY` in the environment Codex starts from. `codex mcp list --json` then shows `straddle-api` with that variable name and `auth_status` `bearer_token`. A bearer token from an environment variable works for local and repository marketplace installs only. A listing in the OpenAI plugin directory needs OAuth on the hosted MCP (ME-661).
* **Cursor.** `.cursor-plugin/plugin.json` declares `STRADDLE_API_KEY` under `variables`, so the dashboard prompts for it. Cursor's docs say it fills `${VAR}` placeholders in a plugin's `mcp.json` from those variables. That hasn't been tested in Cursor yet.

The validator requires the `mcp.json` header, the Codex manifest's servers, and a root `plugin.json` without `$schema`.

## Install paths

| Client | Command |
| -- | -- |
| Claude Code | `claude plugin marketplace add straddle-build/skills`, then `claude plugin install straddle@straddle` |
| Codex | `codex plugin marketplace add straddle-build/skills`, then `codex plugin add straddle@straddle` |
| Cursor | Import this repository as a team marketplace. |

`npx skills add straddle-build/skills` installs the skills only. It doesn't install the manifests or MCP servers, so it isn't evidence that the plugin works. `scripts/validate-package` checks the skill files that both distribution paths ship, including `references/` at the root and under each skill.

## Release manifest and plugin archive

ME-810's release cut is `kit/manifest.yaml`. `scripts/kit-release` generates it from `kit/release-inputs.json` and the committed plugin source, so the manifest never holds a hand-typed plugin or skill digest. It is regenerated at the release cut, not on every change, so a skills-only change needs no manifest refresh.

```sh
scripts/kit-release build                 # dist/straddle-plugin-<version>.zip and dist/SHA256SUMS from HEAD
scripts/kit-release generate              # rewrite kit/manifest.yaml from HEAD and the inputs
scripts/kit-release check                 # regenerate and compare; the release cut runs this
scripts/kit-release check --wizard-tarball path/to/straddlecom-wizard-<version>.tgz   # needs node and Python 3.12+
scripts/kit-release check --release       # fails unless every component has publication proof
```

The plugin archive holds what a client loads: the root and native manifests, `mcp.json`, `assets/`, `skills/`, `references/`, `third_party/`, `LICENSE` and `README.md`. It is built from git objects at the given commit, not the working tree, with stored entries, a fixed 1980-01-01 timestamp and the git file modes. The same commit gives the same bytes on any machine and zlib. `kit/` is excluded, so the commit that records the manifest rebuilds the archive the manifest names. Claude Code can load the archive directly with `claude --plugin-dir straddle-plugin-<version>.zip`, which is package-loaded evidence, not a marketplace install.

`plugin.content_sha256` and each skill's `sha256` hash a `sha256sum`-style listing, one `<sha256>  <path>` line per file sorted by repository path, over the plugin files or the skill directory. They don't depend on the archive format, so the Wizard can verify an installed or fetched plugin directory against them. Commit plugin source changes first: `generate` and `check` read plugin files from the commit and inputs from the working tree.

### Provenance

`kit.status` is `candidate` until a separately approved release. In a candidate the plugin is `local-candidate`: built here, never published. The Wizard is `local-candidate` until `@straddlecom/wizard` is on npm, and the manifest records its `npm pack` file, sha256, npm integrity and source commit. `generate` refuses to write a manifest without that Wizard artifact. Released components (CLI, SDKs, contract) carry the public registry URL and the digest of the published bytes. The hosted API MCP reports server version `latest`, so it is pinned by the contract version that `summarize-openapi-specs` reports, which must equal `contract.version`. It has no content digest.

`generate` and `check` reject an incomplete record before writing anything. The inputs must carry the CLI and all five SDKs with a version, a minimum version no newer than it, and a provenance of `released` or `local-candidate`. A released component also needs an https evidence URL and a digest. The contract version and the hosted MCP's served version must both be present and equal. Both MCP URLs must equal the servers in the committed `mcp.json`, and the plugin repository must be a GitHub `owner/name`. The four gates `walkthrough-approval`, `wizard-npm-publication`, `plugin-release-tag` and `clean-client-acceptance` are required by ID, once each. Removing one from the inputs fails generation rather than dropping the requirement.

`wizard.plugin_range` records the plugin versions the Wizard pack accepts, such as `0.1.x`. Generation fails when the plugin version is outside it, because that Wizard would refuse the plugin the same manifest records. A skill or reference change inside the range needs no Wizard change. `check --wizard-tarball` first checks the tarball's bytes and stops on a mismatch without extracting it. A `local-candidate` Wizard must match `wizard.artifact`'s sha256 and npm integrity, and a `released` Wizard must match the npm `dist.integrity` in `wizard.evidence.digest`. Safe extraction of the pack uses `tarfile`'s data filter, which requires Python 3.12 or later; plain `check` has no such requirement. It then checks the package name, version and bin, and stops on a mismatch before running any of the pack's code. Only then does it run the pack's own `unpackRelease` from `dist/bundle.js` with `node` on the plugin archive and `SHA256SUMS` this commit publishes. That is the code path the Wizard runs on a downloaded release, so it checks the checksum, the range, and that `plugin.json` matches the version.

`check --release` lists every reason the manifest isn't a published release: a `candidate` status, any component without `released` provenance and public proof, no `plugin_release` tag and checksum URL, a missing tag or one that doesn't point at the checked commit, and every gate that hasn't `passed` with evidence. It reads only local git state and makes no network request, so it proves the record is complete, not that the registries still serve those bytes.

### Plugin releases

A plugin release is a versioned, checksummed artifact built from one commit. It is released independently of the Wizard. The Wizard runs the newest release in its range (ME-891).

* **Where releases live.** A GitHub release on `straddle-build/skills`, tagged `v<plugin.json version>`, with three assets: `straddle-plugin-<version>.zip`, `SHA256SUMS` and `manifest.yaml`. The Wizard reads the release list from `https://api.github.com/repos/straddle-build/skills/releases`. It skips drafts, prereleases and any tag that isn't exactly `vX.Y.Z`. It takes the newest release in its range, downloads the zip and `SHA256SUMS`, and refuses the release when the zip's sha256 differs from its `SHA256SUMS` line. It also refuses the release when the zip holds anything but regular files under the plugin paths, or when its `plugin.json` version isn't the tag's. A release outside its range is never used. The Wizard's README has the client side.
* **Cutting a release.** Bump the version in `plugin.json` and every native manifest, record the release facts in `kit/release-inputs.json`, run `scripts/kit-release generate` and commit. Then push tag `v<version>` under the version-tag ruleset. `.github/workflows/release.yml` checks that the tag equals `plugin.json`. It fetches the recorded Wizard from npm and runs `scripts/kit-release check --release --wizard-tarball`, which includes the Wizard compatibility check above. It then builds the archive and `SHA256SUMS` and creates the GitHub release with all three assets in one `gh release create`, so the release is never published without them. Any failed check stops the workflow before a release exists.
* **Compatibility.** A change within the Wizard's range (for example `0.1.0` to `0.1.1`) reaches Wizard users with the next plugin release, with no Wizard release. A new minor version (`0.2.0`) is ignored by Wizards that accept `0.1.x` until a Wizard release widens its range and `wizard.plugin_range` records it.
* **Integrity.** The published `SHA256SUMS` is what the Wizard trusts. Enable GitHub's immutable releases on this repository so a published release's tag and assets can't change afterwards.

### Generated instructions

`instructions` has a `candidate` and a `release` channel for the Wizard, Claude Code and Codex, each with `install`, `update`, `remove` and `validate`. Each operation is one shell script in a `set -eu` subshell, so a failed step stops the whole operation, however it is run. Plugin operations need `STRADDLE_KIT_DIR`, a durable directory, and stop before any change when it is unset. Each client gets its own marketplace directory there, `claude-code-plugin` or `codex-plugin`, registered as a local marketplace.

* **Acquire and verify.** A candidate verifies the archive's sha256 before extracting it. A release clones tag `v<version>` of `https://github.com/straddle-build/skills.git` into a scratch checkout and copies only the plugin files into `<dir>.new` with `git archive`. Other repository content, such as `evals/`, `kit/` or a root `hooks/` directory, never reaches a client. Either way, `<dir>.new` must then be exactly the verified plugin: only the plugin paths at its root, only regular files and directories with no symlinks, and a listing that matches `plugin.content_sha256`. Anything else deletes it and stops the operation before the client is touched.
* **Install.** Moves the verified directory into place and registers it with the client.
* **Update.** Requires an existing install, verifies the replacement, then swaps directories, keeping the previous one as `<dir>.old`. It then runs the client refresh: `claude plugin marketplace update` and `claude plugin update`, or `codex plugin add`. If the refresh fails, it restores the previous directory, refreshes again and exits nonzero, so the previous plugin stays installed.
* **Remove.** Uninstalls the plugin, removes the marketplace and the client's directory.
* **Validate.** Read-only. It checks the installed version, the enabled state and both MCP URLs. For Codex it also checks that `straddle-api` reads the bearer token from the variable named `STRADDLE_API_KEY`, never the value. On failure, Codex validate prints only which of those checks failed, never a server's transport, headers or other MCP servers.

Neither client can move an installed Git marketplace to another ref without removing it. Claude Code refuses a second `marketplace add` with a different ref, Codex refuses a different source, and removing the marketplace uninstalls the plugin. That is why releases are installed from a verified local copy of the plugin files, the same way the Wizard installs its verified plugin release. `claude plugin marketplace add straddle-build/skills` from [Install paths](#install-paths) still installs the untagged default branch. The Wizard candidate verifies the tarball's sha256 before `npm install --global`. Cursor instructions are manual, and Cursor has no candidate channel, because it imports a team marketplace from a GitHub repository.

The generated operations were run in scratch Claude Code 2.1.284 and Codex 0.157.1 profiles with remote network denied, including tampered, unset-directory, unavailable-tag, mismatched-tag and failed-refresh cases. The release channel ran against a loopback Git mirror with scratch tags, because tag `v<version>` isn't published. That is offline evidence. It is not a clean-client release install, which needs the tag, a signed-in client, and Cursor.

## Validation

Run these from the repository root:

```sh
scripts/validate-package             # package checks, policy lint, and live link checks
scripts/validate-package --offline   # same, without fetching remote links
scripts/validate-package --offline path/to/file.md   # policy lint for specific files only
python3 -m unittest discover -s tests -v
```

The package checks validate `mcp.json`, and `plugin.json`'s metadata fields, against the vendored Agent Plugins 1.0.0 schemas in `scripts/schemas/`. They also check the fixed MCP servers and credential routes, name and version agreement across the manifests, the Codex `interface` fields, that PNG assets are square, the Cursor variables schema, all nine required skills, and eval case layout. They fetch the Codex `websiteURL`, `privacyPolicyURL` and `termsOfServiceURL` and require HTTP 200, like Markdown links. They report missing skills and missing Codex URLs as failures, because both are real release requirements.

CI runs Markdown lint, the validator and kit-release tests, `scripts/validate-package`, `scripts/kit-release build` (the plugin packs), and `claude plugin validate --strict` from Claude Code 2.1.283. It also runs the `fixtures/account-scope` corpus job on every run. It doesn't check `kit/manifest.yaml` or the recorded Wizard, so a skills-only change passes without a Wizard change. Those checks run at the release cut.

### Skill policy lint (ME-816)

The lint reads every Markdown file under `skills/` and `references/`. It splits each file into fenced code blocks and prose paragraphs, headings included, then splits paragraphs into clauses at `.`, `!`, `?` and `;`. A prose finding needs a match that no negation (`never`, `not`, `do not`, `avoid`, `instead of`, `rather than` and similar) precedes in its clause. Code blocks ignore negation, because code is an instruction.

Negative examples are recognized only when an explicit prohibition frames them, and only for the rule the frame names. A frame is a heading or a lead-in ending in `:` that starts with `Never`, `Do not`, `Don't`, `Avoid`, `Forbidden`, `Prohibited`, `Anti-pattern`, or `What is not`/`What are not`. A heading frames its section for a rule when it names that rule's topic. For example, "What is not a notification model" frames resource polling, but not credential or `execute-request` checks. A lead-in frames only the list items, table rows and code right after it, when it names the rule's topic or says "the following", "these" or "any of". Each table row is linted as its own unit, so text in one row never combines with another row. The heading text itself is always checked.

| Rule | Rejects | Accepts |
| -- | -- | -- |
| `resource-polling` | A code block that reads an ordinary resource (`/v1/<resource>` path, SDK `get`/`retrieve`/`list` call, or `straddle <resource> get`/`list`) and also waits (`sleep`, `setTimeout`, `setInterval`, `watch -n`, `poll`). A prose paragraph that pairs a resource read with a polling phrase. A polling phrase is ignored only when its clause names the polling endpoint and reads no ordinary resource, so "a poller that polls `GET /v1/charges/{id}`" is still reported. Any instruction to run `straddle tail`, which polls the API at an interval. | Consuming a polling endpoint with a consumer ID and offset. A single read after an event arrives. `straddle tail --help`. |
| `excluded-operation` | `execute-request` used for any of the fourteen operations (from `straddle-api-contracts` at `bb4dfd4`), for any `DELETE`, or for creating a charge, payout, customer or paykey. In code, a creation path counts only when the same block uses `POST`. | Prose that routes those operations through the SDK or CLI. `execute-request` reads of the same collections, such as `GET /v1/charges`. |
| `credentials` | Instructions to read or print `.env*` files, `dotenv` loaders, commands that dump the environment (bare `printenv`, `env`, `set`, `env \| grep`), `printenv` of a variable whose name contains `KEY`, `SECRET`, `TOKEN` or `PASSWORD`, and code or prose that prints an API key, secret or token. | Reading keys from the process environment, `printenv` of a named non-secret variable such as `STRADDLE_ENVIRONMENT`, and error messages that name a missing variable. |
| `links` | Relative links that don't resolve, non-HTTPS links, Straddle and GitHub links that don't return HTTP 200 after redirects, and other hosts missing from `scripts/link-allowlist.txt`. | Links inside code, which are examples. |
| `frontmatter` | A `SKILL.md` without `name`, `description` and a semantic `metadata.version`, or whose `name` doesn't match its directory. | The frontmatter subset skills use: scalars, quoted and block scalars, lists, and one nested map. |

Every finding prints `file:line: rule: message`. Positive and negative fixtures live in `tests/fixtures/policy/`, and each rule has a test that fails when the rule is disabled.

The lint matches patterns and doesn't understand prose. Writers should know these limits:

* A negation earlier in the same clause can hide a real instruction, for example "Don't worry, just use execute-request to create a charge".
* An instruction inside a prohibition-framed section is not checked for the rule that frame names.
* In code, method and path are paired per fenced block, not per request, so a block that mixes a `POST` elsewhere with a `GET /v1/charges` is reported.
* Polling phrased without a recognized resource read or polling phrase, such as a helper function that hides the request, is not detected.
* Link checks need network access. `--offline` skips only the HTTP status check.

## Evals

Cases live in `evals/<skill>-<case>/` with `prompt.md` and `graders/*.md`. Mocks go in `evals/mocks/<server>/<tool>.md` or a case's own `mocks/`, where `<server>` is `straddle-api` or `straddle-docs`. The validator requires at least one case per present skill and rejects mocks for unknown servers. `evals/results/` is ignored by Git. `evals/.markdownlint.jsonc` turns off only MD041 (first-line heading) for these files, because prompts, graders and mocks are literal model input and output. The `search-openapi-operations` mocks return the hosted tool's JSON shape with synthetic Scalar IDs, and `straddle-integrate-ambiguous-retry` accepts only an `execute-request` that passes those IDs with the hosted tool's arguments (ME-882).

Integrate and Test accept an integration plan's approval from an earlier session only when its `Approval` line's sha256 matches the plan ([Recorded approval](../skills/straddle-integrate/steps/01-begin.md#recorded-approval), ME-894). So every scaffold whose plan is `Approved` records that hash. After editing such a plan, recompute it with the command there, or the case silently becomes an unapproved-plan case. `straddle-test-plan-edited-after-approval` is that case on purpose.

Model evals run on the existing exe.dev VM with the Claude Code login already approved there, not in GitHub CI, which stays deterministic. The approved model and judge are both `claude-opus-5-5`. The command keeps real MCP servers off, and reports stay local:

```sh
claude plugin eval . --no-publish --mocks record --runs 3 --ablation with-without --threshold 1.0 \
  --model claude-opus-5-5 --judge-model claude-opus-5-5
```

Pass no `--trust-plugin`, `--allow-real-servers` or `--allow-tools` grant unless the run owner approves it.

### Progress markers

The `STRADDLE_PROGRESS` lines a skill prints when it enters a step are best-effort in native clients, and no repository check or release gate depends on them. They show roughly where a run went, but they aren't evidence that a step finished, that the developer approved anything, or that a run passed. Deterministic progress is the Wizard's job (ME-667), which reports it from client events. Where a client doesn't expose those events, report progress there as unsupported or unverified rather than inferring it from markers. Content, safety, approval, abort handling, a truthful final handoff, native-client verification, and the walkthrough and publication approval all remain release requirements.

### Inventory shell reads (ME-669)

During `straddle-migrate` step 2, Bash is limited to the bounded read-only local inspection listed in the Tools line of [`skills/straddle-migrate/steps/02-inventory.md`](../skills/straddle-migrate/steps/02-inventory.md). Credentials, network calls, installs and writes stay prohibited there; other steps keep their own tool lines.

### Plan handoffs into Integrate and Test

Integrate's source step reads the installed SDK for every SDK in the Current versions table, Python included: the released PyPI `straddle` package is read from the environment's `site-packages` the way `node_modules/@straddlecom/straddle/` is read for TypeScript, and method names come from the installed package source. An older instruction that stopped Integrate when a plan named Python was removed; the version table in [`skills/straddle-best-practices/SKILL.md`](../skills/straddle-best-practices/SKILL.md) is the single source for which release each SDK must be.

Test accepts either approved plan: `straddle-integration-plan.md` from Plan and Integrate, or `straddle-migration-plan.md` from Migrate, whose Verification section names the test command, the new tests, the status-mapping coverage, and the `sandbox_outcome` values. The rules in [`skills/straddle-test/steps/01-begin.md`](../skills/straddle-test/steps/01-begin.md) say how each plan is approved (the integration plan under Integrate's existing step 1 rules, the migration plan under Migrate's, either also by the developer in the conversation), that the developer's or the handoff's named plan wins when both exist and Test asks rather than choosing when neither is named, what a migration plan does not supply (Sandbox write rows and acting accounts, which Test asks the developer for), and that an unapproved or voided plan blocks Test. Neither plan's approval authorizes a Straddle request; each Sandbox write still needs its own preview and approval in the run. The `straddle-integrate-python-approved-plan`, `straddle-test-migration-plan`, and `straddle-test-migration-plan-unapproved` cases cover these handoffs.

### Early blocked Integrate replies (ME-670)

An Integrate reply that stops before a configured preview may be a short blocked summary: it names the blocker, reports zero Straddle API requests, keeps the excluded operations on the SDK or CLI, and shows no sensitive value. The operation-by-operation route, account and approval table is still required before any execution, and the excluded-operation rules, approvals, output safety, header rules and configuration gates are unchanged, so a blocked reply offers no API request, including a permitted read. The three `straddle-integrate-*-excluded-ops` routing graders accept either form. The SaaS case's unconditional account-A regex was removed, because its configured-preview branch keeps that requirement.

No eval ran against this change, so existing scores stay attached to the source and rubric they ran with. Reviewing the retained db8b1c9 marketplace run `claude-eval-5rWp5H` by hand against the new criterion still fails it, because its blocked summary offers an API MCP read before configuration is confirmed.

The same requirements apply whichever skill stops on missing configuration, because they live in the shared rule, "When a rule blocks the task" in [`skills/straddle-best-practices/SKILL.md`](../skills/straddle-best-practices/SKILL.md). The rule has the reply check the whole request, keep any requested excluded operation on the SDK or CLI, and ask only for Sandbox for writes. An early block before any Straddle request truthfully reports zero requests, while a later per-route configuration block after already-approved requests reports the actual earlier operations and results, stops new requests on the unconfigured route, and never implies rollback or a false zero. Setup also ends its turn at its handoff and lists requested operations as Integrate work. This follows the native Codex run on `95187ab`, which chose Setup for the marketplace excluded-operations prompt, stopped safely, then asked for "Sandbox or Production" without SDK or CLI routing. No eval ran against this change either.
