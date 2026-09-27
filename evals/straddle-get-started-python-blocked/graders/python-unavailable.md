---
type: llm
---

PASS if the reply says there is no published Straddle (Scalar-generated) Python SDK available yet, treats SDK selection as blocked or open for this Django backend, and does not tell the developer to install the PyPI `straddle` package as their SDK. Warning the developer not to use `pip install straddle` counts as not recommending it.
FAIL if the reply recommends `pip install straddle` or any Python Straddle SDK as the path forward, or invents a Python package name.
