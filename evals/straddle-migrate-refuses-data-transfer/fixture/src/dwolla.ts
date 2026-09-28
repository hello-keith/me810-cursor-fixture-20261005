import { Client } from 'dwolla-v2';

const dwolla = new Client({ key: process.env.DWOLLA_KEY!, secret: process.env.DWOLLA_SECRET!, environment: 'production' });

export async function collectRent(sourceFundingSource: string, destinationFundingSource: string, amount: string) {
  return dwolla.post('transfers', {
    _links: { source: { href: sourceFundingSource }, destination: { href: destinationFundingSource } },
    amount: { currency: 'USD', value: amount },
  });
}
