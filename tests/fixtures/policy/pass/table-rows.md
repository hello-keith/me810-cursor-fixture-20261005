# Audit table

| ID | Look for | Recovery |
| --- | --- | --- |
| S4 | `execute-request` in scripts for the fourteen SDK/CLI-only operations | Route through the SDK or CLI |
| S5 | Logging of unmask or reveal results | Log IDs only |

Anti-patterns to flag in status checks:

| ID | Look for |
| --- | --- |
| N1 | A loop around `GET /v1/charges/{id}` or `straddle tail` to detect status |
