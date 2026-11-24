// Message templates — what the customer (or driver) is told at each step.
// Pure functions, no Firebase calls, so they can be tested locally.

const LEGACY = { processing: 'cleaning', in_progress: 'cleaning', ready: 'ready_for_delivery', in_transit: 'out_for_delivery', completed: 'delivered' };
const norm = (s) => { const v = String(s || '').toLowerCase(); return LEGACY[v] || v; };

const first = (name) => String(name || '').trim().split(/\s+/)[0] || '';
const money = (n) => `£${Number(n || 0).toFixed(2)}`;
const when = (day, time) => [day, time].filter(Boolean).join(', ');

/**
 * Order status → notification, or null when this step isn't worth a push.
 * category/theme/icon match the customer app's notification screen.
 */
function orderMessage(status, order = {}) {
  const b = order.bookingData || {};
  const id = order.orderId ? `#${order.orderId}` : 'your order';
  const pickupDriver = first(order.pickupDriver?.name) || 'Your driver';
  const deliveryDriver = first(order.deliveryDriver?.name) || 'Your driver';
  const bags = Number(order.bagCount || 0);
  const amount = order.approval?.amount ?? order.pricing?.final;
  const m = (title, body, extra = {}) => ({ title, body, category: 'orders', theme: 'blue', icon: 'local_shipping', ...extra });

  switch (norm(status)) {
    case 'confirmed':
      return m('Booking confirmed', `We'll collect ${id} ${when(b.collectionDate, b.collectionTime) || 'in your slot'}.`, { icon: 'event_available' });
    case 'pickup_assigned':
      return m('Driver assigned', `${pickupDriver} will collect ${id} ${when(b.collectionDate, b.collectionTime) || 'in your slot'}.`, { icon: 'person_pin' });
    case 'pickup_en_route':
      return m(`${pickupDriver} is on the way`, 'Tap to follow your driver live on the map.', { live: true });
    case 'pickup_arrived':
      return m('Your driver is outside', 'Please hand over your bags at the door.', { icon: 'where_to_vote', theme: 'mint' });
    case 'pickup_failed':
      return m('We missed you', `We couldn't collect ${id} today. Tap to reschedule.`, { icon: 'event_busy', theme: 'amber' });
    case 'collected':
      return m('Bags collected', `${bags > 0 ? `${bags} bag${bags === 1 ? '' : 's'}` : 'Your order'} on the way to our facility.`, { icon: 'inventory', theme: 'mint' });
    case 'at_facility':
      return m('Arrived at our facility', `We're checking every item in ${id}.`, { icon: 'warehouse', theme: 'violet' });
    case 'awaiting_approval':
      return m('Please approve your order', `We found changes to ${id}${amount != null ? ` — new total ${money(amount)}` : ''}. Tap to review before we clean.`, { icon: 'pending_actions', theme: 'amber' });
    case 'cleaning':
      return m('Cleaning started', `${id} is being cleaned now.`, { icon: 'laundry', theme: 'violet' });
    case 'ready_for_delivery':
      return m('Ready for delivery', `${id} is cleaned, checked and packed.`, { icon: 'checkroom', theme: 'mint' });
    case 'delivery_assigned':
      return m('Delivery booked', `${deliveryDriver} will deliver ${id} ${when(b.deliveryDate, b.deliveryTime) || 'in your slot'}.`, { icon: 'person_pin' });
    case 'out_for_delivery':
      return m(`${deliveryDriver} is bringing your order`, 'Tap to follow your driver live on the map.', { live: true });
    case 'delivery_arrived':
      return m('Your driver is outside', 'Your clean clothes are at your door.', { icon: 'where_to_vote', theme: 'mint' });
    case 'delivery_failed':
      return m('Delivery missed', `We couldn't deliver ${id} today. Tap to choose a new time.`, { icon: 'event_busy', theme: 'amber' });
    case 'delivered':
      return m('Delivered — thank you!', `${id} has been delivered. We hope you love the results.`, { icon: 'check_circle', theme: 'mint' });
    case 'cancelled':
      return m('Order cancelled', `${id} has been cancelled. Questions? Just call us.`, { icon: 'cancel', theme: 'amber' });
    default:
      return null; // pending, inspecting, quality_check … too small to push
  }
}

/** New order placed in the app. */
function orderPlacedMessage(order = {}) {
  const b = order.bookingData || {};
  return {
    title: 'Order received',
    body: `Thanks${b.firstName ? `, ${first(b.firstName)}` : ''}! We'll collect ${order.orderId ? `#${order.orderId}` : 'your order'} ${when(b.collectionDate, b.collectionTime) || 'in your slot'}.`,
    category: 'orders',
    theme: 'blue',
    icon: 'receipt',
  };
}

/** New job for a driver. */
function jobMessage(job = {}) {
  const pickup = job.type !== 'delivery';
  const postcode = job.address?.postalCode || '';
  return {
    title: `New ${pickup ? 'pickup' : 'delivery'}${job.slot ? ` · ${job.slot}` : ''}`,
    body: [job.customerName, postcode].filter(Boolean).join(' · ') || 'Open the app to see the details.',
  };
}

module.exports = { norm, orderMessage, orderPlacedMessage, jobMessage };
