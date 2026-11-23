import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking_models.dart' as models;
import '../utils/order_status.dart';
import 'service_price_card.dart';

class OrderCardWidget extends StatelessWidget {
  final models.Order order;
  final VoidCallback onTrack;
  final VoidCallback? onReorder;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.onTrack,
    this.onReorder,
  });

  String _getServiceAsset(models.Order order) {
    String svc = order.bookingData.prepaidPackName ?? '';
    if (svc.isEmpty && order.bookingData.selectedItems.isNotEmpty) {
      svc = order.bookingData.selectedItems.values.first.category;
    }
    if (svc.isEmpty) {
      svc = order.type;
    }
    final s = svc.toLowerCase();
    if (s.contains('duvet') || s.contains('bulky')) {
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

  int _calculateStepIndex(int statusStep, bool delivered) {
    if (delivered) return 3;
    switch (statusStep) {
      case 0:
        return 0; // Pending (1/4)
      case 1:
        return 1; // Confirmed (2/4)
      case 2:
      case 3:
        return 2; // Cleaning / In progress (3/4)
      case 4:
        return 3; // Delivered (4/4)
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = orderStatusInfo(order.status);
    final delivered = isOrderDelivered(order.status);
    final cancelled = info.step == -1;
    final total = order.transactionAmount ?? order.bookingData.totalAmount;
    final method = order.paymentMethod ?? order.bookingData.paymentMethod;
    final isCod = method == 'cod';
    final stepIndex = _calculateStepIndex(info.step, delivered);
    final assetImage = _getServiceAsset(order);

    // Gradient based on order status (.pend / .done)
    final List<Color> gradientColors = delivered
        ? const [Color(0xFFC9F78E), Color(0xFFA6EB60)] // Mint green
        : cancelled
            ? const [Color(0xFFFFB4BA), Color(0xFFFF8D96)] // Soft coral red
            : const [Color(0xFFFFE58C), Color(0xFFFFCB4F)]; // Warm sun yellow

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card (.oc)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 38, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: const Alignment(-0.8, -0.6),
                end: const Alignment(0.8, 0.6),
                colors: gradientColors,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF02104C).withOpacity(0.38),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background disc (right: -60, top: -60, 190x190)
                Positioned(
                  right: -60,
                  top: -60,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.34),
                    ),
                  ),
                ),

                // Background ring (left: -46, bottom: -46, 120x120)
                Positioned(
                  left: -46,
                  bottom: -46,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.24), width: 15),
                    ),
                  ),
                ),

                // Decorative Confetti for Delivered/Completed orders
                if (delivered) ...[
                  Positioned(
                    left: 140,
                    top: 14,
                    child: Transform.rotate(
                      angle: 25 * 3.14159 / 180,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7B86),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 200,
                    top: 26,
                    child: Transform.rotate(
                      angle: -30 * 3.14159 / 180,
                      child: Container(
                        width: 7,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1F5B).withOpacity(0.75),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 172,
                    top: 30,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFD25E),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 62,
                    child: Transform.rotate(
                      angle: 35 * 3.14159 / 180,
                      child: Container(
                        width: 10,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BCBFB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 76,
                    top: 56,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 218,
                    top: 20,
                    child: Transform.rotate(
                      angle: 50 * 3.14159 / 180,
                      child: Container(
                        width: 6,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],

                // Content Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID (.id)
                    Text(
                      order.orderId,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Date & Item Count (.date)
                    Text(
                      'Placed ${formatOrderDate(order.createdAt)} · ${order.bookingData.selectedItemsCount} items',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F3274),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Progress Stepper (.steps)
                    _OrderProgressStepper(
                      currentStep: stepIndex,
                      isDelivered: delivered,
                      isCancelled: cancelled,
                    ),
                    const SizedBox(height: 10),

                    // Status line with fraction (.status)
                    Row(
                      children: [
                        Icon(
                          delivered
                              ? Icons.check_circle_rounded
                              : (cancelled ? Icons.cancel_rounded : info.icon),
                          size: 17,
                          color: const Color(0xFF0B1F5B),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            delivered ? 'Delivered successfully' : info.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1F5B),
                            ),
                          ),
                        ),
                        Text(
                          cancelled ? 'Cancelled' : '${stepIndex + 1}/4',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F3274),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dashed Divider (.ft top border)
                    CustomPaint(
                      size: const Size(double.infinity, 2),
                      painter: DashedDividerPainter(
                        color: const Color(0xFF0B1F5B).withOpacity(0.28),
                        strokeWidth: 2,
                        dashWidth: 6,
                        dashSpace: 4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Footer Row (.ft)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.bookingData.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0)
                                    ? 'Bill status'
                                    : (delivered
                                        ? 'Total paid'
                                        : (isCod ? 'To pay on delivery' : 'Total')),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: const Color(0xFF1F3274),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Marker price
                              Stack(
                                alignment: Alignment.bottomLeft,
                                children: [
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 2,
                                    height: 11,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Text(
                                      order.bookingData.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0)
                                          ? 'Pending count'
                                          : '£${total.toStringAsFixed(2)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: order.bookingData.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0) ? 18 : 26,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: const Color(0xFF0B1F5B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action Button (.btn)
                        GestureDetector(
                          onTap: delivered ? (onReorder ?? onTrack) : onTrack,
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.fromLTRB(17, 0, 5, 0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1F5B),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF02104C).withOpacity(0.34),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  delivered ? 'Reorder' : 'Track order',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    delivered ? Icons.refresh_rounded : Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: const Color(0xFF0B1F5B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top-left Rotated Status Flag Badge (.flag)
          Positioned(
            top: -12,
            left: 14,
            child: Transform.rotate(
              angle: -3 * 3.14159 / 180,
              child: Container(
                height: 26,
                padding: const EdgeInsets.fromLTRB(11, 0, 13, 0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F5B),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF02104C).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!delivered && !cancelled) ...[
                      // Pulsing Yellow Dot (.pulse)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD25E),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD25E).withOpacity(0.7),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                    ] else if (delivered) ...[
                      const Icon(Icons.check_rounded, size: 14, color: Color(0xFF7DE85C)),
                      const SizedBox(width: 6),
                    ] else ...[
                      const Icon(Icons.close_rounded, size: 14, color: Color(0xFFFF7B86)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isLiveOrderStatus(order.status) ? '${info.label.toUpperCase()} · LIVE' : info.label.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sparkle star next to floating disc
          const Positioned(
            right: 88,
            top: -8,
            child: SparkleStarWidget(size: 14, color: Colors.white),
          ),

          // Top-right 64x64 Floating 3D Icon Disc (.ic)
          Positioned(
            top: -18,
            right: 12,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    spreadRadius: 4,
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF02104C).withOpacity(0.34),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(5),
              child: ClipOval(
                child: Image.asset(
                  assetImage,
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.receipt_long_rounded,
                    size: 32,
                    color: Color(0xFF0B1F5B),
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

// ─────────────────────────────────────────────────────────────────────────────
// 4-Step Progress Stepper (.steps)
// ─────────────────────────────────────────────────────────────────────────────
class _OrderProgressStepper extends StatelessWidget {
  final int currentStep; // 0..3
  final bool isDelivered;
  final bool isCancelled;

  const _OrderProgressStepper({
    required this.currentStep,
    required this.isDelivered,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    const steps = ['Pending', 'Confirmed', 'Cleaning', 'Delivered'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connecting horizontal bar (.st::before)
          final stepAfter = (index + 1) ~/ 2;
          final isCompleted = isDelivered || stepAfter <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: isCancelled
                    ? const Color(0xFF0B1F5B).withOpacity(0.18)
                    : (isCompleted
                        ? const Color(0xFF0B1F5B)
                        : const Color(0xFF0B1F5B).withOpacity(0.18)),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        } else {
          // Step Dot (.dot)
          final step = index ~/ 2;
          final isPassed = isDelivered || step < currentStep;
          final isCurrent = !isDelivered && step == currentStep;
          final isFin = isDelivered && step == steps.length - 1;

          if (isPassed) {
            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B1F5B),
                boxShadow: isFin
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.65),
                          spreadRadius: 4,
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
            );
          } else if (isCurrent && !isCancelled) {
            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF0B1F5B), width: 3),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0B1F5B),
                ),
              ),
            );
          } else {
            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
                border: Border.all(
                  color: const Color(0xFF0B1F5B).withOpacity(0.4),
                  width: 2,
                ),
              ),
            );
          }
        }
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed Divider Painter
// ─────────────────────────────────────────────────────────────────────────────
class DashedDividerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const DashedDividerPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedDividerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}
