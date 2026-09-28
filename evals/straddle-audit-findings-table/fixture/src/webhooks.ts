import express from 'express';
import { straddle } from './straddle';
import { markWalkPaid } from './walks';

export const webhooks = express.Router();
webhooks.use(express.json());

webhooks.post('/straddle/webhooks', async (req, res) => {
  const event = straddle.webhooks.unwrap(JSON.stringify(req.body), {
    key: process.env.STRADDLE_WEBHOOK_SECRET,
  } as any);
  res.sendStatus(200);
  if (event.event_type === 'charge.event.v1') {
    await markWalkPaid((event.data as any).external_id);
  }
});
