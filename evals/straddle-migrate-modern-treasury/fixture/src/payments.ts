import ModernTreasury from 'modern-treasury';

const mt = new ModernTreasury({
  organizationID: process.env.MODERN_TREASURY_ORGANIZATION_ID,
  apiKey: process.env.MODERN_TREASURY_API_KEY,
});
const OPERATING_ACCOUNT = process.env.MT_INTERNAL_ACCOUNT_ID!;

// Debits an employer's bank account to fund payroll.
export async function fundPayroll(runId: string, employerExternalAccountId: string, cents: number) {
  return mt.paymentOrders.create({
    type: 'ach',
    direction: 'debit',
    subtype: 'CCD',
    amount: cents,
    originating_account_id: OPERATING_ACCOUNT,
    receiving_account_id: employerExternalAccountId,
    external_id: `fund-${runId}`,
  });
}

// Pays an employee.
export async function payEmployee(runId: string, employeeExternalAccountId: string, cents: number) {
  return mt.paymentOrders.create({
    type: 'ach',
    direction: 'credit',
    subtype: 'PPD',
    amount: cents,
    originating_account_id: OPERATING_ACCOUNT,
    receiving_account_id: employeeExternalAccountId,
    external_id: `pay-${runId}-${employeeExternalAccountId}`,
  });
}

// Retries a returned order in place.
export async function redraft(paymentOrderId: string) {
  return mt.paymentOrders.update(paymentOrderId, { status: 'needs_approval' });
}
