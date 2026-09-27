// This file is not part of any build in the skills repository. derive.ts
// compiles it into the straddle-cli internal/straddleacct package with
// `go test -overlay`, so every expected outcome comes from the CLI's own
// Classify and Resolve functions against the contract pinned by
// contract.lock.json. Nothing in the CLI checkout is modified.
package straddleacct

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"sigs.k8s.io/yaml"
)

const (
	corpusAccountA = "00000000-0000-4000-8000-00000000000a"
	corpusAccountB = "00000000-0000-4000-8000-00000000000b"
)

// Corpus integration names follow the build plan; the CLI calls a direct
// integration "account".
var corpusIntegrationTypes = []struct{ Corpus, CLI string }{
	{"direct", TypeAccount},
	{"saas", TypeSaaS},
	{"marketplace", TypeMarketplace},
}

var corpusHTTPMethods = []string{"get", "put", "post", "delete", "options", "head", "patch", "trace"}

type corpusOperation struct {
	ID                   string `json:"id"`
	Method               string `json:"method"`
	Path                 string `json:"path"`
	Resource             string `json:"resource"`
	AcceptsAccountHeader bool   `json:"accepts_account_header"`
}

type corpusAccountInput struct {
	Selected *string `json:"selected"`
	Explicit *string `json:"explicit"`
}

type corpusExpectation struct {
	Outcome          string  `json:"outcome"`
	Header           string  `json:"header,omitempty"`
	Value            *string `json:"value,omitempty"`
	Reason           string  `json:"reason,omitempty"`
	OutboundRequests int     `json:"outbound_requests"`
}

type corpusVector struct {
	ID              string             `json:"id"`
	IntegrationType string             `json:"integration_type"`
	Operation       string             `json:"operation"`
	Policy          string             `json:"policy"`
	ActingAccount   corpusAccountInput `json:"acting_account"`
	Expected        corpusExpectation  `json:"expected"`
}

type corpusStep struct {
	Action    string             `json:"action"`
	Account   *string            `json:"account,omitempty"`
	Operation string             `json:"operation,omitempty"`
	Explicit  *string            `json:"explicit,omitempty"`
	Expected  *corpusExpectation `json:"expected,omitempty"`
}

type corpusCaller struct {
	Name       string            `json:"name"`
	Credential string            `json:"credential"`
	Selected   *string           `json:"selected"`
	Expected   corpusExpectation `json:"expected"`
}

type corpusScenario struct {
	ID              string         `json:"id"`
	Kind            string         `json:"kind"`
	IntegrationType string         `json:"integration_type"`
	Steps           []corpusStep   `json:"steps,omitempty"`
	Operation       string         `json:"operation,omitempty"`
	CallsPerCaller  int            `json:"calls_per_caller,omitempty"`
	MinInFlight     int            `json:"min_in_flight,omitempty"`
	Callers         []corpusCaller `json:"callers,omitempty"`
}

type corpusPathOperation struct {
	OperationID string                  `json:"operationId"`
	Parameters  []policyMatrixParameter `json:"parameters"`
}

func TestExportAccountScopeCorpus(t *testing.T) {
	out := os.Getenv("ACCOUNT_SCOPE_CORPUS_OUT")
	commit := os.Getenv("ACCOUNT_SCOPE_CLI_COMMIT")
	if out == "" || commit == "" {
		t.Skip("run through fixtures/account-scope/derive.ts")
	}

	specBytes, err := os.ReadFile(filepath.Join("..", "..", "spec.yaml"))
	if err != nil {
		t.Fatalf("read spec.yaml: %v", err)
	}
	var lock struct {
		SchemaVersion   int    `json:"schema_version"`
		ContractVersion string `json:"contract_version"`
		RegistryRef     string `json:"registry_ref"`
		PublishedSHA256 string `json:"published_sha256"`
	}
	lockBytes, err := os.ReadFile(filepath.Join("..", "..", "contract.lock.json"))
	if err != nil {
		t.Fatalf("read contract.lock.json: %v", err)
	}
	if err := json.Unmarshal(lockBytes, &lock); err != nil {
		t.Fatalf("parse contract.lock.json: %v", err)
	}
	digest := sha256.Sum256(specBytes)
	if got := hex.EncodeToString(digest[:]); got != lock.PublishedSHA256 {
		t.Fatalf("spec.yaml sha256 %s does not match contract.lock.json %s", got, lock.PublishedSHA256)
	}

	operations := corpusLoadOperations(t, specBytes)
	byID := make(map[string]corpusOperation, len(operations))
	for _, operation := range operations {
		byID[operation.ID] = operation
	}

	a, b := corpusAccountA, corpusAccountB
	conditions := []struct {
		Name  string
		Input corpusAccountInput
	}{
		{"no-account", corpusAccountInput{}},
		{"selected-a", corpusAccountInput{Selected: &a}},
		{"explicit-a", corpusAccountInput{Explicit: &a}},
		{"selected-a-explicit-b", corpusAccountInput{Selected: &a, Explicit: &b}},
	}

	var vectors []corpusVector
	for _, integration := range corpusIntegrationTypes {
		for _, operation := range operations {
			decision := corpusClassify(operation, integration.CLI)
			for _, condition := range conditions {
				vectors = append(vectors, corpusVector{
					ID:              integration.Corpus + "." + operation.ID + "." + condition.Name,
					IntegrationType: integration.Corpus,
					Operation:       operation.ID,
					Policy:          corpusDecisionName(decision),
					ActingAccount:   condition.Input,
					Expected:        corpusResolve(decision, condition.Input),
				})
			}
		}
	}

	scenarios := corpusScenarios(t, byID)

	var buf bytes.Buffer
	writeJSON := func(v any) {
		encoded, err := json.Marshal(v)
		if err != nil {
			t.Fatalf("encode corpus: %v", err)
		}
		buf.Write(encoded)
	}
	writeList := func(name string, n int, item func(int) any, last bool) {
		buf.WriteString("  \"" + name + "\": [\n")
		for i := 0; i < n; i++ {
			buf.WriteString("    ")
			writeJSON(item(i))
			if i < n-1 {
				buf.WriteString(",")
			}
			buf.WriteString("\n")
		}
		buf.WriteString("  ]")
		if !last {
			buf.WriteString(",")
		}
		buf.WriteString("\n")
	}

	buf.WriteString("{\n  \"schema_version\": 1,\n  \"header\": ")
	writeJSON(Header)
	buf.WriteString(",\n  \"contract\": ")
	writeJSON(map[string]string{
		"contract_version": lock.ContractVersion,
		"registry_ref":     lock.RegistryRef,
		"published_sha256": lock.PublishedSHA256,
	})
	buf.WriteString(",\n  \"policy_source\": ")
	writeJSON(map[string]string{
		"repository": "straddle-build/straddle-cli",
		"commit":     commit,
		"package":    "internal/straddleacct",
		"functions":  "Classify, Resolve",
	})
	buf.WriteString(",\n  \"accounts\": ")
	writeJSON(map[string]string{"A": corpusAccountA, "B": corpusAccountB})
	buf.WriteString(",\n")
	writeList("operations", len(operations), func(i int) any { return operations[i] }, false)
	writeList("vectors", len(vectors), func(i int) any { return vectors[i] }, false)
	writeList("scenarios", len(scenarios), func(i int) any { return scenarios[i] }, true)
	buf.WriteString("}\n")

	if err := os.WriteFile(out, buf.Bytes(), 0o644); err != nil {
		t.Fatalf("write corpus: %v", err)
	}
}

func corpusLoadOperations(t *testing.T, specBytes []byte) []corpusOperation {
	t.Helper()
	var spec struct {
		Paths      map[string]map[string]json.RawMessage `json:"paths"`
		Components struct {
			Parameters map[string]policyMatrixParameter `json:"parameters"`
		} `json:"components"`
	}
	if err := yaml.Unmarshal(specBytes, &spec); err != nil {
		t.Fatalf("parse spec.yaml: %v", err)
	}

	var operations []corpusOperation
	seen := map[string]bool{}
	for path, item := range spec.Paths {
		var pathParameters []policyMatrixParameter
		if raw, ok := item["parameters"]; ok {
			if err := json.Unmarshal(raw, &pathParameters); err != nil {
				t.Fatalf("parse parameters for %s: %v", path, err)
			}
		}
		pathDeclares, err := policyMatrixDeclaresAccountHeader(pathParameters, spec.Components.Parameters)
		if err != nil {
			t.Fatalf("path %s: %v", path, err)
		}
		for _, method := range corpusHTTPMethods {
			raw, ok := item[method]
			if !ok {
				continue
			}
			var operation corpusPathOperation
			if err := json.Unmarshal(raw, &operation); err != nil {
				t.Fatalf("parse %s %s: %v", method, path, err)
			}
			if operation.OperationID == "" || seen[operation.OperationID] {
				t.Fatalf("%s %s has missing or duplicate operationId %q", method, path, operation.OperationID)
			}
			seen[operation.OperationID] = true
			operationDeclares, err := policyMatrixDeclaresAccountHeader(operation.Parameters, spec.Components.Parameters)
			if err != nil {
				t.Fatalf("%s %s: %v", method, path, err)
			}
			operations = append(operations, corpusOperation{
				ID:                   operation.OperationID,
				Method:               strings.ToUpper(method),
				Path:                 path,
				Resource:             ResourceFromPath(path),
				AcceptsAccountHeader: pathDeclares || operationDeclares,
			})
		}
	}
	sort.Slice(operations, func(i, j int) bool {
		if operations[i].Path != operations[j].Path {
			return operations[i].Path < operations[j].Path
		}
		return operations[i].Method < operations[j].Method
	})
	return operations
}

func corpusClassify(operation corpusOperation, integrationType string) Decision {
	return Classify(operation.Path, operation.Method, integrationType, operation.AcceptsAccountHeader)
}

func corpusDecisionName(decision Decision) string {
	switch decision {
	case Forbid:
		return "forbid"
	case Require:
		return "require"
	case Allow:
		return "allow"
	}
	panic("unknown straddleacct.Decision")
}

func corpusResolve(decision Decision, input corpusAccountInput) corpusExpectation {
	flag, flagChanged, sticky := "", false, ""
	if input.Explicit != nil {
		flag, flagChanged = *input.Explicit, true
	}
	if input.Selected != nil {
		sticky = *input.Selected
	}
	value, send, err := Resolve(decision, flag, flagChanged, sticky)
	if err != nil {
		return corpusExpectation{Outcome: "local_rejection", Reason: err.(*PolicyError).Reason, OutboundRequests: 0}
	}
	if !send {
		return corpusExpectation{Outcome: "request", Header: "absent", OutboundRequests: 1}
	}
	return corpusExpectation{Outcome: "request", Header: "present", Value: &value, OutboundRequests: 1}
}

func corpusScenarios(t *testing.T, byID map[string]corpusOperation) []corpusScenario {
	t.Helper()
	a, b := corpusAccountA, corpusAccountB
	cli := map[string]string{}
	for _, integration := range corpusIntegrationTypes {
		cli[integration.Corpus] = integration.CLI
	}
	call := func(integration, operationID string, selected, explicit *string) corpusStep {
		operation, ok := byID[operationID]
		if !ok {
			t.Fatalf("scenario operation %q is absent from the contract", operationID)
		}
		expected := corpusResolve(corpusClassify(operation, cli[integration]), corpusAccountInput{Selected: selected, Explicit: explicit})
		return corpusStep{Action: "call", Operation: operationID, Explicit: explicit, Expected: &expected}
	}
	sel := func(account *string) corpusStep { return corpusStep{Action: "select", Account: account} }

	var scenarios []corpusScenario
	for _, integration := range []string{"saas", "marketplace"} {
		scenarios = append(scenarios, corpusScenario{
			ID:              integration + ".switch-a-b",
			Kind:            "sequence",
			IntegrationType: integration,
			Steps: []corpusStep{
				sel(&a),
				call(integration, "createCharge", &a, nil),
				call(integration, "createCustomer", &a, nil),
				sel(&b),
				call(integration, "createCharge", &b, nil),
				call(integration, "createPayout", &b, nil),
				call(integration, "createPayout", &b, &a),
				call(integration, "createPayout", &b, nil),
				call(integration, "createCustomer", &b, nil),
				call(integration, "createBankAccountPaykey", &b, nil),
				call(integration, "listOrganizations", &b, nil),
				call(integration, "getAccount", &b, nil),
				sel(nil),
				call(integration, "createCharge", nil, nil),
				call(integration, "getCharge", nil, nil),
			},
		})
		for _, variant := range []struct {
			name        string
			credentialY string
			selectedY   *string
		}{
			{"concurrent-shared-credential", "fixture-credential-x", &b},
			{"concurrent-separate-credentials", "fixture-credential-y", &b},
			{"concurrent-missing-scope", "fixture-credential-y", nil},
		} {
			callers := []corpusCaller{
				{Name: "x", Credential: "fixture-credential-x", Selected: &a},
				{Name: "y", Credential: variant.credentialY, Selected: variant.selectedY},
			}
			for i := range callers {
				callers[i].Expected = *call(integration, "createCharge", callers[i].Selected, nil).Expected
			}
			scenarios = append(scenarios, corpusScenario{
				ID:              integration + "." + variant.name,
				Kind:            "concurrent",
				IntegrationType: integration,
				Operation:       "createCharge",
				CallsPerCaller:  8,
				MinInFlight:     2,
				Callers:         callers,
			})
		}
	}
	scenarios = append(scenarios, corpusScenario{
		ID:              "direct.credential-scope",
		Kind:            "sequence",
		IntegrationType: "direct",
		Steps: []corpusStep{
			call("direct", "createCharge", nil, nil),
			call("direct", "createCustomer", nil, nil),
			call("direct", "createCharge", nil, &a),
			sel(&a),
			call("direct", "createPayout", &a, nil),
		},
	})
	return scenarios
}
