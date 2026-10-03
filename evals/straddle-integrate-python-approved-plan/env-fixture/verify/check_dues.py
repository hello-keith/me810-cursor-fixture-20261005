"""Fixture-owned behavior check for the dues service, run by the env-fixture Stop hook from the workspace root.

The check-payment behavior existed before Integrate and must still work; the Straddle client factory and
charge_dues are the plan's change. Every HTTP request the SDK makes is captured below and answered locally."""
import json
import os
import sys
import unittest
from unittest import mock

import httpx

sys.path.insert(0, os.getcwd())

SENT = []


def _capture(self, request):
    request.read()
    SENT.append(request)
    return httpx.Response(200, json={"data": {"id": "chg_synthetic"}, "meta": {}, "response_type": "object"}, request=request)


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
            charge_dues(build_client(), member, "paykey-token-full-7c1d", 4500, "192.0.2.10")
        self.assertEqual(len(SENT), 1, "one create request per charge_dues call")
        request = SENT.pop()
        return request, json.loads(request.content)

    def test_missing_configuration_fails_before_any_request(self):
        from dues.straddle_client import ConfigurationError, build_client

        for env in ({}, {"STRADDLE_API_KEY": "synthetic-verify-key"}, {"STRADDLE_ENVIRONMENT": "sandbox"}):
            with mock.patch.dict(os.environ, env, clear=True), self.assertRaises(ConfigurationError):
                build_client()
        self.assertEqual(SENT, [])

    def test_charge_is_created_in_sandbox_with_the_full_token(self):
        request, body = self.charge("member-0001")
        self.assertEqual((request.method, request.url.host, request.url.path), ("POST", "sandbox.straddle.com", "/v1/charges"))
        self.assertEqual(request.headers.get("authorization"), "Bearer " + CONFIGURED["STRADDLE_API_KEY"])
        self.assertNotIn("straddle-account-id", request.headers)
        self.assertEqual(body["paykey"], "paykey-token-full-7c1d")
        self.assertEqual(body["amount"], 4500)
        self.assertEqual(body["device"]["ip_address"], "192.0.2.10")
        self.assertTrue(isinstance(body.get("external_id"), str) and body["external_id"])
        self.assertTrue(10 <= len(request.headers.get("idempotency-key", "")) <= 40)

    def test_a_retry_reuses_its_key_and_another_member_does_not(self):
        first, first_body = self.charge("member-0001")
        retry, retry_body = self.charge("member-0001")
        other, _ = self.charge("member-0002")
        self.assertEqual(first.headers["idempotency-key"], retry.headers["idempotency-key"])
        self.assertEqual(first_body["external_id"], retry_body["external_id"])
        self.assertNotEqual(first.headers["idempotency-key"], other.headers["idempotency-key"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
