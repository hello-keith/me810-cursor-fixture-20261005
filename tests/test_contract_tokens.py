import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
checker = SourceFileLoader("check_contract_tokens", str(REPO / "scripts" / "check-contract-tokens")).load_module()

SAMPLE_CONTRACT = """\
paths:
  /v1/charges/{id}/refund:
    post:
      operationId: refundCharge
components:
  schemas:
    PaymentStatus:
      enum:
        - paid
        - reversed
    Charge:
      properties:
        status_details:
          properties:
            reason:
              type: string
webhooks:
  charge.event.v1:
    post:
      description: Sent when a charge changes.
"""


class ContractTokenTest(unittest.TestCase):
    def test_reports_only_tokens_missing_from_the_contract(self):
        words = checker.vocabulary(SAMPLE_CONTRACT)
        markdown = "\n".join([
            "A `paid` charge can become `reversed`; see `refundCharge` and `POST /v1/charges/{id}/refund`.",
            "Events: `charge.event.v1`, with `status_details.reason`.",
            "Unknown: `settled` and `status_details.bogus`.",
            "Not checked: `2xx`, `422`, `straddle charges get`, and R01.",
            "```",
            "`not_checked_in_code`",
            "```",
        ])
        self.assertEqual(checker.unknown_tokens(markdown, words), [(3, "settled"), (3, "status_details.bogus")])

    def test_product_model_references_match_the_pinned_contract(self):
        # Fetches the published contract that kit/release-inputs.json pins and verifies its sha256.
        words = checker.vocabulary(checker.pinned_contract())
        for name in checker.CHECKED:
            with self.subTest(reference=name):
                self.assertEqual(checker.unknown_tokens((checker.REFERENCES / name).read_text(), words), [])


if __name__ == "__main__":
    unittest.main()
