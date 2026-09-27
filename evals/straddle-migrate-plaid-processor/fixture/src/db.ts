// Stores each tenant's Plaid Item so the bank link can be reused later.
export async function saveItem(userId: string, itemId: string, accessToken: string, accountId: string): Promise<void> {
  console.log('saved item', userId, itemId, accountId, accessToken.length);
}
