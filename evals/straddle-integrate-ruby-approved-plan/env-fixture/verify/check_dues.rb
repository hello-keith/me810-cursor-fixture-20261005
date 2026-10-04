# Fixture-owned behavior check for the dues service, run by the env-fixture Stop hook from the workspace root.
#
# The check-payment behavior existed before Integrate and must still work; the Straddle client factory and
# charge_dues are the plan's change. Every HTTP request the SDK makes is captured below and answered locally.
require "json"
require "minitest/autorun"
require "net/http"
require "straddle"

$LOAD_PATH.unshift(File.join(Dir.pwd, "lib"))

SENT = []

Straddle::Internal::Transport::PooledNetRequester.prepend(Module.new do
  def execute(request)
    body = request[:body]
    body = body.read if body.respond_to?(:read)
    SENT << { method: request[:method].to_s.upcase, path: URI(request[:url].to_s).path, headers: request[:headers].transform_keys(&:downcase), body: JSON.parse(body.to_s) }
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response["content-type"] = "application/json"
    [200, response, [JSON.generate({ data: { id: "chg_synthetic" }, meta: {}, response_type: "object" })].each]
  end
end)

CONFIGURED = { "STRADDLE_API_KEY" => "synthetic-verify-key", "STRADDLE_ENVIRONMENT" => "sandbox" }.freeze

def with_env(env)
  saved = ENV.to_h
  ENV.replace(env)
  yield
ensure
  ENV.replace(saved)
end

class ExistingCheckPayments < Minitest::Test
  def test_recorded_check_reduces_the_balance
    require "dues/payments"
    ledger = []
    Dues::Payments.record_check(ledger, "member-0001", 5000, "1042")
    Dues::Payments.record_check(ledger, "member-0002", 12000, "1043")
    assert_equal 7000, Dues::Payments.balance_due(ledger, "member-0001", 12000)
    assert_equal 0, Dues::Payments.balance_due(ledger, "member-0002", 12000)
  end

  def test_a_check_number_is_recorded_once
    require "dues/payments"
    ledger = []
    Dues::Payments.record_check(ledger, "member-0001", 5000, "1042")
    assert_raises(ArgumentError) { Dues::Payments.record_check(ledger, "member-0003", 5000, "1042") }
    assert_equal 1, ledger.length
  end
end

class StraddleCharges < Minitest::Test
  def setup
    require "dues/payments"
    require "dues/straddle_client"
    SENT.clear
  end

  def charge(member)
    with_env(CONFIGURED) { Dues::Payments.charge_dues(Dues.build_client, member, "paykey-token-full-7c1d", 4500, "192.0.2.10") }
    assert_equal 1, SENT.length, "one create request per charge_dues call"
    SENT.pop
  end

  def test_missing_configuration_fails_before_any_request
    [{}, { "STRADDLE_API_KEY" => "synthetic-verify-key" }, { "STRADDLE_ENVIRONMENT" => "sandbox" }].each do |env|
      with_env(env) { assert_raises(Dues::ConfigurationError) { Dues.build_client } }
    end
    assert_equal [], SENT
  end

  def test_charge_is_created_with_the_token_external_id_and_key
    request = charge("member-0001")
    assert_equal ["POST", "/v1/charges"], [request[:method], request[:path]]
    assert_equal "paykey-token-full-7c1d", request[:body]["paykey"]
    assert_equal 4500, request[:body]["amount"]
    assert_kind_of String, request[:body]["external_id"]
    refute_empty request[:body]["external_id"]
    assert_includes 10..40, request[:headers]["idempotency-key"].to_s.length
    refute request[:headers].key?("straddle-account-id"), "a direct integration sends no Straddle-Account-Id"
  end

  def test_a_retry_reuses_its_key
    first = charge("member-0001")
    retry_request = charge("member-0001")
    assert_equal first[:headers]["idempotency-key"], retry_request[:headers]["idempotency-key"]
    assert_equal first[:body]["external_id"], retry_request[:body]["external_id"]
  end
end
