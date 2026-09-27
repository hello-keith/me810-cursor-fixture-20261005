const seen = new Set<string>();

export async function enqueueEvent(webhookId: string, event: unknown): Promise<void> {
  // ponytail: in-memory dedupe for the fixture; a real app persists this.
  if (seen.has(webhookId)) return;
  seen.add(webhookId);
  console.log('queued', webhookId);
}
