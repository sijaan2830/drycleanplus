import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/booking_ui.dart';
import '../../widgets/service_price_card.dart';
import '../membership_screen.dart';
import 'address_selection_screen.dart';
import 'booking_confirmation_screen.dart';
import 'contact_info_screen.dart';
import 'payment_screen.dart';
import 'time_slots_screen.dart';

/// Step 3 — review and confirm. One page, every part editable in place.
class ReviewOrderScreen extends StatefulWidget {
  const ReviewOrderScreen({super.key});
  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  bool _payNow = false, _placing = false;
  static const _tips = [0.0, 2.0, 3.0, 5.0];

  @override
  void initState() {
    super.initState();
    // Fill address/contact from the profile if this booking doesn't have them yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BookingProvider>();
      final d = bp.bookingData;
      if (d.selectedAddress == null && bp.userDefaultAddress != null && bp.userDefaultAddress!.line1.isNotEmpty) {
        bp.updateBookingData(d.copyWith(selectedAddress: bp.userDefaultAddress));
      }
      final d2 = bp.bookingData;
      if (d2.firstName.isEmpty && bp.userFirstName.isNotEmpty) {
        bp.updateBookingData(d2.copyWith(firstName: bp.userFirstName, lastName: bp.userLastName, phone: bp.userPhone, email: bp.userEmail));
      }
    });
  }

  Future<void> _open(Widget screen, String name) => Navigator.of(context).push(smoothRoute(screen, name: name));

  String? _problem(BookingData d) {
    if (d.selectedServices.isEmpty && d.selectedItems.isEmpty) return 'Please choose at least one service';
    if (d.selectedAddress == null) return 'Please add your collection address';
    if ((d.collectionTime ?? '').isEmpty || (d.deliveryTime ?? '').isEmpty) return 'Please choose your collection and delivery times';
    if (d.firstName.trim().isEmpty || d.phone.trim().isEmpty) return 'Please add your name and phone number';
    return null;
  }

  Future<void> _confirm(BookingProvider bp) async {
    final d = bp.bookingData;
    final problem = _problem(d);
    if (problem != null) return showAppSnack(context, problem, error: true);
    // per-service requests travel with the order to the driver and facility
    final req = d.serviceRequests.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
    if (req.isNotEmpty && !d.specialInstructions.contains(req)) {
      bp.updateBookingData(d.copyWith(specialInstructions: [d.specialInstructions, req].where((e) => e.trim().isNotEmpty).join(' · '), acceptedTerms: true));
    } else {
      bp.updateBookingData(d.copyWith(acceptedTerms: true));
    }
    if (_payNow) {
      _open(PaymentScreen(amount: bp.bookingData.totalAmount), '/payment');
      return;
    }
    setState(() => _placing = true);
    try {
      await bp.createOrder(paymentMethod: 'cod', paymentStatus: 'pay_on_delivery');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(smoothRoute(const BookingConfirmationScreen(), name: '/booking_confirmation'), (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      showAppSnack(context, 'Could not place your order. Please try again.', error: true);
    }
  }

  Future<void> _promo(BookingProvider bp) async {
    final c = TextEditingController();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const UiIcon('promo', size: 30), const SizedBox(width: 10), Text('Promo code', style: BK.h(20))]),
          const SizedBox(height: 14),
          TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: 'e.g. WELCOME10', filled: true, fillColor: BK.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            style: BK.t(16, w: FontWeight.w800),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              style: FilledButton.styleFrom(backgroundColor: BK.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('APPLY', style: BK.t(15, c: Colors.white, w: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;
    final res = await bp.applyCoupon(code);
    if (mounted) showAppSnack(context, '${res['message'] ?? (res['success'] == true ? 'Code applied' : 'Code not valid')}', error: res['success'] != true);
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookingProvider>();
    final d = bp.bookingData;
    final estimate = d.selectedServices.isNotEmpty;
    final money = (double v) => '£${v.toStringAsFixed(2)}';
    return Scaffold(
      backgroundColor: const Color(0xFF1245B5),
      extendBody: true, // the page continues behind the floating button
      appBar: const BookingTopBar(title: 'Order summary', step: 3, onBlue: true),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView(padding: const EdgeInsets.only(bottom: 110), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Review and confirm', style: BK.h(26, c: Colors.white)),
            const SizedBox(height: 6),
            Text(
              estimate ? 'Nothing to pay now. We count and check your items at our facility, and you approve any change before we clean.' : 'Nothing to pay now — you pay when your clean clothes are back.',
              style: BK.t(14, c: Colors.white.withValues(alpha: .85), w: FontWeight.w500, height: 1.45),
            ),
          ]),
        ),

        // ------------------------------------------------ price estimate
        _Section(
          title: estimate ? 'Price estimate' : 'Order Price',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.selectedServices.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < d.selectedServices.length; i++) ...[
                        if (i > 0) const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  ServicePriceConfig.forTitle(d.selectedServices[i]).assetImage,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const UiIcon('bag', size: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                d.selectedServices[i],
                                style: BK.t(15, w: FontWeight.w700, c: const Color(0xFF0F172A)),
                              ),
                            ),
                            const _Chip('COUNTED AT FACILITY', green: true),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (d.selectedItems.isNotEmpty)
                _Row(d.prepaidPackName ?? 'Prepaid pack', value: money(d.subtotal)),
              if (d.discountAmount > 0)
                _Row('Discount${d.discountCode == null ? '' : ' (${d.discountCode})'}',
                    value: '−${money(d.discountAmount)}', valueColor: const Color(0xFF16A34A)),
              if (BookingData.serviceFeeEnabled && BookingData.serviceFee > 0)
                _Row('Service fee', value: money(BookingData.serviceFee)),
              if (BookingData.deliveryFeeEnabled && BookingData.deliveryFee > 0)
                _Row('Delivery fee', value: money(BookingData.deliveryFee)),
              if (d.tipAmount > 0) _Row('Driver tip', value: money(d.tipAmount)),
              const SizedBox(height: 4),
              // Modern Promo Code Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: d.discountCode == null ? const Color(0xFFF8FAFC) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: d.discountCode == null ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.discount_outlined,
                      size: 18,
                      color: d.discountCode == null ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.discountCode == null ? 'Promo code' : d.discountCode!,
                        style: BK.t(14,
                            c: d.discountCode == null ? const Color(0xFF475569) : const Color(0xFF16A34A),
                            w: FontWeight.w700),
                      ),
                    ),
                    if (d.discountCode == null)
                      InkWell(
                        onTap: () => _promo(bp),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: BK.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Apply', style: BK.t(12.5, c: Colors.white, w: FontWeight.w800)),
                        ),
                      )
                    else
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: bp.removeCoupon,
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 24, color: BK.line),
              // To pay now row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(estimate ? 'To pay now' : 'Total', style: BK.h(17)),
                      if (estimate)
                        Text(
                          'No payment required today',
                          style: BK.t(12, c: const Color(0xFF16A34A), w: FontWeight.w700),
                        ),
                    ],
                  ),
                  Text(
                    estimate ? money(0) : money(d.totalAmount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1F5B),
                    ),
                  ),
                ],
              ),
              if (estimate)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your clothes will be counted and priced at our facility. You approve the final itemized total before cleaning begins.',
                            style: BK.t(12, c: const Color(0xFF1E3A8A), w: FontWeight.w500, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ------------------------------------------------ tip
        _Section(
          icon: 'tip',
          title: 'Tip your driver?',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              for (var i = 0; i < _tips.length; i++) ...[
                Expanded(child: _TipChip(label: _tips[i] == 0 ? 'No' : money(_tips[i]), selected: d.tipAmount == _tips[i], onTap: () => bp.setTip(_tips[i]))),
                if (i < _tips.length - 1) const SizedBox(width: 8),
              ],
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: BK.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: BK.line)),
              child: Text('£3 is the most popular tip · 100% goes to your driver', textAlign: TextAlign.center, style: BK.t(13, w: FontWeight.w600)),
            ),
          ]),
        ),

        // ------------------------------------------------ membership
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _open(const MembershipScreen(), '/membership'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF0B1F5B), Color(0xFF1C61E4)]),
                boxShadow: BK.shadow(.2),
              ),
              child: Row(children: [
                const UiIcon('crown', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DrycleanPlus+', style: BK.h(17, c: Colors.white)),
                    const SizedBox(height: 2),
                    Text('No service fee + 15% off every order', style: BK.t(13, c: Colors.white.withValues(alpha: .85), w: FontWeight.w600)),
                  ]),
                ),
                Text('£2.99/mo', style: BK.h(16, c: const Color(0xFFFDE047))),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ]),
            ),
          ),
        ),

        // ------------------------------------------------ order details
        _Section(
          title: 'Order details',
          child: Column(children: [
            _Detail(
              icon: 'calendar',
              title: 'Collection',
              lines: [[d.collectionDate, d.collectionTime].where((e) => (e ?? '').isNotEmpty).join(', '), d.collectionMethod ?? 'Collect from me in person'],
              onEdit: () => _open(const TimeSlotsScreen(isEditMode: true), '/time_slots'),
            ),
            _Detail(
              icon: 'truck',
              title: 'Delivery',
              lines: [[d.deliveryDate, d.deliveryTime].where((e) => (e ?? '').isNotEmpty).join(', '), d.deliveryMethod ?? 'Deliver to me in person'],
              onEdit: () => _open(const TimeSlotsScreen(isEditMode: true), '/time_slots'),
            ),
            _Detail(
              icon: 'bag',
              title: 'Services',
              lines: [
                [...d.selectedServices, if (d.selectedItems.isNotEmpty) d.prepaidPackName ?? 'Prepaid pack'].join(', '),
                ...d.serviceRequests.entries.map((e) => '“${e.value}” — ${e.key}'),
              ],
              onEdit: () => Navigator.of(context).popUntil((r) => r.settings.name == '/select_services' || r.isFirst),
            ),
            _Detail(
              icon: 'pin',
              title: 'Address',
              lines: [d.selectedAddress?.fullAddress ?? 'Add your address', if ((d.instructions ?? '').isNotEmpty) '“${d.instructions}”'],
              onEdit: () => _open(const AddressSelectionScreen(isEditMode: true), '/address_selection'),
            ),
            _Detail(
              icon: 'contact',
              title: 'Contact',
              lines: ['${d.firstName} ${d.lastName.isEmpty ? '' : '${d.lastName[0]}.'}'.trim().isEmpty ? 'Add your details' : '${d.firstName} ${d.lastName.isEmpty ? '' : '${d.lastName[0]}.'}', d.phone],
              onEdit: () => _open(const ContactInfoScreen(isEditMode: true), '/contact_info'),
              last: true,
            ),
          ]),
        ),

        // ------------------------------------------------ repeat + payment
        _Section(
          child: Column(children: [
            Row(children: [
              const UiIcon('repeat', size: 30),
              const SizedBox(width: 12),
              Expanded(child: Text('Repeat this order every week', style: BK.t(15, w: FontWeight.w700))),
              Switch(value: d.repeatOrder, activeTrackColor: BK.blue, onChanged: bp.setRepeatOrder),
            ]),
            const Divider(height: 24, color: BK.line),
            _PayOption(icon: 'cash', title: 'Pay on delivery', sub: 'Card or cash when your order comes back', selected: !_payNow, onTap: () => setState(() => _payNow = false)),
            const SizedBox(height: 10),
            _PayOption(icon: 'card', title: 'Pay now by card', sub: estimate ? 'Pays the estimate; any difference is settled on delivery' : 'Secure online payment', selected: _payNow, onTap: () => setState(() => _payNow = true)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text('By confirming you agree to our Terms and Privacy Policy.', textAlign: TextAlign.center, style: BK.t(12.5, c: Colors.white70, w: FontWeight.w500)),
        ),
      ]),
      ),
      bottomNavigationBar: BottomCta(label: _payNow ? 'Continue to payment' : 'Confirm order', busy: _placing, onTap: () => _confirm(bp)),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title, icon;
  final Widget child;
  const _Section({this.title, this.icon, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: BkCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (title != null) ...[
              Row(children: [if (icon != null) ...[UiIcon(icon!, size: 28), const SizedBox(width: 10)], Text(title!, style: BK.h(18.5))]),
              const SizedBox(height: 12),
            ],
            child,
          ]),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final bool bold;
  final Color? valueColor;
  const _Row(this.label, {this.value, this.trailing, this.bold = false, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(label, style: bold ? BK.h(17) : BK.t(15, w: FontWeight.w500))),
          if (trailing != null) trailing!,
          if (value != null) Text(value!, style: bold ? BK.h(19) : BK.t(15, c: valueColor ?? BK.ink, w: FontWeight.w700)),
        ]),
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final bool green;
  const _Chip(this.text, {this.green = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: green ? const Color(0xFFDCFCE7) : BK.bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: BK.t(11.5, c: green ? const Color(0xFF15803D) : BK.ink, w: FontWeight.w800).copyWith(letterSpacing: .4)),
      );
}

class _TipChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TipChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BK.blueSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? BK.blue : BK.line, width: selected ? 2 : 1),
          ),
          child: Text(label, style: BK.t(16, c: BK.ink, w: selected ? FontWeight.w800 : FontWeight.w600)),
        ),
      );
}

class _Detail extends StatelessWidget {
  final String icon, title;
  final List<String?> lines;
  final VoidCallback onEdit;
  final bool last;
  const _Detail({required this.icon, required this.title, required this.lines, required this.onEdit, this.last = false});

  Widget _buildIcon(String icon) {
    Color bgColor;

    switch (icon) {
      case 'calendar':
        bgColor = const Color(0xFFEEF2FF);
        break;
      case 'truck':
        bgColor = const Color(0xFFCCFBF1);
        break;
      case 'bag':
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'pin':
        bgColor = const Color(0xFFFFE4E6);
        break;
      case 'contact':
        bgColor = const Color(0xFFDCFCE7);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: UiIcon(icon, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = lines.where((l) => (l ?? '').trim().isNotEmpty).cast<String>().toList();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: BK.line))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: BK.t(15, w: FontWeight.w800)),
            for (final l in shown) Padding(padding: const EdgeInsets.only(top: 3), child: Text(l, style: BK.t(13.5, c: BK.mut, w: FontWeight.w500, height: 1.35))),
          ]),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A1D4ED8),
                  blurRadius: 4,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.edit_rounded, color: Color(0xFF1D4ED8), size: 15),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String icon, title, sub;
  final bool selected;
  final VoidCallback onTap;
  const _PayOption({required this.icon, required this.title, required this.sub, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? BK.blueSoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? BK.blue : BK.line, width: selected ? 2 : 1),
          ),
          child: Row(children: [
            UiIcon(icon, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: BK.t(15, w: FontWeight.w800)),
                Text(sub, style: BK.t(12.5, c: BK.mut, w: FontWeight.w500)),
              ]),
            ),
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? BK.blue : BK.mut),
          ]),
        ),
      );
}
