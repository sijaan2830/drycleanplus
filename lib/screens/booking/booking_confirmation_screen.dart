import '../track_order_screen.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/payment_config.dart';
import '../../config/theme.dart';
import '../../models/booking_models.dart' as models;
import '../../providers/booking_provider.dart';
import '../../utils/route_helpers.dart';
import '../../widgets/order_card_widget.dart';
import '../../widgets/persistent_footer_app.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
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
                child: Consumer<BookingProvider>(
                  builder: (context, provider, _) {
                    final orders = provider.orders;
                    models.Order? order;
                    final last = provider.lastPlacedOrder;
                    if (last != null) {
                      // the order just placed — live copy from the list once it arrives
                      order = orders.firstWhere((o) => o.id == last.id, orElse: () => last);
                    } else if (orders.isNotEmpty) {
                      order = orders.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
                    }
                    return _ConfirmationBody(order: order);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationBody extends StatelessWidget {
  final models.Order? order;
  const _ConfirmationBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final isCod = (o?.paymentMethod ?? o?.bookingData.paymentMethod) == PaymentConfig.methodCod;
    final amount = o?.transactionAmount ?? o?.bookingData.totalAmount ?? 0.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            // Confetti & Badge Stack
            Stack(
              alignment: Alignment.center,
              children: [
                // Confetti flakes
                Positioned(
                  left: 30,
                  top: 10,
                  child: Transform.rotate(
                    angle: 25 * math.pi / 180,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC73A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 70,
                  top: 70,
                  child: Transform.rotate(
                    angle: -30 * math.pi / 180,
                    child: Container(
                      width: 8,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 40,
                  top: 15,
                  child: Transform.rotate(
                    angle: 35 * math.pi / 180,
                    child: Container(
                      width: 12,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7BCBFB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 70,
                  top: 80,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFC73A),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFA6EB60),
                    ),
                  ),
                ),

                // 128x128 Expanding Pulsing Badge with Animated Drawing Checkmark
                const _AnimatedSuccessCheckBadge(),
              ],
            ),
            const SizedBox(height: 20),

            // Heading & Subtitle
            Center(
              child: Text(
                'Order placed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  o?.type == 'quick_bag'
                      ? 'We’ll count your items at our facility and confirm the price with you before cleaning. You pay on delivery.'
                      : isCod
                          ? 'Please pay £${amount.toStringAsFixed(2)} when your order is delivered.'
                          : 'Thank you! Your payment of £${amount.toStringAsFixed(2)} has been received.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE6EEFF),
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 4-step progress stepper
            _buildOrderProgressPill(),
            const SizedBox(height: 22),

            // Ticket Receipt Card (rcw)
            if (o == null)
              _buildLoadingDetails()
            else
              _buildReceiptTicketCard(o, isCod, amount),
            const SizedBox(height: 24),

            // Action Buttons with Animated Van Go Animation
            _AnimatedVanTrackButton(
              onTap: () {
                if (o != null) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => TrackOrderScreen(order: o)),
                  );
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => false);
                }
              },
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                persistentFooterAppState?.setTab(0);
                navigatorKey.currentState?.pushAndRemoveUntil(
                  noTransitionRoute(const MainTabScreen(tabIndex: 0), routeName: '/home'),
                  (route) => false,
                );
              },
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    'BACK TO HOME',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
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

  Widget _buildOrderProgressPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF081A5C).withValues(alpha: 0.38),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _stepNode('Placed', isActive: true),
          _stepNode('Collected', isActive: false),
          _stepNode('Cleaning', isActive: false),
          _stepNode('Delivered', isActive: false),
        ],
      ),
    );
  }

  Widget _stepNode(String label, {required bool isActive}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFFFFC73A) : Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                width: isActive ? 3 : 2,
              ),
              boxShadow: isActive
                  ? const [
                      BoxShadow(
                        color: Color(0xB2FFC73A),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
              color: isActive ? Colors.white : const Color(0xFFDCE8FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTicketCard(models.Order o, bool isCod, double amount) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6602104C),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Ticket section (rt)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                _ticketRow('Order number', o.orderId, isOrderNumber: true),
                _ticketRow(
                  'Status',
                  'Pending',
                  customWidget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFFFFE58C),
                    ),
                    child: Text(
                      'Pending',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                      ),
                    ),
                  ),
                ),
                _ticketRow('Collection', '${o.bookingData.collectionDate ?? '-'} · ${o.bookingData.collectionTime ?? ''}'),
                _ticketRow('Delivery', '${o.bookingData.deliveryDate ?? '-'} · ${o.bookingData.deliveryTime ?? ''}'),
                _ticketRow('Items', '${o.bookingData.selectedItemsCount}'),
                _ticketRow('Payment', isCod ? 'Pay on delivery (cash)' : 'Paid online (SumUp)'),
              ],
            ),
          ),

          // Dashed Divider with Notches
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 20,
                color: Colors.white,
                child: Center(
                  child: CustomPaint(
                    size: const Size(double.infinity, 2),
                    painter: const DashedDividerPainter(
                      color: Color(0xFFCBD6F0),
                      strokeWidth: 2,
                      dashWidth: 6,
                      dashSpace: 4,
                    ),
                  ),
                ),
              ),
              // Left cutout notch
              Positioned(
                left: -10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1C61E4),
                  ),
                ),
              ),
              // Right cutout notch
              Positioned(
                right: -10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1C61E4),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Ticket section (rb2)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFEEF3FF)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isCod ? 'To pay on delivery' : 'Paid',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5B6B9A),
                  ),
                ),
                Text(
                  '£${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: const Color(0xFF1553D6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, String value, {bool isOrderNumber = false, Widget? customWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5B6B9A),
            ),
          ),
          if (customWidget != null)
            customWidget
          else
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isOrderNumber ? 17 : 15,
                fontWeight: FontWeight.w800,
                color: isOrderNumber ? const Color(0xFF1553D6) : const Color(0xFF0B1F5B),
                letterSpacing: isOrderNumber ? 0.3 : 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingDetails() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF1553D6)),
      ),
    );
  }
}

class _AnimatedSuccessCheckBadge extends StatefulWidget {
  const _AnimatedSuccessCheckBadge();

  @override
  State<_AnimatedSuccessCheckBadge> createState() => _AnimatedSuccessCheckBadgeState();
}

class _AnimatedSuccessCheckBadgeState extends State<_AnimatedSuccessCheckBadge>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _popController;
  late final AnimationController _drawController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _drawController.forward();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _popController.dispose();
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Expanding Pulse Ring (@keyframes ring from Checkout.html)
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, _) {
              final val = _ringController.value;
              final scale = 0.85 + (0.45 * val);
              final opacity = (1.0 - val).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Translucent outer halo disc (.badge)
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),

          // 3. Popping bounce white disc (.badge i: @keyframes pop)
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _popController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x6602104C),
                    blurRadius: 26,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Center(
                // 4. Drawing Checkmark (@keyframes draw)
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: AnimatedBuilder(
                    animation: _drawController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _CheckmarkStrokePainter(
                          progress: _drawController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckmarkStrokePainter extends CustomPainter {
  final double progress;

  _CheckmarkStrokePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFF1553D6)
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Path matching SVG: M5 12.5l4.5 4.5L19 7.5 (scaled to 52x52)
    final p1 = Offset(size.width * 0.22, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.72);
    final p3 = Offset(size.width * 0.80, size.height * 0.32);

    final path = Path();
    final firstSegLength = (p2 - p1).distance;
    final secondSegLength = (p3 - p2).distance;
    final totalLength = firstSegLength + secondSegLength;
    final curLength = totalLength * progress;

    path.moveTo(p1.dx, p1.dy);
    if (curLength <= firstSegLength) {
      final t = curLength / firstSegLength;
      final currentPoint = Offset.lerp(p1, p2, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (curLength - firstSegLength) / secondSegLength;
      final currentPoint = Offset.lerp(p2, p3, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkStrokePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// "TRACK ORDER" button with smooth animated delivery van driving across
class _AnimatedVanTrackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedVanTrackButton({required this.onTap});

  @override
  State<_AnimatedVanTrackButton> createState() => _AnimatedVanTrackButtonState();
}

class _AnimatedVanTrackButtonState extends State<_AnimatedVanTrackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vanDriveController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _vanDriveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _vanDriveController.dispose();
    super.dispose();
  }

  void _triggerDrive() async {
    if (_isNavigating) return;
    _isNavigating = true;
    HapticFeedback.mediumImpact();
    await _vanDriveController.forward();
    if (mounted) {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerDrive,
      child: Container(
        height: 58,
        clipBehavior: Clip.antiAlias,
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
        child: AnimatedBuilder(
          animation: _vanDriveController,
          builder: (context, _) {
            final t = _vanDriveController.value;
            // Van moves smoothly across from left to right
            final vanOffset = t * 290.0;
            final vanOpacity = (1.0 - t * 0.3).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Label (fades slightly as van drives)
                Opacity(
                  opacity: (1.0 - t * 0.35).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 30),
                      Text(
                        'TRACK ORDER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF0B1F5B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Animated Driving Van Icon with speed streaks
                Positioned(
                  left: 36 + vanOffset,
                  child: Opacity(
                    opacity: vanOpacity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (t > 0.05) ...[
                          // Speed streak lines behind van
                          Container(
                            width: t * 45,
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [Colors.transparent, Color(0xFF0B1F5B)],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Van Icon bobbing with motion
                        Transform.translate(
                          offset: Offset(0, math.sin(t * math.pi * 6) * 1.5),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Color(0xFF0B1F5B),
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
