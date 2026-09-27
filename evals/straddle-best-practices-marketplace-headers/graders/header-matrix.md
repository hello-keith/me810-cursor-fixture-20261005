---
type: llm
---

PASS if all four are right: (1) customer creation omits the header, (2) the Bridge paykey creation omits the header, (3) the charge must send seller account B's ID and fails locally if it is missing, (4) listing organizations omits the header.
FAIL if any item is wrong, including saying the header is optional for the charge or required for the customer or paykey.
