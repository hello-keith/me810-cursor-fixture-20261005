// Fixture-owned behavior check for the dues service, compiled into the workspace's dues package through a go test
// -overlay by the env-fixture Stop hook. The check-payment behavior existed before Integrate and must still work; the
// Straddle client factory and ChargeDues are the plan's change. Every HTTP request the SDK makes is captured below
// and answered locally.
package dues_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"

	"example.com/dues/dues"
	"github.com/straddle-build/straddle-go/option"
)

type sent struct {
	request *http.Request
	body    map[string]any
}

type capture struct{ requests []sent }

func (c *capture) RoundTrip(request *http.Request) (*http.Response, error) {
	raw, _ := io.ReadAll(request.Body)
	var body map[string]any
	_ = json.Unmarshal(raw, &body)
	c.requests = append(c.requests, sent{request, body})
	return &http.Response{
		StatusCode: 200,
		Header:     http.Header{"Content-Type": {"application/json"}},
		Body:       io.NopCloser(strings.NewReader(`{"data":{"id":"chg_synthetic"},"meta":{},"response_type":"object"}`)),
		Request:    request,
	}, nil
}

func environment(t *testing.T, values map[string]string) {
	for _, name := range []string{"STRADDLE_API_KEY", "STRADDLE_ENVIRONMENT", "BEARER", "STRADDLE_BASE_URL"} {
		t.Setenv(name, "")
		os.Unsetenv(name)
	}
	for name, value := range values {
		t.Setenv(name, value)
	}
}

func charge(t *testing.T, transport *capture) sent {
	environment(t, map[string]string{"STRADDLE_API_KEY": "synthetic-verify-key", "STRADDLE_ENVIRONMENT": "sandbox"})
	client, err := dues.BuildClient(option.WithHTTPClient(&http.Client{Transport: transport}), option.WithMaxRetries(0))
	if err != nil {
		t.Fatalf("BuildClient with configuration: %v", err)
	}
	before := len(transport.requests)
	_, _ = dues.ChargeDues(context.Background(), client, "member-0001", "paykey-token-full-7c1d", 4500, "192.0.2.10")
	if len(transport.requests) != before+1 {
		t.Fatalf("one create request per ChargeDues call, got %d", len(transport.requests)-before)
	}
	return transport.requests[len(transport.requests)-1]
}

func TestFixtureRecordedCheckReducesTheBalance(t *testing.T) {
	ledger, err := dues.RecordCheck(nil, "member-0001", 5000, "1042")
	if err == nil {
		ledger, err = dues.RecordCheck(ledger, "member-0002", 12000, "1043")
	}
	if err != nil {
		t.Fatal(err)
	}
	if got := dues.BalanceDue(ledger, "member-0001", 12000); got != 7000 {
		t.Fatalf("member-0001 balance = %d, want 7000", got)
	}
	if got := dues.BalanceDue(ledger, "member-0002", 12000); got != 0 {
		t.Fatalf("member-0002 balance = %d, want 0", got)
	}
}

func TestFixtureACheckNumberIsRecordedOnce(t *testing.T) {
	ledger, _ := dues.RecordCheck(nil, "member-0001", 5000, "1042")
	ledger, err := dues.RecordCheck(ledger, "member-0003", 5000, "1042")
	if err == nil || len(ledger) != 1 {
		t.Fatalf("repeated check number: err = %v, ledger length = %d, want an error and 1", err, len(ledger))
	}
}

func TestFixtureMissingConfigurationFailsBeforeAnyRequest(t *testing.T) {
	transport := &capture{}
	for _, values := range []map[string]string{{}, {"STRADDLE_API_KEY": "synthetic-verify-key"}, {"STRADDLE_ENVIRONMENT": "sandbox"}} {
		environment(t, values)
		_, err := dues.BuildClient(option.WithHTTPClient(&http.Client{Transport: transport}))
		var configurationError *dues.ConfigurationError
		if !errors.As(err, &configurationError) {
			t.Fatalf("BuildClient with %v: err = %v, want a *dues.ConfigurationError", values, err)
		}
	}
	if len(transport.requests) != 0 {
		t.Fatalf("%d requests sent without configuration, want 0", len(transport.requests))
	}
}

func TestFixtureChargeIsCreatedWithTheTokenExternalIDAndKey(t *testing.T) {
	got := charge(t, &capture{})
	if got.request.Method != "POST" || got.request.URL.Path != "/v1/charges" {
		t.Fatalf("request = %s %s, want POST /v1/charges", got.request.Method, got.request.URL.Path)
	}
	if got.body["paykey"] != "paykey-token-full-7c1d" || got.body["amount"] != float64(4500) {
		t.Fatalf("paykey = %v, amount = %v, want the given token and 4500", got.body["paykey"], got.body["amount"])
	}
	if id, _ := got.body["external_id"].(string); id == "" {
		t.Fatalf("external_id = %v, want a non-empty string", got.body["external_id"])
	}
	if key := got.request.Header.Get("Idempotency-Key"); len(key) < 10 || len(key) > 40 {
		t.Fatalf("Idempotency-Key = %q, want 10 to 40 characters", key)
	}
}

func TestFixtureARetryReusesItsKey(t *testing.T) {
	transport := &capture{}
	first, retry := charge(t, transport), charge(t, transport)
	if first.request.Header.Get("Idempotency-Key") != retry.request.Header.Get("Idempotency-Key") {
		t.Fatal("the retry sent a different Idempotency-Key")
	}
	if first.body["external_id"] != retry.body["external_id"] {
		t.Fatal("the retry sent a different external_id")
	}
}
