import { straddle } from './straddle';

export async function chargeWalk(paykey: string, walkerAccountId: string, walkId: string, amountCents: number) {
  const charge = await straddle.charges.create({
    'Straddle-Account-Id': walkerAccountId,
    paykey,
    amount: amountCents,
    currency: 'USD',
    description: `Walk ${walkId}`,
    payment_date: new Date().toISOString().slice(0, 10),
    consent_type: 'internet',
    device: { ip_address: '203.0.113.10' },
    external_id: `walk-${walkId}-${Date.now()}`,
    config: { balance_check: 'enabled' },
  });
  return waitUntilSettled(charge.data.id, walkerAccountId);
}

async function waitUntilSettled(chargeId: string, walkerAccountId: string) {
  for (;;) {
    const current = await straddle.charges.retrieve(chargeId, { 'Straddle-Account-Id': walkerAccountId });
    if (current.data.status === 'paid' || current.data.status === 'failed') return current.data;
    await new Promise((resolve) => setTimeout(resolve, 5000));
  }
}

export async function chargeWalkWithRetry(...args: Parameters<typeof chargeWalk>) {
  for (let attempt = 0; ; attempt++) {
    try {
      return await chargeWalk(...args);
    } catch (err) {
      if (attempt >= 5) throw err;
    }
  }
}
