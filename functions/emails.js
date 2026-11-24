const { Resend } = require('resend');

// Initialize Resend with API key from environment variable
const getResendClient = () => {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    console.warn('[emails] WARNING: RESEND_API_KEY environment variable is not set!');
  }
  return new Resend(apiKey || 're_placeholder');
};

// Default sender address
// When domain is verified in Resend, use 'DryClean Plus <orders@drycleanplus.co.uk>'
// For onboarding/testing, fallback to 'DryClean Plus <onboarding@resend.dev>'
const FROM_EMAIL = process.env.RESEND_FROM_EMAIL || 'DryClean Plus <orders@drycleanplus.co.uk>';
const SUPPORT_PHONE = '+44 7424 866802';
const SUPPORT_EMAIL = 'support@drycleanplus.co.uk';
const SITE_URL = 'https://drycleanplus.co.uk';

// Helper formatters
const money = (n) => `£${Number(n || 0).toFixed(2)}`;
const first = (name) => String(name || '').trim().split(/\s+/)[0] || 'there';

/**
 * Common luxury email wrapper with DryClean Plus styling
 */
function emailLayout({ title, previewText, content, callToAction }) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    body { margin: 0; padding: 0; background-color: #F8FAFC; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1E293B; }
    .email-wrapper { width: 100%; background-color: #F8FAFC; padding: 24px 0 40px; }
    .email-container { max-width: 600px; margin: 0 auto; background: #FFFFFF; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px rgba(15, 23, 42, 0.06); border: 1px solid #E2E8F0; }
    .header-banner { background: linear-gradient(135deg, #091E5B 0%, #13368E 60%, #1B4ABF 100%); padding: 32px 32px 28px; text-align: left; }
    .brand-logo { font-size: 24px; font-weight: 900; color: #FFFFFF; text-decoration: none; letter-spacing: -0.5px; }
    .brand-gold { color: #FFD25E; }
    .header-badge { display: inline-block; background: rgba(255, 210, 94, 0.2); border: 1px solid rgba(255, 210, 94, 0.4); color: #FFD25E; font-size: 11px; font-weight: 800; letter-spacing: 0.8px; padding: 3px 10px; border-radius: 999px; margin-top: 10px; text-transform: uppercase; }
    .header-title { font-size: 22px; font-weight: 800; color: #FFFFFF; margin: 12px 0 4px; line-height: 1.25; }
    .header-sub { font-size: 14px; color: #CBD5E1; margin: 0; }
    .email-body { padding: 32px; }
    .card-box { background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 14px; padding: 18px 20px; margin-bottom: 24px; }
    .card-title { font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.6px; color: #64748B; margin-bottom: 8px; }
    .data-row { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 8px; font-size: 14px; }
    .data-row:last-child { margin-bottom: 0; }
    .data-label { color: #64748B; }
    .data-value { font-weight: 700; color: #0F172A; text-align: right; }
    .items-table { width: 100%; border-collapse: collapse; margin-top: 12px; }
    .items-table th { text-align: left; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #64748B; padding: 8px 10px; border-bottom: 2px solid #E2E8F0; }
    .items-table td { padding: 10px 10px; border-bottom: 1px solid #F1F5F9; font-size: 13.5px; }
    .total-row { display: flex; justify-content: space-between; font-size: 17px; font-weight: 900; color: #091E5B; padding-top: 14px; margin-top: 14px; border-top: 2px solid #CBD5E1; }
    .btn-action { display: block; background: linear-gradient(135deg, #1E5FD8 0%, #1346BA 100%); color: #FFFFFF !important; text-align: center; font-size: 15px; font-weight: 800; text-decoration: none; padding: 14px 24px; border-radius: 12px; margin: 24px 0 12px; box-shadow: 0 4px 14px rgba(30, 95, 216, 0.35); }
    .btn-gold { background: linear-gradient(135deg, #FFB800 0%, #E69D00 100%); color: #07194A !important; box-shadow: 0 4px 14px rgba(255, 184, 0, 0.35); }
    .footer-section { padding: 24px 32px; background: #0F172A; color: #94A3B8; font-size: 12px; text-align: center; border-top: 1px solid #1E293B; }
    .footer-links a { color: #CBD5E1; text-decoration: none; margin: 0 8px; font-weight: 600; }
  </style>
</head>
<body>
  <div style="display:none;font-size:1px;color:#F8FAFC;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
    ${previewText || title}
  </div>
  <div class="email-wrapper">
    <div class="email-container">
      <div class="header-banner">
        <a href="${SITE_URL}" class="brand-logo">Dryclean<span class="brand-gold">Plus+</span></a>
        <div class="header-badge">Eco Friendly · Doorstep Care</div>
        <h1 class="header-title">${title}</h1>
        <p class="header-sub">${previewText}</p>
      </div>
      <div class="email-body">
        ${content}
        ${callToAction ? callToAction : ''}
      </div>
      <div class="footer-section">
        <p style="margin: 0 0 10px;">Questions about your order? Reach our London concierge at <b>${SUPPORT_PHONE}</b> or email <a href="mailto:${SUPPORT_EMAIL}" style="color: #FFD25E; text-decoration: none;">${SUPPORT_EMAIL}</a>.</p>
        <p style="margin: 0 0 14px;">DryClean Plus Ltd · London, United Kingdom</p>
        <div class="footer-links">
          <a href="${SITE_URL}/track">Track Order</a> ·
          <a href="${SITE_URL}/vip">VIP Club</a> ·
          <a href="${SITE_URL}/prices">Prices & Services</a>
        </div>
      </div>
    </div>
  </div>
</body>
</html>`;
}

/**
 * 1. Booking Confirmation Email
 */
function buildOrderConfirmationEmail(order = {}, orderIdDisplay = '') {
  const b = order.bookingData || {};
  const id = orderIdDisplay || order.orderId || 'your order';
  const name = first(b.firstName);
  const trackUrl = `${SITE_URL}/track/${encodeURIComponent(id)}`;

  const content = `
    <p style="font-size: 15px; line-height: 1.5; color: #334155;">Hello <b>${name}</b>,</p>
    <p style="font-size: 15px; line-height: 1.5; color: #334155;">
      Thank you for booking with <b>DrycleanPlus+</b>. We have received your booking and scheduled our electric collection van for your chosen slot.
    </p>

    <div class="card-box">
      <div class="card-title">Collection & Delivery Schedule</div>
      <div class="data-row">
        <span class="data-label">Order Number:</span>
        <span class="data-value">#${id}</span>
      </div>
      <div class="data-row">
        <span class="data-label">Collection Slot:</span>
        <span class="data-value" style="color: #1E5FD8;">${b.collectionDate || 'Pending'} (${b.collectionTime || 'TBD'})</span>
      </div>
      <div class="data-row">
        <span class="data-label">Delivery Slot:</span>
        <span class="data-value">${b.deliveryDate || '24-48 Hours'} (${b.deliveryTime || 'TBD'})</span>
      </div>
      <div class="data-row">
        <span class="data-label">Address:</span>
        <span class="data-value">${b.selectedAddress?.line1 || ''}, ${b.selectedAddress?.postalCode || ''}</span>
      </div>
    </div>

    <div style="background: #F0FDF4; border: 1px solid #BBF7D0; border-radius: 12px; padding: 14px 18px; margin-bottom: 20px;">
      <b style="color: #166534; font-size: 13.5px; display: block; margin-bottom: 4px;">🌿 How collection works:</b>
      <span style="font-size: 13px; color: #15803D; line-height: 1.4;">
        Simply hand over your garments in any disposable bag at your door. Our driver will tag and weigh them, and you will receive a live status update immediately.
      </span>
    </div>
  `;

  const callToAction = `
    <a href="${trackUrl}" class="btn-action">Follow Order Live</a>
  `;

  return emailLayout({
    title: `Booking Confirmed #${id}`,
    previewText: `Collection booked for ${b.collectionDate || 'your slot'}. Track your driver live.`,
    content,
    callToAction,
  });
}

/**
 * 2. Bill Update & Approval Email (Awaiting Approval)
 */
function buildBillApprovalEmail(order = {}, orderIdDisplay = '') {
  const b = order.bookingData || {};
  const id = orderIdDisplay || order.orderId || 'your order';
  const name = first(b.firstName);
  const trackUrl = `${SITE_URL}/track/${encodeURIComponent(id)}`;

  // Parse items list
  const rawItems = order.countedItems || order.items || order.lines || b.selectedItems || {};
  let itemsList = [];
  if (Array.isArray(rawItems)) {
    itemsList = rawItems.map(it => ({
      name: it.itemType || it.name || 'Garment',
      qty: Number(it.quantity || it.qty || 1),
      price: Number(it.unitPrice || it.price || 0)
    }));
  } else if (typeof rawItems === 'object') {
    itemsList = Object.values(rawItems).map(it => ({
      name: it.itemType || it.name || 'Garment',
      qty: Number(it.quantity || it.qty || 1),
      price: Number(it.numericPrice || it.price || 0)
    }));
  }

  const subtotal = Number(order.subtotal || order.pricing?.subtotal || b.totalPrice || 0);
  const discount = Number(order.discountAmount || b.discountAmount || 0);
  const serviceFee = Number(order.serviceFee ?? 2.99);
  const finalTotal = Number(order.transactionAmount || order.totalAmount || (subtotal - discount + serviceFee));

  let itemsHtml = '';
  itemsList.forEach(it => {
    const rowTotal = it.qty * (it.price || 0);
    itemsHtml += `
      <tr>
        <td style="font-weight: 600; color: #0F172A;">${it.name}</td>
        <td style="text-align: center; color: #64748B;">×${it.qty}</td>
        <td style="text-align: right; font-weight: 700; color: #0F172A;">${money(rowTotal)}</td>
      </tr>
    `;
  });

  const content = `
    <p style="font-size: 15px; line-height: 1.5; color: #334155;">Hello <b>${name}</b>,</p>
    <p style="font-size: 15px; line-height: 1.5; color: #334155;">
      Your garments for order <b>#${id}</b> have arrived at our London facility and been inspected and counted by our master cleaners.
    </p>

    <div style="background: #FEF3C7; border: 1px solid #FDE68A; border-radius: 12px; padding: 14px 18px; margin-bottom: 20px;">
      <b style="color: #92400E; font-size: 14px; display: block; margin-bottom: 4px;">⚠️ Action Required:</b>
      <span style="font-size: 13px; color: #B45309; line-height: 1.4;">
        Please review and approve the updated garment count and total below so our team can immediately begin the eco-cleaning process.
      </span>
    </div>

    <div class="card-box">
      <div class="card-title">Inspected Items Breakdown</div>
      <table class="items-table">
        <thead>
          <tr>
            <th>Item</th>
            <th style="text-align: center;">Qty</th>
            <th style="text-align: right;">Amount</th>
          </tr>
        </thead>
        <tbody>
          ${itemsHtml || '<tr><td colspan="3" style="text-align:center;color:#64748B;">Item inspection complete</td></tr>'}
        </tbody>
      </table>

      <div style="margin-top: 16px; border-top: 1px dashed #CBD5E1; padding-top: 12px;">
        <div class="data-row">
          <span class="data-label">Garments Subtotal:</span>
          <span class="data-value">${money(subtotal)}</span>
        </div>
        ${discount > 0 ? `
          <div class="data-row">
            <span class="data-label" style="color: #059669;">VIP / Promo Discount:</span>
            <span class="data-value" style="color: #059669;">-${money(discount)}</span>
          </div>
        ` : ''}
        <div class="data-row">
          <span class="data-label">Collection & Delivery Service Fee:</span>
          <span class="data-value">${serviceFee === 0 ? '<span style="color:#059669;">FREE</span>' : money(serviceFee)}</span>
        </div>
        <div class="total-row">
          <span>New Total Payable:</span>
          <span>${money(finalTotal)}</span>
        </div>
      </div>
    </div>
  `;

  const callToAction = `
    <a href="${trackUrl}" class="btn-action btn-gold">Review & Approve Order Now</a>
    <p style="text-align: center; font-size: 12px; color: #64748B; margin-top: 8px;">
      You can approve with a single tap in the app or on our website.
    </p>
  `;

  return emailLayout({
    title: `Please Approve Order #${id}`,
    previewText: `New total: ${money(finalTotal)}. Review counted items to begin cleaning.`,
    content,
    callToAction,
  });
}

/**
 * 3. Delivered Order & Official Invoice Email
 */
function buildDeliveredInvoiceEmail(order = {}, orderIdDisplay = '') {
  const b = order.bookingData || {};
  const id = orderIdDisplay || order.orderId || 'your order';
  const name = first(b.firstName);
  const trackUrl = `${SITE_URL}/track/${encodeURIComponent(id)}`;

  const finalTotal = Number(order.transactionAmount || order.totalAmount || b.totalPrice || 0);
  const paymentMethod = order.paymentMethod || b.paymentMethod || 'Card on Delivery';

  const content = `
    <p style="font-size: 15px; line-height: 1.5; color: #334155;">Hello <b>${name}</b>,</p>
    <p style="font-size: 15px; line-height: 1.5; color: #334155;">
      Your clean garments for order <b>#${id}</b> have been safely delivered to your doorstep. We hope everything looks and smells pristine!
    </p>

    <div class="card-box" style="border-left: 4px solid #059669;">
      <div class="card-title">Official Tax Receipt / Invoice</div>
      <div class="data-row">
        <span class="data-label">Invoice Number:</span>
        <span class="data-value">INV-${id}</span>
      </div>
      <div class="data-row">
        <span class="data-label">Delivery Date:</span>
        <span class="data-value">${new Date().toLocaleDateString('en-GB')}</span>
      </div>
      <div class="data-row">
        <span class="data-label">Delivered To:</span>
        <span class="data-value">${b.selectedAddress?.line1 || ''}, ${b.selectedAddress?.postalCode || ''}</span>
      </div>
      <div class="data-row">
        <span class="data-label">Payment Method:</span>
        <span class="data-value">${paymentMethod}</span>
      </div>
      <div class="data-row">
        <span class="data-label">Payment Status:</span>
        <span class="data-value" style="color: #059669;">Paid & Completed</span>
      </div>
      <div class="total-row">
        <span>Total Paid:</span>
        <span style="color: #059669;">${money(finalTotal)}</span>
      </div>
    </div>

    <div style="text-align: center; margin: 24px 0 10px;">
      <p style="font-size: 14px; font-weight: 700; color: #0F172A; margin-bottom: 6px;">How was your experience?</p>
      <p style="font-size: 13px; color: #64748B; margin: 0;">If you loved our service, leave us a 5-star Google review!</p>
    </div>
  `;

  const callToAction = `
    <a href="${SITE_URL}/new-order" class="btn-action">Book Next Collection</a>
  `;

  return emailLayout({
    title: `Order Delivered · Receipt #${id}`,
    previewText: `Your order #${id} has been delivered. View your official invoice.`,
    content,
    callToAction,
  });
}

/**
 * Universal dispatcher: sends email via Resend
 */
async function sendOrderEmail({ type, order, orderDocId, recipientEmail }) {
  const targetEmail = recipientEmail || order.bookingData?.email || order.email;
  if (!targetEmail || !targetEmail.includes('@')) {
    console.warn(`[emails] No valid recipient email for order ${orderDocId}`);
    return { success: false, reason: 'no-recipient' };
  }

  const id = order.orderId || orderDocId;
  let subject = '';
  let html = '';

  switch (type) {
    case 'order_confirmed':
      subject = `Booking Confirmed: Order #${id} · DryClean Plus`;
      html = buildOrderConfirmationEmail(order, id);
      break;

    case 'awaiting_approval':
      subject = `Action Required: Please approve order #${id} · DryClean Plus`;
      html = buildBillApprovalEmail(order, id);
      break;

    case 'delivered':
      subject = `Invoice & Receipt: Order #${id} · DryClean Plus`;
      html = buildDeliveredInvoiceEmail(order, id);
      break;

    default:
      console.warn(`[emails] Unknown email type "${type}"`);
      return { success: false, reason: 'unknown-type' };
  }

  try {
    const resend = getResendClient();
    const result = await resend.emails.send({
      from: FROM_EMAIL,
      to: [targetEmail],
      subject,
      html,
    });

    console.log(`[emails] Email "${type}" sent successfully to ${targetEmail} (id: ${result.data?.id})`);
    return { success: true, id: result.data?.id };
  } catch (error) {
    console.error(`[emails] Failed to send "${type}" to ${targetEmail}:`, error.message);
    return { success: false, error: error.message };
  }
}

module.exports = {
  sendOrderEmail,
  buildOrderConfirmationEmail,
  buildBillApprovalEmail,
  buildDeliveredInvoiceEmail,
};
