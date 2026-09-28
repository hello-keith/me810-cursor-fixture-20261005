import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function collectTuition(customerId: string, paymentMethodId: string, amountCents: number, invoiceId: string) {
  return stripe.paymentIntents.create(
    {
      amount: amountCents,
      currency: 'usd',
      customer: customerId,
      payment_method: paymentMethodId,
      payment_method_types: ['us_bank_account'],
      confirm: true,
      mandate_data: { customer_acceptance: { type: 'online', online: { ip_address: '203.0.113.5', user_agent: 'tutorly' } } },
      metadata: { invoiceId },
    },
    { idempotencyKey: `tuition-${invoiceId}` },
  );
}

export async function linkBankAccount(customerId: string) {
  return stripe.setupIntents.create({
    customer: customerId,
    payment_method_types: ['us_bank_account'],
    payment_method_options: { us_bank_account: { financial_connections: { permissions: ['payment_method'] } } },
  });
}
