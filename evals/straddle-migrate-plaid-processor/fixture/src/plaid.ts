import { Configuration, PlaidApi, PlaidEnvironments } from 'plaid';
import { saveItem } from './db';

const plaid = new PlaidApi(new Configuration({
  basePath: PlaidEnvironments[process.env.PLAID_ENV ?? 'sandbox'],
  baseOptions: { headers: { 'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID, 'PLAID-SECRET': process.env.PLAID_SECRET } },
}));

export async function createLinkToken(userId: string) {
  const res = await plaid.linkTokenCreate({
    user: { client_user_id: userId },
    client_name: 'RentPal',
    products: ['auth'],
    country_codes: ['US'],
    language: 'en',
  });
  return res.data.link_token;
}

// Exchanges the Link public token and hands Dwolla a processor token for the selected account.
export async function onLinkSuccess(userId: string, publicToken: string, accountId: string) {
  const exchange = await plaid.itemPublicTokenExchange({ public_token: publicToken });
  await saveItem(userId, exchange.data.item_id, exchange.data.access_token, accountId);
  const processor = await plaid.processorTokenCreate({
    access_token: exchange.data.access_token,
    account_id: accountId,
    processor: 'dwolla',
  });
  return processor.data.processor_token;
}
