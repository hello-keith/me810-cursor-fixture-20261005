export function bookingStateFor(moovStatus: string): 'paid' | 'unpaid' | 'refund_due' {
  if (moovStatus === 'completed') return 'paid';
  if (moovStatus === 'reversed') return 'refund_due';
  return 'unpaid';
}
