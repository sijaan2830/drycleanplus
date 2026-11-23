import '../../widgets/collection_delivery_badges.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/order_card_widget.dart';
import '../service_overview_screen.dart';
import 'address_selection_screen.dart';
import 'contact_info_screen.dart';
import 'payment_options_screen.dart';
import 'time_slots_screen.dart';

class BookingOverviewScreen extends StatefulWidget {
  const BookingOverviewScreen({super.key});

  @override
  State<BookingOverviewScreen> createState() => _BookingOverviewScreenState();
}

class _BookingOverviewScreenState extends State<BookingOverviewScreen> {
  bool _showCouponField = false;
  bool _applyingCoupon = false;
  bool _isServicesExpanded = false;
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1F5B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Cancel order?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Your selected items and details will be cleared.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Keep order',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Provider.of<BookingProvider>(context, listen: false).clearBookingData();
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            child: Text(
              'Yes, cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFF8A80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateTo(Widget screen, String routeName) {
    return Navigator.of(context).push(smoothRoute(screen, name: routeName));
  }

  String? _validate(BookingData d) {
    if (d.selectedAddress == null) return 'Please select a collection address';
    if ((d.collectionDate ?? '').isEmpty || (d.collectionTime ?? '').isEmpty) {
      return 'Please select a collection date and time';
    }
    if ((d.deliveryDate ?? '').isEmpty || (d.deliveryTime ?? '').isEmpty) {
      return 'Please select a delivery date and time';
    }
    if (d.firstName.trim().isEmpty || d.phone.trim().isEmpty) {
      return 'Please complete your contact information';
    }
    return null;
  }

  void _payNow(BookingData d) {
    final problem = _validate(d);
    if (problem != null) {
      showAppSnack(context, problem, error: true);
      return;
    }
    Navigator.of(context).push(
      smoothRoute(PaymentOptionsScreen(amount: d.totalAmount), name: '/payment_options'),
    );
  }

  Future<void> _applyCoupon(BookingProvider provider) async {
    if (_applyingCoupon) return;
    setState(() => _applyingCoupon = true);
    final result = await provider.applyCoupon(_couponController.text);
    if (!mounted) return;
    setState(() => _applyingCoupon = false);
    showAppSnack(context, result['message']?.toString() ?? '', error: result['success'] != true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final d = provider.bookingData;
        final total = d.totalAmount;

        final grouped = <String, List<ServiceItem>>{};
        for (final item in d.selectedItems.values) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.bgGradient,
            ),
            child: Stack(
              children: [
                // Ambient top decorative circle
                Positioned(
                  top: -140,
                  right: -150,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // Header Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            Text(
                              'Review order',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showCancelConfirmation,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Progress Steps Bar (Step 4 of 4 filled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(4, (index) {
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                                height: 7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: const Color(0xFFFFC73A),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x99FFC73A),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Scrollable content stack
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Total to pay card (cd tot)
                                    _buildTotalCard(d, provider),
                                    const SizedBox(height: 16),

                                    // 2. Collection & delivery card (cd v) - Zoomed out compact style
                                    _buildCollectionDeliveryCard(d),
                                    const SizedBox(height: 16),

                                    // 3. Services card (cd bl) - Short summary with dropdown
                                    _buildServicesCard(d, provider, grouped),
                                    const SizedBox(height: 16),

                                    // 4. Collection address card (cd te inf)
                                    _buildAddressCard(d),
                                    const SizedBox(height: 16),

                                    // 5. Contact information card (cd v inf)
                                    _buildContactCard(d),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed Bottom Dock CTA
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      14 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0A2468).withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: GestureDetector(
                          onTap: d.selectedItems.isEmpty ? null : () => _payNow(d),
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFD25E), Color(0xFFFFB400)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x8CFFB400),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFF0B1F5B),
                                  size: 21,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'PAY NOW  £${total.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF0B1F5B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 1. Total to pay card (cd tot) ──────────────────────────────────────────

  Widget _buildTotalCard(BookingData d, BookingProvider provider) {
    final hasCoupon = d.discountCode != null;
    final itemsCount = d.selectedItems.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C02104C),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Top gradient header (th)
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1553D6), Color(0xFF4F46E5)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total to pay',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '£${d.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.2,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Text(
                          '$itemsCount ${itemsCount == 1 ? 'item' : 'items'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Decorative circles in header
                Positioned(
                  top: -56,
                  right: -34,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.13),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: 180,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Body breakdown (tb)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                children: [
                  _buildPriceLine('Subtotal', '£${d.subtotal.toStringAsFixed(2)}'),
                  if (d.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    _buildPriceLine(
                      'Discount (${d.discountCode})',
                      '-£${d.discountAmount.toStringAsFixed(2)}',
                      isDiscount: true,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _buildPriceLine('Service fee', '£${BookingData.serviceFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _buildPriceLine('Delivery fee', 'FREE', isFreePill: true),
                  const SizedBox(height: 10),

                  // Dashed Divider
                  CustomPaint(
                    size: const Size(double.infinity, 2),
                    painter: const DashedDividerPainter(
                      color: Color(0xFFDCE5F8),
                      strokeWidth: 2,
                      dashWidth: 6,
                      dashSpace: 4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Total line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1F5B),
                        ),
                      ),
                      Text(
                        '£${d.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1F5B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Coupon expandable
                  GestureDetector(
                    onTap: () => setState(() => _showCouponField = !_showCouponField),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_rounded, color: Color(0xFF1553D6), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasCoupon ? 'Coupon applied: ${d.discountCode}' : 'Have a coupon code?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: hasCoupon ? const Color(0xFF0A5C36) : const Color(0xFF1553D6),
                              ),
                            ),
                          ),
                          Icon(
                            _showCouponField ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF1553D6),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Coupon Input Form
                  if (_showCouponField && !hasCoupon) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE1E9FB), width: 2),
                              color: const Color(0xFFF4F7FF),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _couponController,
                                textCapitalization: TextCapitalization.characters,
                                cursorColor: const Color(0xFF1553D6),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0B1F5B),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter code',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5B6B9A),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _applyingCoupon ? null : () => _applyCoupon(provider),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFF1553D6),
                            ),
                            child: Center(
                              child: _applyingCoupon
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Apply',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceLine(String label, String value, {bool isDiscount = false, bool isFreePill = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5B6B9A),
          ),
        ),
        if (isFreePill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFDDF6E6),
            ),
            child: Text(
              'FREE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0A5C36),
                letterSpacing: 0.6,
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDiscount ? const Color(0xFF0A5C36) : const Color(0xFF0B1F5B),
            ),
          ),
      ],
    );
  }

  // ── 2. Collection & delivery card (cd v) - Zoomed Out Compact ───────────────

  Widget _buildCollectionDeliveryCard(BookingData d) {
    return _buildCardBase(
      accentColor: const Color(0xFF4338CA),
      accentBg: const Color(0xFFEEF0FF),
      icon: Icons.calendar_month_rounded,
      title: 'Collection & delivery',
      onEdit: () => _navigateTo(const TimeSlotsScreen(isEditMode: true), '/time_slots'),
      child: Column(
        children: [
          // Collection row with Vector Calendar & Clock badge
          _buildTimelineSlotRow(
            isCollection: true,
            label: 'COLLECTION',
            dateTime: '${d.collectionDate ?? 'Not selected'} · ${d.collectionTime ?? ''}',
            method: d.collectionMethod ?? 'Collect from me in person',
            accentColor: const Color(0xFF4338CA),
            accentBg: const Color(0xFFEEF0FF),
          ),
          const SizedBox(height: 8),

          // Delivery row with Vector Delivery Van badge
          _buildTimelineSlotRow(
            isCollection: false,
            label: 'DELIVERY',
            dateTime: '${d.deliveryDate ?? 'Not selected'} · ${d.deliveryTime ?? ''}',
            method: d.deliveryMethod ?? 'Deliver to me in person',
            accentColor: const Color(0xFF0B6E64),
            accentBg: const Color(0xFFE4F7F0),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSlotRow({
    required bool isCollection,
    required String label,
    required String dateTime,
    required String method,
    required Color accentColor,
    required Color accentBg,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 38x38 compact illustration badge with vector icon
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accentBg,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF02104C).withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(26, 26),
              painter: isCollection
                  ? const CollectionBadgePainter()
                  : const DeliveryBadgePainter(),
            ),
          ),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5B6B9A),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                dateTime,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B1F5B),
                ),
              ),
              Text(
                method,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B6B9A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 3. Services card (cd bl) - Short Summary with Dropdown ───────────────────

  Widget _buildServicesCard(BookingData d, BookingProvider provider, Map<String, List<ServiceItem>> grouped) {
    final count = d.selectedItems.length;
    final allItems = grouped.entries.expand((entry) => entry.value).toList();

    return _buildCardBase(
      accentColor: const Color(0xFF1553D6),
      accentBg: const Color(0xFFE8F0FF),
      icon: Icons.local_laundry_service_rounded,
      title: 'Services',
      subtitle: '$count ${count == 1 ? 'item' : 'items'}',
      onEdit: () {
        final svc = provider.selectedService ?? 'Dry Clean';
        _navigateTo(
          ServiceOverviewScreen(serviceType: svc, isEditMode: true),
          '/service_overview',
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Service Banner & Dropdown Toggle Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF4F7FF),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF1553D6), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.dry_cleaning_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.selectedService ?? 'Dry Clean',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1F5B),
                        ),
                      ),
                      Text(
                        '$count ${count == 1 ? 'item' : 'items'} in order',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5B6B9A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (allItems.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _isServicesExpanded = !_isServicesExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isServicesExpanded ? const Color(0xFF1553D6) : const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isServicesExpanded ? 'Hide' : 'Check items',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isServicesExpanded ? Colors.white : const Color(0xFF1553D6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isServicesExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: _isServicesExpanded ? Colors.white : const Color(0xFF1553D6),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Collapsible Items List
          if (allItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No items selected',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF5B6B9A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (_isServicesExpanded) ...[
            const SizedBox(height: 10),
            ...allItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8F0FF),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B1F5B).withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          _getIconForCategory(item.category),
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.itemType,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B1F5B),
                        ),
                      ),
                    ),
                    Text(
                      '£${item.numericPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _getIconForCategory(String category) {
    final s = category.toLowerCase();
    if (s.contains('duvet') || s.contains('bedding')) {
      return 'assets/images/price_duvet.png';
    } else if (s.contains('laundry')) {
      return 'assets/images/price_laundry.png';
    } else if (s.contains('wash')) {
      return 'assets/images/price_wash.png';
    } else if (s.contains('household') || s.contains('iron')) {
      return 'assets/images/price_household.png';
    }
    return 'assets/images/price_dryclean.png';
  }

  // ── 4. Collection address card (cd te inf) ──────────────────────────────────

  Widget _buildAddressCard(BookingData d) {
    return _buildCardBase(
      accentColor: const Color(0xFF0B6E64),
      accentBg: const Color(0xFFE4F7F0),
      icon: Icons.location_on_rounded,
      title: 'Collection address',
      isSmallTitle: true,
      subtitleContent: d.selectedAddress?.fullAddress ?? 'No address selected',
      onEdit: () => _navigateTo(const AddressSelectionScreen(isEditMode: true), '/address_selection'),
      child: const SizedBox.shrink(),
    );
  }

  // ── 5. Contact information card (cd v inf) ──────────────────────────────────

  Widget _buildContactCard(BookingData d) {
    final name = '${d.firstName} ${d.lastName}'.trim();
    final phone = d.phone;

    return _buildCardBase(
      accentColor: const Color(0xFF4338CA),
      accentBg: const Color(0xFFEEF0FF),
      icon: Icons.person_rounded,
      title: 'Contact information',
      isSmallTitle: true,
      subtitleContent: name.isNotEmpty ? name : 'Name not provided',
      extraContent: phone.isNotEmpty ? phone : null,
      onEdit: () => _navigateTo(const ContactInfoScreen(isEditMode: true), '/contact_info'),
      child: const SizedBox.shrink(),
    );
  }

  // ── Reusable Card Base ─────────────────────────────────────────────────────

  Widget _buildCardBase({
    required Color accentColor,
    required Color accentBg,
    required IconData icon,
    required String title,
    String? subtitle,
    bool isSmallTitle = false,
    String? subtitleContent,
    String? extraContent,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C02104C),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background disc (top-right)
            Positioned(
              top: -70,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentBg,
                ),
              ),
            ),

            // Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: isSmallTitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(icon, color: Colors.white, size: 23),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: isSmallTitle
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF5B6B9A),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitleContent ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0B1F5B),
                                      height: 1.25,
                                    ),
                                  ),
                                  if (extraContent != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      extraContent,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0B1F5B),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0B1F5B),
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      subtitle,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5B6B9A),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(width: 8),

                      // Edit Button
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: accentBg,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, color: accentColor, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                'Edit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (child is! SizedBox || child.height != 0) ...[
                    const SizedBox(height: 14),
                    child,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
