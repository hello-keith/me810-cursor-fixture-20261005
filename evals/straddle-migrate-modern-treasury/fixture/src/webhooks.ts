import express from 'express';
import crypto from 'node:crypto';
import { markRun } from './runs';

export const mtWebhooks = express.Router();

mtWebhooks.post('/webhooks/modern-treasury', express.raw({ type: 'application/json' }), async (req, res) => {
  const expected = crypto.createHmac('sha256', process.env.MODERN_TREASURY_WEBHOOK_KEY!).update(req.body).digest('hex');
  if (expected !== req.header('X-Signature')) return res.sendStatus(400);
  const { event, data } = JSON.parse(req.body.toString('utf8'));
  // NOCs are applied to the external account by Modern Treasury, so nothing to do here.
  if (req.header('X-Topic') === 'payment_order') await markRun(data.external_id, event);
  res.sendStatus(200);
});
