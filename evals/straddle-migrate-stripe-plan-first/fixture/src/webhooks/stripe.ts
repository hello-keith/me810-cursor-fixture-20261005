import express from 'express';
import Stripe from 'stripe';
import { markInvoicePaid } from '../invoices';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
export const stripeWebhooks = express.Router();

stripeWebhooks.post('/webhooks/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
  const event = stripe.webhooks.constructEvent(req.body, req.header('stripe-signature')!, process.env.STRIPE_WEBHOOK_SECRET!);
  if (event.type === 'payment_intent.succeeded') {
    await markInvoicePaid((event.data.object as Stripe.PaymentIntent).metadata.invoiceId);
  }
  res.sendStatus(204);
});
