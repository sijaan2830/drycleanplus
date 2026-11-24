// Run: npm test — checks every status produces a sensible message.
const assert = require('node:assert');
const { orderMessage, orderPlacedMessage, jobMessage } = require('../notifications');

const order = {
  orderId: 'DC26000051',
  bagCount: 2,
  bookingData: { firstName: 'Amelia', collectionDate: 'Mon, 16 Nov', collectionTime: '18:00 - 21:00', deliveryDate: 'Wed, 18 Nov', deliveryTime: '18:00 - 21:00' },
  pickupDriver: { name: 'Sam Patel' },
  deliveryDriver: { name: 'Ola Ade' },
  approval: { amount: 24.15 },
};

const pushed = ['confirmed', 'pickup_assigned', 'pickup_en_route', 'pickup_arrived', 'pickup_failed', 'collected', 'at_facility', 'awaiting_approval', 'cleaning',
  'ready_for_delivery', 'delivery_assigned', 'out_for_delivery', 'delivery_arrived', 'delivery_failed', 'delivered', 'cancelled', 'completed', 'processing'];
for (const s of pushed) {
  const m = orderMessage(s, order);
  assert.ok(m && m.title && m.body, `no message for ${s}`);
  assert.ok(!/undefined|null|NaN/.test(m.title + m.body), `bad text for ${s}: ${m.title} / ${m.body}`);
  console.log(`${s.padEnd(20)} ${m.title} — ${m.body}`);
}
for (const s of ['pending', 'inspecting', 'quality_check', '']) assert.strictEqual(orderMessage(s, order), null, `${s} should be silent`);
assert.match(orderMessage('pickup_en_route', order).title, /^Sam is on the way/);
assert.match(orderMessage('awaiting_approval', order).body, /£24\.15/);
assert.match(orderMessage('pickup_en_route', {}).title, /^Your driver/);
assert.match(orderPlacedMessage(order).body, /Amelia/);
assert.strictEqual(jobMessage({ type: 'pickup', slot: '18:00–19:00', customerName: 'Amelia Hart', address: { postalCode: 'E14 9SH' } }).title, 'New pickup · 18:00–19:00');
console.log('\nall template checks passed');
