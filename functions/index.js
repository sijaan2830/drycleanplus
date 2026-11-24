/**
 * DryClean Plus — server-side notifications & Resend Email engine.
 *
 *   orders/{id} status changes (driver app, intake app, dispatch, admin, customer)
 *        → users/{uid}/notifications/{auto}   (in-app inbox)
 *        → push to users/{uid}.fcmToken        (phone notification)
 *        → Resend automated email              (awaiting_approval, delivered, confirmed)
 *   jobs/{id} created by dispatch
 *        → push to drivers/{uid}.fcmToken      (driver app)
 *   sendBroadcast (called by the admin console)
 *        → push to a topic ("offers", "prepaid_packs")
 *   sendOrderEmailManual (called by admin console)
 *        → on-demand manual invoice/receipt email to customer
 *
 * The Firebase service account and Resend API key live securely only here.
 */
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions, logger } = require('firebase-functions/v2');
const admin = require('firebase-admin');
const { norm, orderMessage, orderPlacedMessage, jobMessage } = require('./notifications');
const { sendOrderEmail } = require('./emails');

admin.initializeApp();
const db = admin.firestore();
const { FieldValue } = admin.firestore;

setGlobalOptions({ region: 'europe-west2', maxInstances: 10 });

const DEAD_TOKEN = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token', 'messaging/invalid-argument']);

/** Push to one device; forget the token if the phone has uninstalled the app. */
async function pushToToken(ref, token, title, body, data) {
  if (!token) return false;
  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v ?? '')])),
      android: { priority: 'high', notification: { channelId: 'high_importance_channel', sound: 'default' } },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    return true;
  } catch (e) {
    if (DEAD_TOKEN.has(e.code)) await ref.update({ fcmToken: FieldValue.delete() }).catch(() => {});
    else logger.warn('push failed', { code: e.code, message: e.message });
    return false;
  }
}

/** Inbox entry + phone push for a customer. Website guests have no account, so they are skipped. */
async function notifyCustomer(uid, msg, orderDocId, order) {
  if (!uid || uid === 'website_guest' || uid === 'dummy') return;
  const userRef = db.collection('users').doc(uid);
  const data = { type: 'order', orderId: orderDocId, displayOrderId: order.orderId || '', status: norm(order.status), live: msg.live ? '1' : '' };
  await userRef.collection('notifications').add({
    title: msg.title,
    body: msg.body,
    category: msg.category,
    theme: msg.theme,
    icon: msg.icon,
    orderId: orderDocId,
    displayOrderId: order.orderId || '',
    status: norm(order.status),
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  const user = await userRef.get();
  const sent = await pushToToken(userRef, user.get('fcmToken'), msg.title, msg.body, data);
  logger.info('customer notified', { uid, order: order.orderId, status: data.status, pushed: sent });
}

/** Log email event to order history timeline */
async function logEmailHistory(orderDocId, type, result, recipientEmail) {
  try {
    await db.collection('orders').doc(orderDocId).collection('history').add({
      status: `email_${type}`,
      title: type === 'awaiting_approval' ? 'Approval bill email sent' : type === 'delivered' ? 'Official invoice email sent' : 'Booking confirmation email sent',
      description: result.success ? `Sent to ${recipientEmail}` : `Failed: ${result.error || result.reason}`,
      success: result.success,
      emailId: result.id || null,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    logger.warn('Failed to log email history', { orderDocId, error: err.message });
  }
}

// ---------------------------------------------------------------- order status changed
exports.onOrderStatusChange = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before?.data() || {};
  const after = event.data?.after?.data() || {};
  const orderDocId = event.params.orderId;

  if (norm(before.status) === norm(after.status)) return; // price edits, GPS fields etc.

  // 1. Mobile app push notification
  const msg = orderMessage(after.status, after);
  if (msg) {
    await notifyCustomer(after.userId, msg, orderDocId, after);
  }

  // 2. Automated Resend Emails on critical milestones
  const normalizedStatus = norm(after.status);
  const recipient = after.bookingData?.email || after.email;

  if (normalizedStatus === 'awaiting_approval') {
    logger.info('Sending item approval email', { orderDocId, orderId: after.orderId, recipient });
    const res = await sendOrderEmail({ type: 'awaiting_approval', order: after, orderDocId, recipientEmail: recipient });
    await logEmailHistory(orderDocId, 'awaiting_approval', res, recipient);
  } else if (normalizedStatus === 'delivered') {
    logger.info('Sending delivered receipt & invoice email', { orderDocId, orderId: after.orderId, recipient });
    const res = await sendOrderEmail({ type: 'delivered', order: after, orderDocId, recipientEmail: recipient });
    await logEmailHistory(orderDocId, 'delivered', res, recipient);
  }
});

// ---------------------------------------------------------------- new order created
exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data?.data() || {};
  const orderDocId = event.params.orderId;
  if (orderDocId === '--indexes--' || !order.orderId) return;

  // 1. Push notification to mobile customer
  await notifyCustomer(order.userId, orderPlacedMessage(order), orderDocId, order);

  // 2. Automated booking confirmation email (sent to app users AND website guests!)
  const recipient = order.bookingData?.email || order.email;
  if (recipient) {
    logger.info('Sending booking confirmation email', { orderDocId, orderId: order.orderId, recipient });
    const res = await sendOrderEmail({ type: 'order_confirmed', order, orderDocId, recipientEmail: recipient });
    await logEmailHistory(orderDocId, 'order_confirmed', res, recipient);
  }
});

// ---------------------------------------------------------------- new driver job
exports.onJobCreated = onDocumentCreated('jobs/{jobId}', async (event) => {
  const job = event.data?.data() || {};
  if (!job.driverId) return;
  const ref = db.collection('drivers').doc(job.driverId);
  const driver = await ref.get();
  const { title, body } = jobMessage(job);
  const sent = await pushToToken(ref, driver.get('fcmToken'), title, body, { type: 'job', jobId: event.params.jobId, orderId: job.orderId || '' });
  logger.info('driver notified', { driver: job.driverId, job: event.params.jobId, pushed: sent });
});

// ---------------------------------------------------------------- admin broadcast
const TOPICS = new Set(['offers', 'prepaid_packs']);

async function isAdmin(auth) {
  if (!auth) return false;
  const email = auth.token?.email || '';
  const checks = await Promise.all([
    email ? db.collection('admin_users').doc(email).get() : null,
    db.collection('admin_users').doc(auth.uid).get(),
    db.collection('staff').doc(auth.uid).get(),
  ]);
  return Boolean(checks[0]?.exists || checks[1].exists || checks[2].get('role') === 'admin');
}

exports.sendBroadcast = onCall(async (request) => {
  if (!(await isAdmin(request.auth))) throw new HttpsError('permission-denied', 'Only DryClean Plus admins can send notifications.');
  const { title, body, topic, data = {} } = request.data || {};
  if (!title || !body) throw new HttpsError('invalid-argument', 'A title and message are required.');
  if (!TOPICS.has(topic)) throw new HttpsError('invalid-argument', `Unknown audience "${topic}".`);
  const id = await admin.messaging().send({
    topic,
    notification: { title: String(title).slice(0, 120), body: String(body).slice(0, 400) },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v ?? '')])),
    android: { priority: 'high', notification: { channelId: 'high_importance_channel' } },
  });
  await db.collection('broadcasts').add({ title, body, topic, messageId: id, by: request.auth.token?.email || request.auth.uid, at: FieldValue.serverTimestamp() });
  return { success: true, messageId: id };
});

// ---------------------------------------------------------------- admin manual email trigger
exports.sendOrderEmailManual = onCall(async (request) => {
  if (!(await isAdmin(request.auth))) throw new HttpsError('permission-denied', 'Only DryClean Plus staff can manually send invoice emails.');
  const { orderDocId, type } = request.data || {};
  if (!orderDocId || !type) throw new HttpsError('invalid-argument', 'orderDocId and type are required.');

  const snap = await db.collection('orders').doc(orderDocId).get();
  if (!snap.exists) throw new HttpsError('not-found', 'Order document does not exist.');

  const order = snap.data();
  const recipient = order.bookingData?.email || order.email;
  const res = await sendOrderEmail({ type, order, orderDocId, recipientEmail: recipient });
  await logEmailHistory(orderDocId, `manual_${type}`, res, recipient);

  return res;
});
