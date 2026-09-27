import express from 'express';

const app = express();
app.use(express.json());

app.post('/bookings', (req, res) => {
  // TODO: collect payment from the owner and pay the walker after the walk.
  res.status(201).json({ id: 'bk_1', walkerId: req.body.walkerId });
});

app.listen(3000);
