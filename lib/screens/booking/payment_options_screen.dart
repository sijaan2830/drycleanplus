import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/prepaid_provider.dart';
import '../../widgets/app_ui.dart';
import 'booking_confirmation_screen.dart';
import 'payment_screen.dart';

enum _PayChoice { payNow, payLater }

class PaymentOptionsScreen extends StatefulWidget {
  final double amount;
  const PaymentOptionsScreen({super.key, required this.amount});

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  _PayChoice _choice = _PayChoice.payNow;
  bool _placing = false;

  Future<void> _continue() async {
    if (_choice == _PayChoice.payNow) {
      Navigator.of(context).push(
        smoothRoute(PaymentScreen(amount: widget.amount), name: '/payment'),
      );
      return;
    }

    // Pay later (COD): place order right away
    setState(() => _placing = true);
    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final isPrepaidPack = bookingProvider.selectedService == 'Prepaid Pack';

      final order = await bookingProvider.createOrder(
        paymentMethod: 'cod',
        paymentStatus: 'pay_on_delivery',
      );

      if (isPrepaidPack && mounted) {
        try {
          final prepaidProvider = Provider.of<PrepaidProvider>(context, listen: false);
          final packItem = order.bookingData.selectedItems.values.isNotEmpty
              ? order.bookingData.selectedItems.values.first
              : null;
          final packName = order.bookingData.prepaidPackName ?? packItem?.category ?? 'Prepaid Pack';
          final itemType = packItem?.itemType ?? '';
          final count = int.tryParse(itemType.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;

          await prepaidProvider.addPack(PrepaidPack(
            id: order.id.isNotEmpty ? order.id : DateTime.now().millisecondsSinceEpoch.toString(),
            name: packName,
            description: 'Payment on delivery · ${order.orderId}',
            itemCount: count,
            usedCount: 0,
            price: widget.amount,
            itemType: itemType.isNotEmpty ? itemType : packName,
            purchasedDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 90)),
          ));
        } catch (e) {
          debugPrint('Error adding prepaid pack to provider: $e');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        smoothRoute(const BookingConfirmationScreen(), name: '/booking_confirmation'),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not place your order. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = '£${widget.amount.toStringAsFixed(2)}';
    final payNow = _choice == _PayChoice.payNow;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: Stack(
          children: [
            // Ambient decorative background circle
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
                          'Payment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'How would you like to pay?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Total to pay: $amount',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE6EEFF),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Pay Now (Card) Option - Slim
                                _buildPaymentOptionCard(
                                  isSelected: payNow,
                                  title: 'Pay now',
                                  tag: 'CARD',
                                  subtitle: 'Pay securely by card with SumUp.',
                                  icon: Icons.credit_card_rounded,
                                  accentColor: const Color(0xFF1553D6),
                                  accentBg: const Color(0xFFE8F0FF),
                                  onTap: () => setState(() => _choice = _PayChoice.payNow),
                                ),
                                const SizedBox(height: 10),

                                // Pay Later (COD) Option - Slim
                                _buildPaymentOptionCard(
                                  isSelected: !payNow,
                                  title: 'Pay later',
                                  tag: 'COD',
                                  subtitle: 'Cash on delivery — pay after clothes are delivered.',
                                  icon: Icons.payments_rounded,
                                  accentColor: const Color(0xFF0B6E64),
                                  accentBg: const Color(0xFFE4F7F0),
                                  onTap: () => setState(() => _choice = _PayChoice.payLater),
                                ),
                                const SizedBox(height: 16),

                                // Notice Box
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: const Color(0xFF081A5C).withValues(alpha: 0.4),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.shield_rounded,
                                        color: Color(0xFFFFC73A),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          payNow
                                              ? 'You will be taken to our SumUp payment page. Your order is confirmed once payment is done.'
                                              : 'Your order is confirmed right away. Please keep $amount ready for the driver.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                      onTap: _placing ? null : _continue,
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
                            if (_placing)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF0B1F5B),
                                ),
                              )
                            else ...[
                              Icon(
                                payNow ? Icons.lock_rounded : Icons.check_circle_rounded,
                                color: const Color(0xFF0B1F5B),
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                payNow ? 'PAY $amount NOW' : 'PLACE ORDER · PAY LATER',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF0B1F5B),
                                ),
                              ),
                            ],
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
  }

  // ── Slim Payment Option Card ────────────────────────────────────────────────

  Widget _buildPaymentOptionCard({
    required bool isSelected,
    required String title,
    required String tag,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color accentBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.28),
            width: isSelected ? 3.5 : 1.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x8C02104C),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // 46x46 compact tile
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isSelected ? accentBg : Colors.white,
                border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF02104C).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? accentColor : const Color(0xFF0B1F5B),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFF0B1F5B) : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: isSelected ? accentBg : Colors.white.withValues(alpha: 0.22),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: isSelected ? accentColor : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF5B6B9A) : const Color(0xFFE6EEFF),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Radio Circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.7),
                  width: 2.5,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 15),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
