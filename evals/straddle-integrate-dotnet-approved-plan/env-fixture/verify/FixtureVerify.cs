// Fixture-owned behavior check for the dues service, compiled into the workspace's test project by the env-fixture
// Stop hook. The check-payment behavior existed before Integrate and must still work; the Straddle client factory and
// ChargeDues are the plan's change. Every HTTP request the SDK makes goes through CaptureHandler and is answered locally.
using System.Net;
using System.Reflection;
using System.Text;
using System.Text.Json;
using Straddle;

namespace Dues.FixtureVerify;

sealed class CaptureHandler : HttpMessageHandler
{
    public readonly List<(HttpRequestMessage Request, string Body)> Sent = new();

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken token)
    {
        var body = request.Content == null ? "" : await request.Content.ReadAsStringAsync(token);
        Sent.Add((request, body));
        return new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(
                "{\"data\":{\"id\":\"chg_synthetic\"},\"meta\":{},\"response_type\":\"object\"}",
                Encoding.UTF8,
                "application/json"),
        };
    }
}

[Collection("FixtureVerify")]
public class FixtureVerifyExistingCheckPayments
{
    [Fact]
    public void RecordedCheckReducesTheBalance()
    {
        var ledger = new List<CheckPayment>();
        Payments.RecordCheck(ledger, "member-0001", 5000, "1042");
        Payments.RecordCheck(ledger, "member-0002", 12000, "1043");
        Assert.Equal(7000, Payments.BalanceDue(ledger, "member-0001", 12000));
        Assert.Equal(0, Payments.BalanceDue(ledger, "member-0002", 12000));
    }

    [Fact]
    public void ACheckNumberIsRecordedOnce()
    {
        var ledger = new List<CheckPayment>();
        Payments.RecordCheck(ledger, "member-0001", 5000, "1042");
        Assert.Throws<ArgumentException>(() => Payments.RecordCheck(ledger, "member-0003", 5000, "1042"));
        Assert.Single(ledger);
    }
}

[Collection("FixtureVerify")]
public class FixtureVerifyStraddleCharges
{
    static void SetConfiguration(string? key, string? environment)
    {
        Environment.SetEnvironmentVariable("STRADDLE_API_KEY", key);
        Environment.SetEnvironmentVariable("STRADDLE_ENVIRONMENT", environment);
    }

    static async Task<(HttpRequestMessage Request, JsonElement Body)> Charge(string member)
    {
        var handler = new CaptureHandler();
        var client = new StraddleClient
        {
            Bearer = "synthetic-verify-key",
            BaseUrl = "https://sandbox.straddle.com",
            MaxRetries = 0,
            HttpClient = new HttpClient(handler),
        };
        var charge = typeof(Payments).GetMethod("ChargeDues", BindingFlags.Public | BindingFlags.Static)!;
        var result = charge.Invoke(null, new object[] { client, member, "paykey-token-full-7c1d", 4500, "192.0.2.10" });
        if (result is Task task)
            await task;
        Assert.Single(handler.Sent);
        var (request, body) = handler.Sent[0];
        return (request, JsonDocument.Parse(body).RootElement);
    }

    [Fact]
    public void MissingConfigurationFailsBeforeAnyRequest()
    {
        foreach (var (key, environment) in new[] { ((string?)null, (string?)null), ("synthetic-verify-key", null), (null, "sandbox") })
        {
            SetConfiguration(key, environment);
            Assert.Throws<StraddleConfigurationException>(() => StraddleClientFactory.Build());
        }
        SetConfiguration("synthetic-verify-key", "sandbox");
        Assert.IsType<StraddleClient>(StraddleClientFactory.Build());
    }

    [Fact]
    public async Task ChargeIsCreatedWithTheTokenExternalIdAndKey()
    {
        var (request, body) = await Charge("member-0001");
        Assert.Equal(("POST", "/v1/charges"), (request.Method.Method, request.RequestUri!.AbsolutePath));
        Assert.Equal("paykey-token-full-7c1d", body.GetProperty("paykey").GetString());
        Assert.Equal(4500, body.GetProperty("amount").GetInt32());
        Assert.False(string.IsNullOrEmpty(body.GetProperty("external_id").GetString()));
        var key = request.Headers.GetValues("Idempotency-Key").Single();
        Assert.InRange(key.Length, 10, 40);
    }

    [Fact]
    public async Task ARetryReusesItsKey()
    {
        var (first, firstBody) = await Charge("member-0001");
        var (retry, retryBody) = await Charge("member-0001");
        Assert.Equal(first.Headers.GetValues("Idempotency-Key").Single(), retry.Headers.GetValues("Idempotency-Key").Single());
        Assert.Equal(firstBody.GetProperty("external_id").GetString(), retryBody.GetProperty("external_id").GetString());
    }
}
