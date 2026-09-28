import { Moov } from '@moovio/sdk';

const moov = new Moov({ security: { username: process.env.MOOV_PUBLIC_KEY!, password: process.env.MOOV_SECRET_KEY! } });
const PARTNER_ACCOUNT_ID = process.env.MOOV_ACCOUNT_ID!;

// Collects a studio member's class pack payment into the studio's Moov wallet.
export async function collectClassPack(bookingId: string, payerDebitMethodId: string, studioWalletMethodId: string, cents: number) {
  try {
    const res = await moov.transfers.create({
      xIdempotencyKey: `booking-${bookingId}`,
      accountID: PARTNER_ACCOUNT_ID,
      createTransfer: {
        source: { paymentMethodID: payerDebitMethodId, achDetails: { secCode: 'WEB' } },
        destination: { paymentMethodID: studioWalletMethodId },
        amount: { currency: 'USD', value: cents },
        description: `Class pack ${bookingId}`,
      },
    });
    return waitForOutcome(res.result.transferID);
  } catch (err: any) {
    // A duplicate idempotency key means we already created it.
    if (err?.statusCode === 409) return { status: 'completed' };
    throw err;
  }
}

async function waitForOutcome(transferID: string) {
  for (let i = 0; i < 60; i++) {
    const t = await moov.transfers.get({ accountID: PARTNER_ACCOUNT_ID, transferID });
    if (['completed', 'failed', 'reversed', 'canceled'].includes(t.result.status)) return t.result;
    await new Promise((r) => setTimeout(r, 10_000));
  }
  return { status: 'pending' };
}
