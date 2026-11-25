import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/booking_models.dart' as models;
import '../providers/booking_provider.dart';
import '../utils/order_status.dart';
import '../widgets/live_tracking_card.dart';
import '../widgets/order_card_widget.dart';
import '../widgets/persistent_footer_app.dart';
import '../widgets/service_price_card.dart';
import 'track_driver_screen.dart';

class TrackOrderScreen extends StatefulWidget {
  final models.Order order;

  const TrackOrderScreen({super.key, required this.order});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> with SingleTickerProviderStateMixin {
  late models.Order _currentOrder;
  late AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<BookingProvider>(context, listen: false).initializeListeners();
    });
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  void _handleRefresh(BookingProvider provider) {
    _refreshAnimController.forward(from: 0.0);
    provider.initializeListeners();
  }

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

  void _safeBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final state = persistentFooterAppState ?? persistentFooterKey.currentState;
      if (state != null && state.tabHistory.length > 1) {
        state.tabHistory.removeLast();
        final prevTab = state.tabHistory.last;
        state.setTab(prevTab, addToHistory: false);
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.order.id).snapshots(),
      builder: (context, docSnap) {
        if (docSnap.hasData && docSnap.data != null && docSnap.data!.exists) {
          try {
            _currentOrder = models.Order.fromJson({...docSnap.data!.data()!, 'id': docSnap.data!.id});
          } catch (_) {}
        }
        return Consumer<BookingProvider>(
          builder: (context, provider, _) {
            // Also update from provider if available
            final pOrder = provider.orders.where((o) => o.id == widget.order.id).firstOrNull;
            if (pOrder != null && docSnap.data == null) {
              _currentOrder = pOrder;
            }
            final order = _currentOrder;
            final info = orderStatusInfo(order.status);
            final delivered = isOrderDelivered(order.status);
            final cancelled = info.step == -1 || normalizeOrderStatus(order.status) == 'cancelled';
            final isEnRoute = isLiveOrderStatus(order.status);

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _safeBack();
              },
              child: Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.bgGradient,
                  ),
                  child: Stack(
                    children: [
                      // Ambient background decorative circles
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
                      Positioned(
                        top: 760,
                        left: -230,
                        child: Container(
                          width: 420,
                          height: 420,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),

                      // Main Content
                      SafeArea(
                        child: Column(
                          children: [
                            // Header Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 44x44 glass back button
                                  GestureDetector(
                                    onTap: _safeBack,
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

                                  // Centered Title
                                  Text(
                                    'Track order',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),

                                  // 44x44 glass refresh button with spin
                                  GestureDetector(
                                    onTap: () => _handleRefresh(provider),
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
                                      child: RotationTransition(
                                        turns: _refreshAnimController,
                                        child: const Center(
                                          child: Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // List of Cards
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                                children: [
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 480),
                                      child: Column(
                                        children: [
                                          // 1. Order Header Card
                                          _buildOrderHeaderCard(order, info, delivered, cancelled),
                                          const SizedBox(height: 30),

                                          // If CANCELLED: Map and all active cards are completely deactivated / dead
                                          if (cancelled) ...[
                                            _buildCancelledCard(),
                                            const SizedBox(height: 30),
                                            _buildNeedHelpButton(context),
                                          ] else ...[
                                            // Live driver map ONLY when driver is actually ON THE WAY (en route / arrived)
                                            if (isEnRoute && !delivered)
                                              LiveTrackingCard(order: order),

                                            // Facility found extras / damage / itemized count → customer approves the new total
                                            if (normalizeOrderStatus(order.status) == 'awaiting_approval')
                                              ApprovalCard(order: order),

                                            // 2. Order Journey Card
                                            _buildOrderJourneyCard(order, info, delivered),
                                            const SizedBox(height: 30),

                                            // 3. Collection & Delivery Card
                                            _buildCollectionDeliveryCard(order),
                                            const SizedBox(height: 30),

                                            // 4. Items Card
                                            _buildItemsCard(order),
                                            const SizedBox(height: 30),

                                            // 5. Payment Card
                                            _buildPaymentCard(order, delivered),
                                            const SizedBox(height: 24),

                                            // 6. Need Help Button
                                            _buildNeedHelpButton(context),
                                            const SizedBox(height: 16),

                                            // 7. Cancel Order Button (active non-delivered, non-cancelled orders)
                                            if (!delivered) ...[
                                              _buildCancelOrderButton(order),
                                              const SizedBox(height: 16),
                                            ],
                                          ],
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── 1. Order Header Card (oc pend) ──────────────────────────────────────────
  Widget _buildOrderHeaderCard(
    models.Order order,
    OrderStatusInfo info,
    bool delivered,
    bool cancelled,
  ) {
    final d = order.bookingData;
    final total = order.transactionAmount ?? d.totalAmount;
    final itemsCount = d.selectedItems.isNotEmpty
        ? d.selectedItems.length
        : (order.type == 'prepaid_pack' ? 1 : 0);

    // Card background gradient
    LinearGradient bgGradient;
    if (cancelled) {
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFC2C6), Color(0xFFFF8F99)],
      );
    } else if (delivered) {
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDDF6E6), Color(0xFFA6EB60)],
      );
    } else if (info.step >= 2) {
      // Cleaning / In progress
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFBDEBFF), Color(0xFF7BCBFB)],
      );
    } else {
      // Pending / Placed
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE58C), Color(0xFFFFCB4F)],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: bgGradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x7F02104C),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Background disc (top-right)
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                ),
                // Background ring (bottom-left)
                Positioned(
                  bottom: -46,
                  left: -46,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 15,
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID
                      Text(
                        order.orderId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1F5B),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Placed Date & Item Count or Service
                      Builder(builder: (context) {
                        final services = order.bookingData.selectedServices;
                        final serviceLabel = services.isNotEmpty
                            ? services.join(', ')
                            : (order.bookingData.prepaidPackName ?? (order.type == 'quick_bag' ? 'Standard Service' : ''));
                        final subtitle = itemsCount > 0
                            ? '$itemsCount ${itemsCount == 1 ? 'item' : 'items'}'
                            : (serviceLabel.isNotEmpty ? serviceLabel : 'Counted at facility');
                        return Text(
                          'Placed ${formatOrderDate(order.createdAt)} · $subtitle',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F3274),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      // 5 Segmented Progress Bar
                      _buildSegmentedProgress(info.step, cancelled, delivered),
                      const SizedBox(height: 10),

                      // Status Row with Fraction
                      Row(
                        children: [
                          Icon(
                            delivered
                                ? Icons.check_circle_rounded
                                : (cancelled ? Icons.cancel_rounded : Icons.schedule_rounded),
                            size: 17,
                            color: const Color(0xFF0B1F5B),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              info.description.isNotEmpty ? info.description : info.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1F5B),
                              ),
                            ),
                          ),
                          Text(
                            cancelled ? 'Cancelled' : '${(info.step + 1).clamp(1, 5)}/5',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F3274),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dashed Divider
                      CustomPaint(
                        size: const Size(double.infinity, 2),
                        painter: const DashedDividerPainter(
                          color: Color(0x470B1F5B),
                          strokeWidth: 2,
                          dashWidth: 6,
                          dashSpace: 4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Footer: Left Marker Price, Right When Pill
                      // Footer: Left Marker Price, Right When Pill (Fixed 9.3px overflow)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Left: Label + Marker Price
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0)
                                      ? 'Bill status'
                                      : (order.paymentMethod == 'cod' && !delivered
                                          ? 'To pay on delivery'
                                          : 'Total amount'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F3274),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _buildMarkerPrice(
                                  d.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0)
                                      ? 'Pending count'
                                      : '£${(order.transactionAmount != null && order.transactionAmount! > 0 ? order.transactionAmount! : total).toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right: When Pill (Collection or Delivery)
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: const Color(0xFF0B1F5B),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x5702104C),
                                      blurRadius: 14,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.arrow_upward_rounded,
                                          size: 14,
                                          color: Color(0xFF0B1F5B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      d.collectionDate != null
                                          ? '${d.collectionDate} · ${d.collectionTime ?? ""}'
                                          : 'Mon · 10:00 – 11:00',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Rotated Flag (-3 deg) at Top-Left
        Positioned(
          top: -12,
          left: 14,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF0B1F5B),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5902104C),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!delivered && !cancelled) ...[
                    const _PulsingFlagDot(),
                    const SizedBox(width: 7),
                  ] else if (delivered) ...[
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF7CFFB0), size: 13),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    info.label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating 3D Disc at Top-Right with Bobbing Animation (.ic @keyframes bob)
        Positioned(
          top: -18,
          right: 12,
          child: _FloatingBobbingDisc(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5702104C),
                    blurRadius: 18,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    _getServiceAsset(order),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Sparkle Star Decoration near 3D disc
        const Positioned(
          top: -8,
          right: 86,
          child: SparkleStarWidget(size: 14, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSegmentedProgress(int currentStep, bool cancelled, bool delivered) {
    return Row(
      children: List.generate(5, (index) {
        final isFilled = delivered || (index <= currentStep);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isFilled
                  ? const Color(0xFF0B1F5B)
                  : const Color(0x2E0B1F5B),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMarkerPrice(String price) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 2,
          height: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Text(
          price,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1F5B),
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ── 2. Order Journey Card (wc) ──────────────────────────────────────────────
  Widget _buildOrderJourneyCard(models.Order order, OrderStatusInfo info, bool delivered) {
    final step = delivered ? 4 : info.step;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFEEF3FF)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7F02104C),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Inner disc & ring
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x297BCBFB),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -46,
                  left: -46,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x33FFCB4F),
                        width: 15,
                      ),
                    ),
                  ),
                ),

                // Journey timeline
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 38, 18, 20),
                  child: Column(
                    children: List.generate(kOrderSteps.length, (i) {
                      final s = kOrderSteps[i];
                      final isDone = i < step || (delivered && i <= step);
                      final isCurrent = !delivered && i == step;
                      final isLast = i == kOrderSteps.length - 1;
                      final canTrack = isCurrent && isLiveOrderStatus(order.status) && !delivered;

                      return _JourneyTimelineTile(
                        title: isCurrent ? info.label : s.$1,
                        description: isCurrent && info.description.isNotEmpty ? info.description : s.$2,
                        icon: isCurrent ? info.icon : s.$3,
                        isDone: isDone,
                        isCurrent: isCurrent,
                        isLast: isLast,
                        onTrackDriver: canTrack
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => TrackDriverScreen(order: order)),
                                )
                            : null,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Rotated Flag (-3 deg) at Top-Left
        Positioned(
          top: -12,
          left: 14,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF0B1F5B),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5902104C),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'ORDER JOURNEY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Dedicated driver tracking card providing instant map access
  Widget _buildDriverTrackingActionCard(models.Order order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x7F02104C), blurRadius: 26, offset: Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1F5B), Color(0xFF1E3A8A)],
                  ),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFFFD44D), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Driver Tracking',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track driver location, ETA & vehicle live',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5B6F99),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TrackDriverScreen(order: order)),
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(
                'Open Live Driver Map',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B1F5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Color(0x5902104C), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEBEE),
            ),
            child: const Icon(Icons.cancel_rounded, color: Color(0xFFD32F2F), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1F5B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This order was cancelled. If you were charged, please contact customer support.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5B6F99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Collection & Delivery Card (oc sky) ──────────────────────────────────
  Widget _buildCollectionDeliveryCard(models.Order order) {
    final d = order.bookingData;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFBDEBFF), Color(0xFF7BCBFB)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7F02104C),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Inner disc & ring
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -46,
                  left: -46,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 15,
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
                  child: Column(
                    children: [
                      // 2 Slot Tiles side-by-side
                      Row(
                        children: [
                          // Collection Slot Tile
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.66),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0B1F5B),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 17),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'COLLECTION',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1F3274),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.collectionDate ?? 'Monday',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0B1F5B),
                                    ),
                                  ),
                                  Text(
                                    d.collectionTime ?? '10:00 – 11:00',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0B1F5B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Delivery Slot Tile
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.66),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0B1F5B),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 17),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'DELIVERY',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1F3274),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.deliveryDate ?? 'Thursday',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0B1F5B),
                                    ),
                                  ),
                                  Text(
                                    d.deliveryTime ?? '11:00 – 12:00',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0B1F5B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Address Tile
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withValues(alpha: 0.66),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFCB4F),
                              ),
                              child: const Center(
                                child: Icon(Icons.location_on_rounded, color: Color(0xFF0B1F5B), size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ADDRESS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1F3274),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    d.selectedAddress?.fullAddress ?? 'No address selected',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0B1F5B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Driver Note (if present)
                      if ((d.instructions ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: 0.66),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0B1F5B),
                                ),
                                child: const Center(
                                  child: Icon(Icons.sticky_note_2_rounded, color: Colors.white, size: 17),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DRIVER NOTE',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1F3274),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      d.instructions!.trim(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0B1F5B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Rotated Flag (-3 deg) at Top-Left
        Positioned(
          top: -12,
          left: 14,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF0B1F5B),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5902104C),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'COLLECTION & DELIVERY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. Items Card (oc pink) ─────────────────────────────────────────────────
  Widget _buildItemsCard(models.Order order) {
    final items = order.bookingData.selectedItems.values.toList();
    final isPrepaid = order.type == 'prepaid_pack';
    final count = isPrepaid ? 1 : items.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFC2C6), Color(0xFFFF8F99)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7F02104C),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Inner disc & ring
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -46,
                  left: -46,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 15,
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
                  child: Column(
                    children: [
                      if (isPrepaid) ...[
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/price_dryclean.png',
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.bookingData.prepaidPackName ?? 'Prepaid Pack',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0B1F5B),
                                    ),
                                  ),
                                  Text(
                                    'Prepaid Package',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F3274),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '£${(order.transactionAmount ?? order.bookingData.totalAmount).toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1F5B),
                              ),
                            ),
                          ],
                        ),
                      ] else if (items.isEmpty) ...[
                        Builder(builder: (context) {
                          final selectedServices = order.bookingData.selectedServices;
                          final services = selectedServices.isNotEmpty
                              ? selectedServices
                              : [
                                  order.bookingData.prepaidPackName ??
                                      (order.type == 'quick_bag' ? 'Standard Service' : 'Laundry & Dry Clean')
                                ];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < services.length; i++) ...[
                                if (i > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: CustomPaint(
                                      size: const Size(double.infinity, 2),
                                      painter: const DashedDividerPainter(
                                        color: Color(0x380B1F5B),
                                        strokeWidth: 2,
                                        dashWidth: 6,
                                        dashSpace: 4,
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          _getItemIcon(services[i]),
                                          width: 30,
                                          height: 30,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            services[i],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0B1F5B),
                                            ),
                                          ),
                                          Text(
                                            'Items counted at facility',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1F3274),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B1F5B),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'COUNTED AT FACILITY',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        }),
                      ] else ...[
                        for (int i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: CustomPaint(
                                size: const Size(double.infinity, 2),
                                painter: const DashedDividerPainter(
                                  color: Color(0x380B1F5B),
                                  strokeWidth: 2,
                                  dashWidth: 6,
                                  dashSpace: 4,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    _getItemIcon(items[i].category),
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      items[i].itemType,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0B1F5B),
                                      ),
                                    ),
                                    Text(
                                      items[i].category,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1F3274),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '£${items[i].numericPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0B1F5B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Rotated Flag (-3 deg) at Top-Left
        Positioned(
          top: -12,
          left: 14,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF0B1F5B),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5902104C),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isPrepaid
                      ? 'PREPAID PACK'
                      : (items.isEmpty
                          ? (order.bookingData.selectedServices.length > 1
                              ? 'SERVICES · ${order.bookingData.selectedServices.length}'
                              : 'SERVICE')
                          : 'ITEMS · $count'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getItemIcon(String category) {
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

  // ── 5. Payment Card (wc) ────────────────────────────────────────────────────
  Widget _buildPaymentCard(models.Order order, bool delivered) {
    final d = order.bookingData;
    final method = order.paymentMethod ?? d.paymentMethod;
    final isCod = method == 'cod';
    final total = order.transactionAmount ?? d.totalAmount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFEEF3FF)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7F02104C),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Inner disc & ring
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x297BCBFB),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -46,
                  left: -46,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x33FFCB4F),
                        width: 15,
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
                  child: Column(
                    children: [
                      // Method Pill on Right
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFF0B1F5B),
                          ),
                          child: Text(
                            isCod ? 'Pay on delivery' : 'Paid by card',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Items / Subtotal
                      if (d.selectedItems.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Itemized Garments & Services (${d.selectedItems.length})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...d.selectedItems.values.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.itemType,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                            if (item.category.isNotEmpty)
                                              Text(
                                                item.category,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        item.price,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        _buildPaymentLine('Subtotal', '£${d.subtotal.toStringAsFixed(2)}'),
                      ] else ...[
                        // Notice banner for items to be counted at facility
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'PRICE UPDATE PENDING',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Final bill will be calculated & updated once garments are itemized at our cleaning facility. You will receive an invoice update via Email and here in the app.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1B5E20),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildPaymentLine('Items & Cleaning', 'Counted at facility', isCountedAtFacility: true),
                      ],

                      if (d.discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildPaymentLine(
                          'Discount${d.discountCode != null && d.discountCode!.isNotEmpty ? ' (${d.discountCode})' : ''}',
                          '-£${d.discountAmount.toStringAsFixed(2)}',
                          isDiscount: true,
                        ),
                      ],
                      if (models.BookingData.serviceFeeEnabled && models.BookingData.serviceFee > 0) ...[
                        const SizedBox(height: 8),
                        _buildPaymentLine('Service fee', '£${models.BookingData.serviceFee.toStringAsFixed(2)}'),
                      ],
                      if (d.tipAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildPaymentLine('Driver tip', '£${d.tipAmount.toStringAsFixed(2)}'),
                      ],
                      if (models.BookingData.deliveryFeeEnabled && models.BookingData.deliveryFee > 0) ...[
                        const SizedBox(height: 8),
                        _buildPaymentLine('Delivery fee', '£${models.BookingData.deliveryFee.toStringAsFixed(2)}'),
                      ],
                      const SizedBox(height: 12),

                      // Dashed Divider
                      CustomPaint(
                        size: const Size(double.infinity, 2),
                        painter: const DashedDividerPainter(
                          color: Color(0x470B1F5B),
                          strokeWidth: 2,
                          dashWidth: 6,
                          dashSpace: 4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Total with Marker Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            d.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0)
                                ? 'Estimated Total'
                                : (isCod && !delivered ? 'To pay on\ndelivery' : 'Total'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1F5B),
                              height: 1.2,
                            ),
                          ),
                          _buildWhiteMarkerPrice(
                            d.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0)
                                ? 'Pending'
                                : '£${(order.transactionAmount != null && order.transactionAmount! > 0 ? order.transactionAmount! : total).toStringAsFixed(2)}',
                          ),
                        ],
                      ),

                      if (isCod && !delivered) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            d.selectedItems.isEmpty && (order.transactionAmount == null || order.transactionAmount == 0)
                                ? 'Final total will be approved after inspection at facility. Pay upon delivery.'
                                : 'Please keep this amount ready for the driver.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F3274),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Rotated Flag (-3 deg) at Top-Left
        Positioned(
          top: -12,
          left: 14,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF0B1F5B),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5902104C),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'PAYMENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentLine(String label, String value, {bool isDiscount = false, bool isFreePill = false, bool isCountedAtFacility = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F3274),
          ),
        ),
        if (isFreePill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFC9F78E),
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
        else if (isCountedAtFacility)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFDCFCE7),
            ),
            child: Text(
              'Counted at facility',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF15803D),
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDiscount ? const Color(0xFF0A5C36) : const Color(0xFF0B1F5B),
            ),
          ),
      ],
    );
  }

  Widget _buildWhiteMarkerPrice(String price) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 2,
          height: 10,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFE58C),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Text(
          price,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1F5B),
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ── 6. Need Help Button ─────────────────────────────────────────────────────
  Widget _buildNeedHelpButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/faq'),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.5,
          ),
          color: Colors.white.withValues(alpha: 0.16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'NEED HELP?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 7. Cancel Order Feature ─────────────────────────────────────────────────
  Widget _buildCancelOrderButton(models.Order order) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: FilledButton.icon(
        onPressed: () => _handleCancelOrderTap(order),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626), // Strong Red
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.cancel_outlined, size: 20, color: Colors.white),
        label: Text(
          'Cancel this order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  bool _canCancelOrder(models.Order order) {
    final status = normalizeOrderStatus(order.status);
    if (const {'collected', 'cleaning', 'ready_for_delivery', 'out_for_delivery', 'delivery_arrived', 'delivered', 'cancelled'}.contains(status)) {
      return false;
    }
    if (isLiveOrderStatus(order.status)) {
      return false;
    }

    final collectionDateStr = (order.bookingData.collectionDate ?? '').trim();
    final collectionTimeStr = (order.bookingData.collectionTime ?? '').trim();
    if (collectionDateStr.isEmpty) {
      return DateTime.now().difference(order.createdAt).inHours < 2;
    }

    try {
      const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final targetIdx = days.indexOf(collectionDateStr.toLowerCase());
      final now = DateTime.now();
      DateTime colDate = now;
      if (targetIdx >= 0) {
        final currentIdx = now.weekday - 1;
        int diff = targetIdx - currentIdx;
        if (diff < 0) diff += 7;
        colDate = now.add(Duration(days: diff));
      }

      int startHour = 9;
      final timeParts = collectionTimeStr.split('-');
      if (timeParts.isNotEmpty) {
        final startPart = timeParts.first.trim().split(':');
        if (startPart.isNotEmpty) {
          startHour = int.tryParse(startPart.first.trim()) ?? 9;
        }
      }

      final collectionSlotStart = DateTime(colDate.year, colDate.month, colDate.day, startHour);
      final cutoff = collectionSlotStart.subtract(const Duration(hours: 2));

      // Free cancellation up to 2 hours before collection
      if (now.isBefore(cutoff)) {
        return true;
      }
      // Grace period: within 15 minutes of booking
      if (now.difference(order.createdAt).inMinutes <= 15) {
        return true;
      }
      return false;
    } catch (_) {
      return DateTime.now().difference(order.createdAt).inHours < 2;
    }
  }

  void _handleCancelOrderTap(models.Order order) {
    final canCancel = _canCancelOrder(order);

    if (canCancel) {
      _showCancelModal(order);
    } else {
      _showWindowClosedModal(order);
    }
  }

  void _showWindowClosedModal(models.Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DEF5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFEA580C), size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cancellation window closed',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0B1F5B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders can be cancelled free of charge up to 2 hours before the scheduled collection slot. Since your collection slot is starting soon or your order is already being processed, please contact our support team directly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5B6B9A),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:01636918181')),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                label: Text(
                  'Call Support (01636 918181)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F5B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://wa.me/441636918181')),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  'WhatsApp Support',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0B1F5B),
                  side: const BorderSide(color: Color(0xFFCBD6F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelModal(models.Order order) {
    String selectedReason = 'Change of plans';
    final reasons = [
      'Change of plans',
      'Wrong collection date/time',
      'Need to modify items or services',
      'Booked by mistake',
      'Other reason',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DEF5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel order #${order.orderId}?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1F5B),
                          ),
                        ),
                        Text(
                          'Free cancellation (2h before pickup window)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Please select a reason:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F3274),
                ),
              ),
              const SizedBox(height: 10),
              for (final r in reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setSheetState(() => selectedReason = r),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedReason == r ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedReason == r ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          width: selectedReason == r ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == r
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 18,
                            color: selectedReason == r ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: selectedReason == r ? FontWeight.w700 : FontWeight.w500,
                                color: selectedReason == r ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    await _executeCancellation(order, selectedReason);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Confirm Cancellation',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(
                    'Keep Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5B6B9A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeCancellation(models.Order order, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
      });

      // Cleanup any live tracking doc
      try {
        await FirebaseFirestore.instance.collection('live_tracking').doc(order.orderId).delete();
      } catch (_) {}

      setState(() {
        _currentOrder = _currentOrder.copyWith(status: 'cancelled');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order #${order.orderId} was cancelled successfully.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Journey Timeline Step Widget
// ─────────────────────────────────────────────────────────────────────────────
class _JourneyTimelineTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final VoidCallback? onTrackDriver;

  const _JourneyTimelineTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.onTrackDriver,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left circle & line
          SizedBox(
            width: 46,
            child: Column(
              children: [
                _buildCircle(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF0B1F5B) : const Color(0xFFCBD6F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 22, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: (isDone || isCurrent)
                              ? const Color(0xFF0B1F5B)
                              : const Color(0xFF4D5F96),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFFFFE58C),
                          ),
                          child: Text(
                            'NOW',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1F5B),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (isDone || isCurrent)
                          ? const Color(0xFF1F3274)
                          : const Color(0xFF5F6F9E),
                    ),
                  ),
                  if (onTrackDriver != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onTrackDriver,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B1F5B), Color(0xFF1E3A8A)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x330B1F5B), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.navigation_rounded, color: Color(0xFFFFD44D), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Track driver live',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle() {
    if (isDone) {
      return Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0B1F5B),
        ),
        child: const Center(
          child: Icon(Icons.check_rounded, color: Colors.white, size: 22),
        ),
      );
    }
    if (isCurrent) {
      return _PulsingTimelineStepCircle(icon: icon);
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEEF3FF),
        border: Border.all(
          color: const Color(0xFFB7C4EA),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(icon, color: const Color(0xFF5F6F9E), size: 22),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Interactive Animations for Track Order Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Animated pulsing dot inside the status flag (.flag .pl @keyframes ping)
class _PulsingFlagDot extends StatefulWidget {
  const _PulsingFlagDot();

  @override
  State<_PulsingFlagDot> createState() => _PulsingFlagDotState();
}

class _PulsingFlagDotState extends State<_PulsingFlagDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pingController;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pingController,
      builder: (context, _) {
        final val = _pingController.value;
        final spread = val * 8.0;
        final opacity = (1.0 - val).clamp(0.0, 1.0) * 0.75;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFD25E),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD25E).withValues(alpha: opacity),
                spreadRadius: spread,
                blurRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Floating 3D disc bobbing smoothly up and down (.ic @keyframes bob)
class _FloatingBobbingDisc extends StatefulWidget {
  final Widget child;

  const _FloatingBobbingDisc({required this.child});

  @override
  State<_FloatingBobbingDisc> createState() => _FloatingBobbingDiscState();
}

class _FloatingBobbingDiscState extends State<_FloatingBobbingDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bobController;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat();
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bobController,
      builder: (context, _) {
        final progress = math.sin(_bobController.value * 2 * math.pi);
        final dy = -5.0 * (progress * 0.5 + 0.5);
        final angle = (7.0 + 3.0 * (progress * 0.5 + 0.5)) * math.pi / 180;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Active timeline step circle with continuous expanding wave shadow (.cur .b @keyframes pulse)
class _PulsingTimelineStepCircle extends StatefulWidget {
  final IconData icon;

  const _PulsingTimelineStepCircle({required this.icon});

  @override
  State<_PulsingTimelineStepCircle> createState() =>
      _PulsingTimelineStepCircleState();
}

class _PulsingTimelineStepCircleState extends State<_PulsingTimelineStepCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final val = _pulseController.value;
        final spread = val * 12.0;
        final opacity = (1.0 - val).clamp(0.0, 1.0) * 0.35;

        return Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFCB4F),
            border: Border.all(color: const Color(0xFF0B1F5B), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F5B).withValues(alpha: opacity),
                spreadRadius: spread,
                blurRadius: 4,
              ),
              const BoxShadow(
                color: Color(0x330B1F5B),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(widget.icon, color: const Color(0xFF0B1F5B), size: 22),
          ),
        );
      },
    );
  }
}
