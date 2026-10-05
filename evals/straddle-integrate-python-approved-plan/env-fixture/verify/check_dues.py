"""Fixture-owned behavior check for the dues service, run by the env-fixture Stop hook from the workspace root.

The check-payment behavior existed before Integrate and must still work; the Straddle client factory and
charge_dues are the plan's change. Every HTTP request the SDK makes is captured below and answered locally with a
created charge."""
import json
import os
import sys
import unittest
from unittest import mock

import httpx

sys.path.insert(0, os.getcwd())

SENT = []
CHARGE_ID = "3c8d1f5a-6b2e-4a9c-8d7f-2e1b0a9c4d68"


def _capture(self, request):
    request.read()
    SENT.append(request)
    charge = {
        **json.loads(request.content or b"{}"),
        "id": CHARGE_ID, "status": "created", "created_at": "2026-10-04T12:00:00Z", "updated_at": "2026-10-04T12:00:00Z",
        "status_details": {"message": "Charge created", "reason": "ok", "source": "system", "changed_at": "2026-10-04T12:00:00Z"},
        "status_history": [], "funding_ids": [], "trace_ids": {}, "has_refund": False, "has_resubmit": False, "is_resubmit": False,
    }
    meta = {"api_request_id": "7d2e4f6a-9c1b-4d3e-b5a7-8f0e1d2c3b4a", "api_request_timestamp": "2026-10-04T12:00:00Z"}
    return httpx.Response(200, json={"data": charge, "meta": meta, "response_type": "object"}, request=request)


httpx.HTTPTransport.handle_request = _capture

CONFIGURED = {"STRADDLE_API_KEY": "synthetic-verify-key", "STRADDLE_ENVIRONMENT": "sandbox"}


class ExistingCheckPayments(unittest.TestCase):
    def test_recorded_check_reduces_the_balance(self):
        from dues.payments import balance_due, record_check

        ledger = []
        record_check(ledger, "member-0001", 5000, "1042")
        record_check(ledger, "member-0002", 12000, "1043")
        self.assertEqual(balance_due(ledger, "member-0001", 12000), 7000)
        self.assertEqual(balance_due(ledger, "member-0002", 12000), 0)

    def test_a_check_number_is_recorded_once(self):
        from dues.payments import record_check

        ledger = []
        record_check(ledger, "member-0001", 5000, "1042")
        with self.assertRaises(ValueError):
            record_check(ledger, "member-0003", 5000, "1042")
        self.assertEqual(len(ledger), 1)


class StraddleCharges(unittest.TestCase):
    def setUp(self):
        SENT.clear()

    def charge(self, member):
        from dues.payments import charge_dues
        from dues.straddle_client import build_client

        with mock.patch.dict(os.environ, CONFIGURED, clear=True):
            result = charge_dues(build_client(), member, "paykey-token-full-7c1d", 4500, "192.0.2.10")
        self.assertEqual(len(SENT), 1, "one create request per charge_dues call")
        # charge_dues may return the SDK response, its charge, or the charge id; None means it swallowed a failure.
        result = getattr(result, "data", result)
        self.assertEqual(getattr(result, "id", result), CHARGE_ID, "charge_dues returns the created charge")
        if hasattr(result, "status"):
            self.assertEqual(result.status, "created")
        request = SENT.pop()
        return request, json.loads(request.content)

    def test_missing_configuration_fails_before_any_request(self):
        from dues.straddle_client import ConfigurationError, build_client

        for env in ({}, {"STRADDLE_API_KEY": "synthetic-verify-key"}, {"STRADDLE_ENVIRONMENT": "sandbox"}):
            with mock.patch.dict(os.environ, env, clear=True), self.assertRaises(ConfigurationError):
                build_client()
        self.assertEqual(SENT, [])

    def test_charge_is_created_with_the_token_external_id_and_key(self):
        request, body = self.charge("member-0001")
        self.assertEqual((request.method, request.url.path), ("POST", "/v1/charges"))
        self.assertEqual(body["paykey"], "paykey-token-full-7c1d")
        self.assertEqual(body["amount"], 4500)
        self.assertTrue(isinstance(body.get("external_id"), str) and body["external_id"])
        self.assertTrue(10 <= len(request.headers.get("idempotency-key", "")) <= 40)

    def test_a_retry_reuses_its_key(self):
        first, first_body = self.charge("member-0001")
        retry, retry_body = self.charge("member-0001")
        self.assertEqual(first.headers["idempotency-key"], retry.headers["idempotency-key"])
        self.assertEqual(first_body["external_id"], retry_body["external_id"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
