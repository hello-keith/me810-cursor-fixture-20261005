import express from 'express';
import { straddle } from './straddle';
import { enqueueEvent } from './walks';

export const webhooks = express.Router();

webhooks.post('/straddle/webhooks', express.raw({ type: 'application/json' }), async (req, res) => {
  const key = process.env.STRADDLE_WEBHOOK_SECRET;
  if (!key) return res.status(500).send('STRADDLE_WEBHOOK_SECRET is not configured');
  let event;
  try {
    event = straddle.webhooks.unwrap(req.body.toString('utf8'), {
      headers: {
        'webhook-id': req.header('webhook-id') ?? '',
        'webhook-timestamp': req.header('webhook-timestamp') ?? '',
        'webhook-signature': req.header('webhook-signature') ?? '',
      },
      key,
    });
  } catch {
    return res.sendStatus(400);
  }
  try {
    await enqueueEvent(req.header('webhook-id')!, event);
  } catch {
    return res.sendStatus(500);
  }
  return res.sendStatus(204);
});
