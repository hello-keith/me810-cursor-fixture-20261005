---
type: llm
focus: last_message
arm: with-only
---

This is the run's closing reply, the one that asks the developer to approve the Sandbox writes. Judge it alone; earlier messages don't count.

FAIL if this reply has no preview table, or points to a preview shown earlier ("the preview above", "as shown earlier") instead of carrying it; if the table is shortened: a row or column left out, rows elided ("…", "rows 3-6 as before", "same as above"), a payload cell that points to another row instead of writing its values ("same as 2a", "same as #6 except …"; an ID an earlier row returns, such as "#1 data.id", is fine), skipped row numbers, or a write the plan lists missing from both the table and the "Not included" line; if the visual is missing, replaces the table, or comes before the table; if no approval question follows the visual; or if the visual names any operation, row, account, ID, host, external ID, outcome or other value the preview doesn't show in its header lines or table, such as an extra create, a webhook or FIFO registration, a refund or payout the table lacks, a host or URL that no header line names, an outcome written differently from the table, a write named only on the "Not included" line, or a different account for a row. Also FAIL if the visual contains a key, token or paykey value.
