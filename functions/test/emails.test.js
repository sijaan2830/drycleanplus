const assert = require('assert');
const {
  buildOrderConfirmationEmail,
  buildBillApprovalEmail,
  buildDeliveredInvoiceEmail,
} = require('../emails');

const sampleOrder = {
  orderId: 'DC26000099',
  bookingData: {
    firstName: 'Sarah',
    email: 'sarah@example.com',
    collectionDate: 'Tomorrow',
    collectionTime: '18:00 - 21:00',
    deliveryDate: 'Thu, 26 Nov',
    deliveryTime: '18:00 - 21:00',
    selectedAddress: {
      line1: '42 Kensington High St',
      postalCode: 'W8 4PF',
    },
    totalPrice: 45.0,
  },
  countedItems: [
    { itemType: 'Suit (2 pc)', quantity: 2, unitPrice: 16.5 },
    { itemType: 'Shirt (Wash & Iron)', quantity: 4, unitPrice: 3.0 },
  ],
  subtotal: 45.0,
  discountAmount: 6.75,
  serviceFee: 0.0,
  transactionAmount: 38.25,
  paymentMethod: 'Card on Delivery',
};

console.log('Testing email template generators...\n');

// 1. Order confirmation
const confHtml = buildOrderConfirmationEmail(sampleOrder, 'DC26000099');
assert(confHtml.includes('Your booking is confirmed'), 'Confirmation title matches');
assert(confHtml.includes('Sarah'), 'Customer name included');
assert(confHtml.includes('W8 4PF'), 'Postcode included');
console.log('✓ Order Confirmation HTML template generated successfully');

// 2. Bill Approval
const approvalHtml = buildBillApprovalEmail(sampleOrder, 'DC26000099');
assert(approvalHtml.includes('Suit (2 pc)'), 'Item name included');
assert(approvalHtml.includes('Shirt (Wash & Iron)'), 'Second item included');
assert(approvalHtml.includes('£38.25'), 'Final total included');
assert(approvalHtml.includes('Review and approve order'), 'Approval CTA included');
console.log('✓ Bill Approval HTML template generated successfully');

// 3. Delivered invoice
const invoiceHtml = buildDeliveredInvoiceEmail(sampleOrder, 'DC26000099');
assert(invoiceHtml.includes('Your order has been delivered'), 'Delivered heading matches');
assert(invoiceHtml.includes('INV-DC26000099'), 'Invoice ID included');
assert(invoiceHtml.includes('£38.25') || invoiceHtml.includes('38.25'), 'Invoice total included');
assert(invoiceHtml.includes('Card on Delivery'), 'Payment method included');
console.log('✓ Delivered Invoice HTML template generated successfully');

console.log('\nAll email tests passed successfully!');
