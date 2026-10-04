# Eval evidence integrity

`scripts/eval-evidence-check` reads the `aggregate-result.json` files and `trace.jsonl` files that a `claude plugin eval` pass kept, and reports, for every run, whether the evidence its verdict rests on is complete. It runs offline and makes no model or judge call. It never changes a verdict.

Exit 0 means only that these integrity checks found no gap. It is not a candidate PASS. It doesn't accept any grader verdict, and it doesn't prove that a run stayed inside its sandbox. An original FAIL with complete evidence is still a FAIL.

## What it checks

| Reason | Meaning |
| --- | --- |
| `drift:<key>` | The run's `init` event (or the aggregate's judge model, or an assistant message's model) differs from the pinned identity: `claude_code_version`, `model`, `judge_model`, `apiKeySource`, `plugins` (sources) or `skills`. |
| `identity-unavailable:<key>` | The trace doesn't record that identity field, so the run can't be shown to match. |
| `trace-missing`, `trace-unreadable: line N`, `trace-no-init` | The trace is absent, has a line that isn't a JSON object, or has no `init` event. |
| `denials-unavailable` | The trace has no `result` event, so its permission denials are unknown. |
| `evidence-missing:<grader>` | A `focus: trace` LLM grader kept no judge input. |
| `evidence-mismatch:<grader>` | The kept judge input isn't what the runner would have built from this trace. |
| `trace-elided:<grader>` | The judge saw only 24 of the trace's events. |
| `trace-truncated:<grader>` | The judge text was cut at 100,000 chars. |

A `focus: trace` judge sees every `\n`-separated trace event up to 24, otherwise the first and last 12 around a `[…N messages elided…]` marker. Judge text over 100,000 chars is then cut to its first 80,000 and last 20,000. The checker rebuilds that view from the trace and compares it with the kept `evidence`; it matched all 15 kept trace-judge inputs of `combined-c2bae0e` and `combined-c2bae0e-r4` byte for byte. A PASS from a judge that didn't see the whole trace is reported as `trace-elided`, so it can't stand in for a full-trajectory check.

Each line also carries the run's `permission_denials`, verbatim from the trace's `result` event. Denials are diagnostics shown beside the verdict, not gaps.

## Pinning an identity

Print a run's identity, vet it by hand, and save it:

```sh
scripts/eval-evidence-check identity <results>/<case>/aggregate-result.json --run 1 > expect.json
```

Plugins a case declares itself, such as `plugins: ["../..", "env-fixture"]` in its `prompt.md`, appear in the run's `init` event. They count as drift unless `expect.json` lists them for that case. The output names each one it excluded in `case_plugins_excluded`:

```json
"case_plugins": {"straddle-integrate-python-approved-plan": ["straddle-eval-env-fixture@inline"]}
```

The trace doesn't record the account, so the identity shows an account change only through its effects on plugins and skills, such as `cc-plugin-sec-default@builtin` or the `schedule` skill.

## Checking a pass

```sh
scripts/eval-evidence-check --trace-root <copy of the eval host's /> check --expect expect.json \
  --export <new dir> <results dir or aggregate-result.json>...
```

Each run prints one JSON line: `case`, `run`, `verdict` (the original PASS, FAIL or ERROR), `evidence_integrity` (`complete` or `incomplete`), `reasons`, `denials`, `case_plugins_excluded`, `trace` and `aggregate`. Exit 1 means at least one run has a gap. Exit 2 means it couldn't check: an empty or partial results directory, an unreadable aggregate, an expected identity with an empty field, or an export that would overwrite earlier files.

`--trace-root` resolves each run's absolute `tracePath` under a local copy, for traces copied off the eval host. `--export` writes, for every run with a `focus: trace` grader, `<case>/run-N/trace.jsonl` (a byte copy) and `<case>/run-N/<grader>.json` (criteria, original verdict and votes, the exact judge input, and the trace's event count and sha256). It refuses an existing directory, a case or run seen twice, and a case or grader name that isn't a safe file name.

Traces live in each run's temporary directory, so a pass has to keep them (`--keep-temp`) or copy them before cleanup. Without them every run reports `trace-missing`.

## Limits

- It reads evidence after a pass. It doesn't pin the runtime of future runs or change how lanes launch. Pinning the version, account and loaded environment before a launch is still open.
- It doesn't judge anything. Reading an exported trace against a grader's criteria is human review.
- It makes no claim about confinement. Bash commands can reach paths that no regex over their text reliably finds, and the native file-tool boundary for `evals/` has never been exercised.
- Judge rationale isn't kept by the runner, so nothing here can recover it.
