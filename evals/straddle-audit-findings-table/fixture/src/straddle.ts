import StraddleAPI from '@straddlecom/straddle';

export const straddle = new StraddleAPI({
  bearer: process.env.STRADDLE_API_KEY,
});
