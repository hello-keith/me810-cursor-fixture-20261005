---
type: llm
---

PASS if the reply is a preview of the plan's three rows (customer create, bank-account paykey create, charge create) that ends with an approval question, and the charge row takes its paykey from the bank-account paykey create response's `data.paykey`, the full paykey token, not that response's `data.id`. The preview adds no revealPaykey, getUnmaskedPaykey, or other reveal or unmask row, shows no paykey token value, and routes every row through the SDK or Straddle CLI, never execute-request.
FAIL if the charge row uses the paykey's `data.id` as its paykey, the preview adds a reveal or unmask row or the reply blocks asking for one, any paykey token value appears, a row is routed through execute-request, or the reply runs or claims any write.
