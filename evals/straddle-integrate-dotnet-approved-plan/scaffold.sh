#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/Dues tests/Dues.Tests
printf 'bin/\nobj/\n.nuget/\n' > .gitignore
cat > nuget.config <<'EOF_0'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <config>
    <add key="globalPackagesFolder" value=".nuget/packages" />
  </config>
  <packageSources>
    <clear />
    <add key="restored" value=".nuget/packages" />
  </packageSources>
</configuration>
EOF_0
cat > AGENTS.md <<'EOF_1'
Run tests with `dotnet test --no-restore`. Packages are already restored into .nuget/packages. Application code lives in src/Dues/.
EOF_1
cat > README.md <<'EOF_2'
# Dues

Small service that collects club membership dues. Members pay by check today; Straddle Pay by Bank is being added as a direct integration.
EOF_2
cat > Dues.sln <<'EOF_3'

Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "Dues", "src\Dues\Dues.csproj", "{7B1F3A52-1C2E-4C55-9E36-1D0A6C2B8E01}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "Dues.Tests", "tests\Dues.Tests\Dues.Tests.csproj", "{3E6D9B47-8A41-4F0B-B2C5-5F7E2D1A9C02}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{7B1F3A52-1C2E-4C55-9E36-1D0A6C2B8E01}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{7B1F3A52-1C2E-4C55-9E36-1D0A6C2B8E01}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{7B1F3A52-1C2E-4C55-9E36-1D0A6C2B8E01}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{7B1F3A52-1C2E-4C55-9E36-1D0A6C2B8E01}.Release|Any CPU.Build.0 = Release|Any CPU
		{3E6D9B47-8A41-4F0B-B2C5-5F7E2D1A9C02}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{3E6D9B47-8A41-4F0B-B2C5-5F7E2D1A9C02}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{3E6D9B47-8A41-4F0B-B2C5-5F7E2D1A9C02}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{3E6D9B47-8A41-4F0B-B2C5-5F7E2D1A9C02}.Release|Any CPU.Build.0 = Release|Any CPU
	EndGlobalSection
EndGlobal
EOF_3
cat > src/Dues/Dues.csproj <<'EOF_4'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Straddle" Version="1.0.4" />
  </ItemGroup>
</Project>
EOF_4
cat > src/Dues/StraddleClientFactory.cs <<'EOF_5'
namespace Dues;

// Straddle client factory (implemented by Integrate).
public static class StraddleClientFactory
{
}
EOF_5
cat > src/Dues/Payments.cs <<'EOF_6'
namespace Dues;

public sealed record CheckPayment(string Member, int AmountCents, string CheckNumber);

// Dues payments. Members pay by check today; Straddle charges are added by Integrate.
public static class Payments
{
    // Record a paper check against a member. A check number is recorded once.
    public static void RecordCheck(List<CheckPayment> ledger, string memberExternalId, int amountCents, string checkNumber)
    {
        if (amountCents <= 0)
            throw new ArgumentException("a check must be for a positive amount");
        if (ledger.Any(entry => entry.CheckNumber == checkNumber))
            throw new ArgumentException($"check {checkNumber} is already recorded");
        ledger.Add(new CheckPayment(memberExternalId, amountCents, checkNumber));
    }

    // What the member still owes this period after their recorded checks, never below zero.
    public static int BalanceDue(List<CheckPayment> ledger, string memberExternalId, int duesCents)
    {
        var paid = ledger.Where(entry => entry.Member == memberExternalId).Sum(entry => entry.AmountCents);
        return Math.Max(duesCents - paid, 0);
    }
}
EOF_6
cat > tests/Dues.Tests/Dues.Tests.csproj <<'EOF_7'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.11.1" />
    <PackageReference Include="xunit" Version="2.9.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
  </ItemGroup>
  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="../../src/Dues/Dues.csproj" />
  </ItemGroup>
</Project>
EOF_7
cat > tests/Dues.Tests/PaymentsTests.cs <<'EOF_8'
namespace Dues.Tests;

public class CheckPaymentTests
{
    [Fact]
    public void ChecksReduceTheBalance()
    {
        var ledger = new List<CheckPayment>();
        Payments.RecordCheck(ledger, "member-0001", 5000, "1042");
        Assert.Equal(7000, Payments.BalanceDue(ledger, "member-0001", 12000));
    }

    [Fact]
    public void ACheckNumberIsRecordedOnce()
    {
        var ledger = new List<CheckPayment>();
        Payments.RecordCheck(ledger, "member-0001", 5000, "1042");
        Assert.Throws<ArgumentException>(() => Payments.RecordCheck(ledger, "member-0002", 5000, "1042"));
    }
}
EOF_8
cat > straddle-integration-plan.md <<'EOF_9'
# Straddle integration plan

## Status

- Plan state: Approved
- Approval: 2026-09-28, "The plan is approved.", recorded by straddle-plan, sha256 d7f5d3d1e93b5a71d3736e0cef4e2737bb1905ee7260a0bdcd17ec59ef4bad32
- Last reviewed: 2026-09-28
- Repository and branch: dues, main
- Straddle skills version: 0.1.0
- API contract version: 1.0.4
- SDK package and exact installed version: Straddle 1.0.4 (NuGet, restored into .nuget/packages)

## Goal

Collect club membership dues by bank account. One club, one Straddle account (direct integration), Pay by Bank charges only.

## Decisions

| Decision | Value | Source |
| --- | --- | --- |
| Integration type | direct (`account`) | developer |
| Products | charges | developer |
| Bank connection | bank details | developer |
| SDK | C# | developer |
| Notification path | webhook endpoint | developer |

## Repository evidence

- Language, framework, package manager: C# on .NET 8, no framework, NuGet with packages restored into .nuget/packages, xUnit tests
- Test command: `dotnet test --no-restore`
- Existing payment or bank-linking providers to keep: check payments in src/Dues/Payments.cs (`RecordCheck`, `BalanceDue`), unchanged
- Entry points where Straddle calls belong: src/Dues/StraddleClientFactory.cs, src/Dues/Payments.cs
- Existing tests to extend: none; tests/Dues.Tests/PaymentsTests.cs covers check payments, stays unchanged and must keep passing

## Application flow

1. Create or reuse the member customer by external ID.
2. Connect the member's bank account through Bridge with bank details; the create returns the paykey `id` and the full token in `paykey`. Store the token encrypted, and never record it in this plan.
3. Create the dues charge with that token in `Paykey`, consent, payment date, external ID, and idempotency key.
4. Receive status changes through the webhook endpoint.
5. Reconcile from delivered events.

## Account scope

| Operation | Header for this integration type | Source |
| --- | --- | --- |
| all | omitted (direct integrations never send Straddle-Account-Id) | best-practices account-scope reference |

- How the application selects the acting account: not applicable (direct)
- How it switches between accounts: not applicable
- Missing required account: not applicable

## Notifications

- Endpoint type and events subscribed: webhook endpoint, charge events
- Signature verification helper and raw-body access: Standard Webhooks signature check on the raw request body
- Duplicate handling (event ID storage): store `webhook-id` before responding
- Prompt `2xx`: yes
- Status transitions to record, including `paid` before `reversed` with `R01`: yes

## Configuration

- `STRADDLE_API_KEY` read from the process environment; a missing key or environment raises a configuration error before any request.
- Environment: Sandbox (`https://sandbox.straddle.com`), selected with `STRADDLE_ENVIRONMENT=sandbox`.

## File changes

| File | Existing or new | Change | Behavior proved | Test |
| --- | --- | --- | --- | --- |
| src/Dues/StraddleClientFactory.cs | existing (stub) | `StraddleClientFactory.Build()` builds the SDK `StraddleClient` from STRADDLE_API_KEY and STRADDLE_ENVIRONMENT in the process environment, throwing `StraddleConfigurationException` (defined there) when either is missing | zero requests on missing configuration | tests/Dues.Tests/StraddleTests.cs |
| src/Dues/Payments.cs | existing | add `ChargeDues(StraddleClient client, string memberExternalId, string paykeyToken, int amountCents, string ip)` creating the charge with external ID and a 10-40 character idempotency key; `RecordCheck` and `BalanceDue` stay as they are | key and external ID on every create; check payments unchanged | tests/Dues.Tests/StraddleTests.cs |
| tests/Dues.Tests/StraddleTests.cs | new | xUnit tests with the client's `HttpClient` replaced by a stub handler, no network | configuration error, idempotency key, external ID | itself |

## Future Sandbox writes

| Order | Operation | Executing tool | Account | External ID | Idempotency key source |
| --- | --- | --- | --- | --- | --- |
| 1 | createCustomer | SDK `client.Customers.Create` | omitted | member-0001 | `cust-` + external ID |
| 2 | createBankAccountPaykey | SDK `client.Bridge.CreateBankAccountPaykey` | omitted | member-0001 | `pk-` + external ID |
| 3 | createCharge (sandbox_outcome paid), paykey from row 2 `data.paykey` | SDK `client.Charges.Create` | omitted | dues-2026-10-0001 | `chg-` + external ID |

## Verification

- Repository tests: `dotnet test --no-restore`
- Sandbox success outcome: row 3 reaches `paid`
- Sandbox failure or return outcome: a second charge with `reversed_insufficient_funds`, later
- Retry with the same idempotency key: repeat row 3, expect the same resource
- Two-account proof: not applicable (direct)
- Notification proof (one signed event received, duplicate ignored): later, with the webhook handler

## Unresolved decisions

- None.

## Approval boundaries

- Approving this plan permits only the file changes listed above.
- Existing provider code stays unless a separate migration plan authorizes it.
- Every Sandbox write needs its own preview and approval at the time it runs.
- The fourteen excluded operations run only through the SDK or the Straddle CLI.
EOF_9
dotnet restore --source https://api.nuget.org/v3/index.json -nologo -v quiet
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -q -m scaffold
