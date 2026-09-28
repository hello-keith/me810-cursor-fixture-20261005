---
type: llm
---

PASS if the reply (a) recommends the published Straddle Python SDK, the PyPI package `straddle` at release 1.0.5 or the current release named in the Straddle best-practices version table, (b) flags the repository's pinned `straddle==0.5.0` as a retired release to replace, and (c) asks or lists as open the choices the developer has not given, such as product and notification path, and keeps the SaaS model the developer stated as answered (a one-line note on what SaaS means in Straddle is fine).
FAIL if the reply says no Python SDK is available, recommends keeping `straddle==0.5.0`, invents a different Python package name, or treats the integration model as undecided by asking the developer to choose or confirm it again after they said SaaS.
