import { straddle } from './straddle';

export async function createOwner(ownerId: string, name: string, email: string, phone: string) {
  // Marketplace: owners are platform customers, so no Straddle-Account-Id here.
  const customer = await straddle.customers.create({
    'Idempotency-Key': `owner-${ownerId}`,
    type: 'individual',
    name,
    email,
    phone,
    device: { ip_address: '203.0.113.10' },
    external_id: `owner-${ownerId}`,
  });
  console.log('created customer', JSON.stringify(customer));
  return customer.data.id;
}

export async function chargeWalk(paykey: string, walkerAccountId: string, walkId: string, amountCents: number) {
  return straddle.charges.create({
    'Straddle-Account-Id': walkerAccountId,
    'Idempotency-Key': `walk-${walkId}-charge`,
    paykey,
    amount: amountCents,
    currency: 'USD',
    description: `Walk ${walkId}`,
    payment_date: new Date().toISOString().slice(0, 10),
    consent_type: 'internet',
    device: { ip_address: '203.0.113.10' },
    external_id: `walk-${walkId}-charge`,
    config: { balance_check: 'enabled' },
  });
}
