const PDFDocument = require('pdfkit');

const money = (n) => `£${Number(n || 0).toFixed(2)}`;

function generateInvoicePdfBuffer(order = {}, idDisplay = '') {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ size: 'A4', margin: 48 });
      const chunks = [];
      doc.on('data', (chunk) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      const b = order.bookingData || {};
      const id = idDisplay || order.orderId || order.id || '0000';
      const customerName = [b.firstName, b.lastName].filter(Boolean).join(' ').trim() || order.customerName || 'Valued Customer';
      const phone = b.phone || order.phone || 'N/A';
      const email = b.email || order.email || 'N/A';
      const addr = b.selectedAddress || b.deliveryAddress || order.address || {};
      const addressStr = typeof addr === 'string'
        ? addr
        : [addr.line1, addr.line2, addr.city, addr.postalCode].filter(Boolean).join(', ') || 'On file';

      const colDate = [b.collectionDate, b.collectionTime].filter(Boolean).join(' ') || 'Scheduled';
      const delDate = [b.deliveryDate, b.deliveryTime].filter(Boolean).join(' ') || new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
      const statusLabel = String(order.status || 'Delivered').replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
      const paymentMethod = order.paymentMethod || b.paymentMethod || 'Card on Delivery';
      const dateStr = new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });

      // Top Navy Brand Bar
      doc.rect(0, 0, doc.page.width, 6).fill('#0B2A6B');

      // Signature Brand Wordmark (No icon box)
      doc.font('Times-BoldItalic').fontSize(26).fillColor('#1B5E20').text('Dryclean ', 48, 48, { continued: true });
      doc.font('Times-BoldItalic').fontSize(26).fillColor('#EF4444').text('Plus+');
      doc.font('Helvetica').fontSize(9.5).fillColor('#6B7280')
        .text('DryClean Plus Ltd', 48, 82)
        .text('2c Bar Gate, Newark NG24 1ES, United Kingdom', 48, 95)
        .text('dilee@drycleanplus.co.uk · www.drycleanplus.co.uk', 48, 108);

      // Right Invoice Header
      doc.font('Times-Roman').fontSize(28).fillColor('#111827').text('Invoice', 340, 46, { width: 207, align: 'right' });
      doc.font('Helvetica').fontSize(10).fillColor('#6B7280').text('Invoice number', 340, 82, { width: 110, align: 'right' });
      doc.font('Helvetica-Bold').fontSize(10).fillColor('#111827').text(`INV-${id}`, 455, 82, { width: 92, align: 'right' });
      doc.font('Helvetica').fontSize(10).fillColor('#6B7280').text('Date', 340, 98, { width: 110, align: 'right' });
      doc.font('Helvetica-Bold').fontSize(10).fillColor('#111827').text(dateStr, 455, 98, { width: 92, align: 'right' });
      doc.font('Helvetica').fontSize(10).fillColor('#6B7280').text('Status', 340, 114, { width: 110, align: 'right' });
      doc.font('Helvetica-Bold').fontSize(10).fillColor('#111827').text(statusLabel, 455, 114, { width: 92, align: 'right' });

      // Horizontal rule
      doc.moveTo(48, 142).lineTo(547, 142).strokeColor('#E3E6EB').lineWidth(1).stroke();

      // Customer & Schedule columns
      doc.font('Helvetica').fontSize(9).fillColor('#6B7280').text('Billed to', 48, 156);
      doc.font('Helvetica-Bold').fontSize(11).fillColor('#111827').text(customerName, 48, 171);
      doc.font('Helvetica').fontSize(10).fillColor('#374151')
        .text(phone, 48, 187)
        .text(email, 48, 201)
        .text(addressStr, 48, 215, { width: 245 });

      doc.moveTo(310, 152).lineTo(310, 246).strokeColor('#E3E6EB').lineWidth(1).stroke();

      doc.font('Helvetica').fontSize(9).fillColor('#6B7280').text('Collection', 328, 156);
      doc.font('Helvetica').fontSize(10).fillColor('#111827').text(colDate, 328, 171, { width: 215 });
      doc.font('Helvetica').fontSize(9).fillColor('#6B7280').text('Delivery', 328, 200);
      doc.font('Helvetica').fontSize(10).fillColor('#111827').text(delDate, 328, 215, { width: 215 });

      doc.moveTo(48, 254).lineTo(547, 254).strokeColor('#E3E6EB').lineWidth(1).stroke();

      // Items Table Header
      let y = 274;
      doc.font('Helvetica-Bold').fontSize(9.5).fillColor('#0B2A6B')
        .text('#', 48, y, { width: 24 })
        .text('Item', 74, y, { width: 170 })
        .text('Category', 248, y, { width: 92 })
        .text('Qty', 344, y, { width: 38, align: 'center' })
        .text('Unit price', 386, y, { width: 76, align: 'right' })
        .text('Total', 466, y, { width: 81, align: 'right' });

      y += 18;
      doc.moveTo(48, y).lineTo(547, y).strokeColor('#0B2A6B').lineWidth(1).stroke();
      y += 10;

      // Parse Items
      const rawItems = order.countedItems || order.items || order.lines || b.selectedItems || {};
      let itemsList = [];
      if (Array.isArray(rawItems)) {
        itemsList = rawItems;
      } else if (rawItems && typeof rawItems === 'object') {
        itemsList = Object.values(rawItems);
      }

      let itemsSum = 0;
      if (itemsList.length === 0) {
        const totalAmt = Number(order.transactionAmount ?? order.totalAmount ?? b.totalPrice ?? 0) || 0;
        itemsSum = totalAmt;
        doc.font('Helvetica').fontSize(10).fillColor('#111827')
          .text('1', 48, y, { width: 24 })
          .text('Dry Cleaning & Laundry Service', 74, y, { width: 170 })
          .fillColor('#6B7280').text('Standard Care', 248, y, { width: 92 })
          .fillColor('#111827').text('1', 344, y, { width: 38, align: 'center' })
          .text(money(totalAmt), 386, y, { width: 76, align: 'right' })
          .font('Helvetica-Bold').text(money(totalAmt), 466, y, { width: 81, align: 'right' });
        y += 24;
        doc.moveTo(48, y).lineTo(547, y).strokeColor('#E3E6EB').lineWidth(0.75).stroke();
        y += 10;
      } else {
        itemsList.forEach((it, idx) => {
          const name = it.itemType || it.name || 'Garment';
          const cat = it.category || 'Dry Clean';
          const qty = Number(it.quantity || it.qty || 1);
          const unit = Number(it.unitPrice ?? it.numericPrice ?? String(it.price || 0).replace(/[^0-9.]/g, '')) || 0;
          const rowTotal = Number(it.total ?? it.rowTotal ?? (unit * qty)) || 0;
          itemsSum += rowTotal;

          doc.font('Helvetica').fontSize(10).fillColor('#111827')
            .text(`${idx + 1}`, 48, y, { width: 24 })
            .text(name, 74, y, { width: 170 })
            .fillColor('#6B7280').text(cat, 248, y, { width: 92 })
            .fillColor('#111827').text(`${qty}`, 344, y, { width: 38, align: 'center' })
            .text(money(unit), 386, y, { width: 76, align: 'right' })
            .font('Helvetica-Bold').text(money(rowTotal), 466, y, { width: 81, align: 'right' });

          y += 24;
          doc.moveTo(48, y).lineTo(547, y).strokeColor('#E3E6EB').lineWidth(0.75).stroke();
          y += 10;
        });
      }

      // Totals & Payment
      const subtotalNum = Number(order.subtotal ?? order.pricing?.subtotal ?? b.totalPrice ?? itemsSum) || 0;
      const serviceFeeNum = Number(order.deliveryFee ?? order.serviceFee ?? 0) || 0;
      const discountNum = Number(order.discountAmount ?? b.discountAmount ?? 0) || 0;
      const totalNum = Number(order.transactionAmount ?? order.totalAmount ?? (subtotalNum - discountNum + serviceFeeNum)) || 0;

      y += 12;
      doc.font('Helvetica').fontSize(9).fillColor('#6B7280').text('Payment', 48, y);
      doc.font('Helvetica-Bold').fontSize(10).fillColor('#111827').text(paymentMethod, 48, y + 15);
      doc.font('Helvetica').fontSize(9.5).fillColor('#374151')
        .text('Pay online with SumUp:', 48, y + 36)
        .fillColor('#0B2A6B').text('https://pay.sumup.com/b2c/Q3MO3NEP', 48, y + 50);

      let sy = y;
      doc.font('Helvetica').fontSize(10).fillColor('#6B7280').text('Subtotal', 328, sy, { width: 120 });
      doc.fillColor('#111827').text(money(subtotalNum || totalNum), 450, sy, { width: 97, align: 'right' });
      sy += 18;

      if (discountNum > 0) {
        doc.fillColor('#1A7F5A').text('Discount', 328, sy, { width: 120 });
        doc.text(`-${money(discountNum)}`, 450, sy, { width: 97, align: 'right' });
        sy += 18;
      }

      doc.fillColor('#6B7280').text('Collection and delivery', 328, sy, { width: 120 });
      doc.fillColor('#111827').text(serviceFeeNum === 0 ? 'Free' : money(serviceFeeNum), 450, sy, { width: 97, align: 'right' });
      sy += 22;

      doc.moveTo(328, sy).lineTo(547, sy).strokeColor('#0B2A6B').lineWidth(1.5).stroke();
      sy += 10;

      doc.font('Helvetica-Bold').fontSize(11).fillColor('#111827').text('Total', 328, sy + 5, { width: 90 });
      doc.font('Times-Bold').fontSize(20).fillColor('#0B2A6B').text(money(totalNum), 420, sy, { width: 127, align: 'right' });

      // Bottom Footer
      const fy = doc.page.height - 96;
      doc.moveTo(48, fy).lineTo(547, fy).strokeColor('#E3E6EB').lineWidth(1).stroke();
      doc.font('Helvetica-Bold').fontSize(10).fillColor('#111827').text('Thank you for choosing DryClean Plus.', 48, fy + 14);
      doc.font('Helvetica').fontSize(9).fillColor('#6B7280')
        .text('Questions about this invoice? Email dilee@drycleanplus.co.uk or call +44 7424 866802.', 48, fy + 30)
        .text('DryClean Plus Ltd · 2c Bar Gate, Newark NG24 1ES, United Kingdom', 48, fy + 44);

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}

module.exports = { generateInvoicePdfBuffer };
