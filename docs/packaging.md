# Straddle Agent Plugin packaging

This repository is one Straddle Agent Plugin. The root `plugin.json`, `mcp.json` and `skills/` form the portable [Agent Plugins 1.0.0](https://github.com/agentplugins/agent-plugins-spec) package. Claude Code, Codex and Cursor each read their own manifest beside it, and every manifest points at the same `mcp.json`.

Native installation in each client has not been accepted yet. The commands below are the intended install paths, and they stay unverified until the ME-666 clean-profile checks pass in Claude Code, Codex and Cursor.

## Files

| File | Read by | Contents |
| -- | -- | -- |
| `plugin.json` | Agent Plugins clients, including Codex when its `$schema` is present | Name, version, description, author, homepage, repository, license. |
| `mcp.json` | Every client, through its manifest's `mcpServers` | The `straddle-api` and `straddle-docs` servers. |
| `.claude-plugin/plugin.json` | Claude Code | Metadata and `"mcpServers": "./mcp.json"`. Skills load from `skills/`. |
| `.claude-plugin/marketplace.json` | Claude Code and Codex marketplaces | One plugin entry, `straddle`, with source `./`. |
| `.codex-plugin/plugin.json` | Codex, as an overlay on the root manifest | The `interface` block and PNG assets. |
| `.cursor-plugin/plugin.json` | Cursor | Metadata, `logo`, and the `STRADDLE_API_KEY` variable prompt. |
| `assets/` | Codex and Cursor | `logo.svg` is the published Straddle docs mark (`straddle-openapi/assets/favicon.svg` at `d571b47`). `logo.png` (512 px) and `icon.png` (256 px) are rendered from it with `@resvg/resvg-js` 2.6.2. |
| `evals/` | `claude plugin eval` | Eval cases per skill, plus MCP mocks. |
| `scripts/validate-package` | CI and authors | Package validation and the skill policy lint. |

The version is `0.1.0` in `plugin.json`, all three native manifests, and both version fields in `.claude-plugin/marketplace.json`. Clients stay on a release until the version changes, so bump every copy together. The validator fails when they differ.

## MCP servers and credentials

`mcp.json` uses the Agent Plugins MCP form: a top-level `$schema` and `"type": "streamable-http"` for both servers. Codex rejects `"type": "http"` in an Agent Plugins package, while Claude Code reads `streamable-http` as `http`. The file carries no headers, credentials or account IDs, because the spec defines header values as literal package data and leaves credentials to each client.

| Server | URL | Credential |
| -- | -- | -- |
| `straddle-api` | `https://mcp.scalar.com/mcp/d5d1b1c2-ae5b-432d-b795-4fcb31cfdedd` | The caller's Straddle API key as a bearer token, supplied through the client. |
| `straddle-docs` | `https://straddle-build-straddle-openapi.apidocumentation.com/mcp` | None. It is intended to be search-only once ME-809 removes its binding to the API installation. |

Registering the plugin's servers and authenticating `straddle-api` are separate steps. Each client's documented credential route is below. None of them is verified yet with the plugin installed.

* **Claude Code.** The [published setup guide](https://straddle-build-straddle-openapi.apidocumentation.com/connect-mcp) adds a client-level server whose header reads the key from the environment: `claude mcp add --transport http --scope local straddle-api <API URL> --header 'Authorization: Bearer ${STRADDLE_API_KEY}'`. Claude Code keeps plugin servers separate from client-level servers, so this adds a second `straddle-api` registration rather than authenticating the plugin's own server.
* **Codex.** In a scratch `CODEX_HOME`, a client-level server with the same name replaced the plugin's server: `codex mcp add straddle-api --url <API URL> --bearer-token-env-var STRADDLE_API_KEY`. Codex removes an `Authorization` header from Agent Plugins MCP config, so the plugin alone registers `straddle-api` without a credential.
* **Cursor.** `.cursor-plugin/plugin.json` declares `STRADDLE_API_KEY` under `variables` so the dashboard prompts for it. `mcp.json` has no `${STRADDLE_API_KEY}` placeholder, so it is unproven whether Cursor injects the value into the plugin's server.

## Install paths

| Client | Command |
| -- | -- |
| Claude Code | `claude plugin marketplace add straddle-build/skills`, then `claude plugin install straddle@straddle` |
| Codex | `codex plugin marketplace add straddle-build/skills`, then `codex plugin add straddle@straddle` |
| Cursor | Import this repository as a team marketplace. |

`npx skills add straddle-build/skills` installs the skills only. It doesn't install the manifests or MCP servers, so it isn't evidence that the plugin works. `scripts/validate-package` checks the skill files that both distribution paths ship, including `references/` at the root and under each skill.

## Validation

Run these from the repository root:

```sh
scripts/validate-package             # package checks, policy lint, and live link checks
scripts/validate-package --offline   # same, without fetching remote links
scripts/validate-package --offline path/to/file.md   # policy lint for specific files only
python3 -m unittest discover -s tests -v
```

The package checks validate `plugin.json` and `mcp.json` against the vendored Agent Plugins 1.0.0 schemas in `scripts/schemas/`. They also check the fixed MCP servers, name and version agreement across the manifests, the Codex `interface` fields, that PNG assets are square, the Cursor variables schema, all nine required skills, and eval case layout. They report missing skills and missing Codex legal URLs as failures, because both are real release requirements.

CI runs Markdown lint, the validator tests, `scripts/validate-package`, and `claude plugin validate --strict` from Claude Code 2.1.283. It also runs the `fixtures/account-scope` corpus job whenever that directory exists.

### Skill policy lint (ME-816)

The lint reads every Markdown file under `skills/` and `references/`. It splits each file into fenced code blocks and prose paragraphs, headings included, then splits paragraphs into clauses at `.`, `!`, `?` and `;`. A prose finding needs a match that no negation (`never`, `not`, `do not`, `avoid`, `instead of`, `rather than` and similar) precedes in its clause. Code blocks ignore negation, because code is an instruction.

Negative examples are recognized only when an explicit prohibition frames them, and only for the rule the frame names. A frame is a heading or a lead-in ending in `:` that starts with `Never`, `Do not`, `Don't`, `Avoid`, `Forbidden`, `Prohibited`, `Anti-pattern`, or `What is not`/`What are not`. A heading frames its section for a rule when it names that rule's topic. For example, "What is not a notification model" frames resource polling, but not credential or `execute-request` checks. A lead-in frames only the list items and code right after it, when it names the rule's topic or says "the following", "these" or "any of". The heading text itself is always checked.

| Rule | Rejects | Accepts |
| -- | -- | -- |
| `resource-polling` | A code block that reads an ordinary resource (`/v1/<resource>` path, SDK `get`/`retrieve`/`list` call, or `straddle <resource> get`/`list`) and also waits (`sleep`, `setTimeout`, `setInterval`, `watch -n`, `poll`). A prose paragraph that pairs a resource read with a polling phrase, unless the polling phrase's clause names the polling endpoint. Any instruction to run `straddle tail`, which polls the API at an interval. | Consuming a polling endpoint with a consumer ID and offset. A single read after an event arrives. `straddle tail --help`. |
| `excluded-operation` | `execute-request` used for any of the fourteen operations (from `straddle-api-contracts` at `bb4dfd4`), for any `DELETE`, or for creating a charge, payout, customer or paykey. In code, a creation path counts only when the same block uses `POST`. | Prose that routes those operations through the SDK or CLI. `execute-request` reads of the same collections, such as `GET /v1/charges`. |
| `credentials` | Instructions to read or print `.env*` files, `dotenv` loaders, commands that dump the environment, and code or prose that prints an API key, secret or token. | Reading keys from the process environment, and error messages that name a missing variable. |
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

Cases live in `evals/<skill>-<case>/` with `prompt.md` and `graders/*.md`. Mocks go in `evals/mocks/<server>/<tool>.md` or a case's own `mocks/`, where `<server>` is `straddle-api` or `straddle-docs`. The validator requires at least one case per present skill and rejects mocks for unknown servers. `evals/results/` is ignored by Git. `evals/.markdownlint.jsonc` turns off only MD041 (first-line heading) for these files, because prompts, graders and mocks are literal model input and output.

The gate run needs model credentials, so it isn't in CI yet. This recipe is incomplete: it doesn't select an exact model or judge, so it isn't an approved run until the run owner supplies verified `--model` and `--judge-model` values. The rest of the command keeps real MCP servers off, and reports stay local:

```sh
claude plugin eval . --no-publish --mocks record --runs 3 --ablation with-without --threshold 1.0 \
  --model <approved model> --judge-model <approved judge>
```

Pass no `--trust-plugin`, `--allow-real-servers` or `--allow-tools` grant unless the run owner approves it.
