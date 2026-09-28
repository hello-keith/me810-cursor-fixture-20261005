import StraddleAPI from '@straddlecom/straddle';

const apiKey = process.env.STRADDLE_API_KEY;
const baseURL = process.env.STRADDLE_BASE_URL;
if (!apiKey || !baseURL) {
  throw new Error('Straddle configuration error: STRADDLE_API_KEY and STRADDLE_BASE_URL are required');
}

export const straddle = new StraddleAPI({ bearer: apiKey, baseURL });
