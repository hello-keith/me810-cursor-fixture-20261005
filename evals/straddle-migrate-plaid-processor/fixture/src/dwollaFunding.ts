import { Client } from 'dwolla-v2';

const dwolla = new Client({ key: process.env.DWOLLA_KEY!, secret: process.env.DWOLLA_SECRET!, environment: 'sandbox' });

export async function addFundingSource(customerUrl: string, plaidProcessorToken: string) {
  const res = await dwolla.post(`${customerUrl}/funding-sources`, { plaidToken: plaidProcessorToken, name: 'Rent account' });
  return res.headers.get('location');
}
