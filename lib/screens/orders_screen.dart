import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/booking_models.dart' as models;
import '../providers/booking_provider.dart';
import '../utils/order_status.dart';
import '../widgets/order_card_widget.dart';
import 'track_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTab = 0; // 0 = Active, 1 = Completed (last 24h)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<BookingProvider>(context, listen: false).initializeListeners();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _openTrack(models.Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackOrderScreen(order: order),
        settings: const RouteSettings(name: '/track_order'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1245B5),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.bgGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Soft background ambient circles from HTML (.wrap::before, .wrap::after)
                Positioned(
                  right: -150,
                  top: -140,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  left: -230,
                  top: 720,
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _isLoading
                          ? const _SkeletonList()
                          : Consumer<BookingProvider>(
                              builder: (context, provider, _) {
                                final orders = provider.orders;
                                final active = orders
                                    .where((o) => !isOrderDelivered(o.status))
                                    .toList();
                                final cutoff = DateTime.now().subtract(const Duration(hours: 24));
                                final completed = orders.where((o) {
                                  if (!isOrderDelivered(o.status)) return false;
                                  final date = o.deliveredAt ?? o.updatedAt ?? o.createdAt;
                                  return date.isAfter(cutoff);
                                }).toList();

                                final shown = _selectedTab == 0 ? active : completed;

                                return RefreshIndicator(
                                  color: const Color(0xFF0B1F5B),
                                  backgroundColor: Colors.white,
                                  onRefresh: () async {
                                    provider.initializeListeners();
                                    await Future.delayed(const Duration(milliseconds: 500));
                                  },
                                  child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                                    children: [
                                      Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 480),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              _Tabs(
                                                selected: _selectedTab,
                                                activeCount: active.length,
                                                completedCount: completed.length,
                                                onChanged: (i) => setState(() => _selectedTab = i),
                                              ),
                                              const SizedBox(height: 28),
                                              if (shown.isEmpty)
                                                _EmptyState(
                                                  isActiveTab: _selectedTab == 0,
                                                  onStart: () => Navigator.of(context).pushNamed('/home'),
                                                )
                                              else ...[
                                                ...shown.map(
                                                  (o) => OrderCardWidget(
                                                    order: o,
                                                    onTrack: () => _openTrack(o),
                                                    onReorder: () => Navigator.of(context).pushNamed('/home'),
                                                  ),
                                                ),
                                                if (_selectedTab == 1 && completed.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Delivered orders stay here for 24 hours.',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFFDDE8FF),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header (44x44 Circular Glass Back Button + Title) ──────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/more');
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'My Orders',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Capsule Tab Switcher (.tabs)
// ─────────────────────────────────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  final int selected;
  final int activeCount;
  final int completedCount;
  final ValueChanged<int> onChanged;

  const _Tabs({
    required this.selected,
    required this.activeCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
      ),
      child: Row(
        children: [
          _tab(0, 'Active', activeCount),
          const SizedBox(width: 4),
          _tab(1, 'Completed', completedCount),
        ],
      ),
    );
  }

  Widget _tab(int index, String label, int count) {
    final on = selected == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: const Color(0xFF02104C).withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: on ? const Color(0xFF0B1F5B) : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                constraints: const BoxConstraints(minWidth: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? const Color(0xFFFFD25E) : Colors.white.withOpacity(0.24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: on ? const Color(0xFF0B1F5B) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isActiveTab;
  final VoidCallback onStart;
  const _EmptyState({required this.isActiveTab, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
            ),
            child: Icon(
              isActiveTab ? Icons.receipt_long_rounded : Icons.check_circle_outline_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isActiveTab ? 'No active orders' : 'No completed orders',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isActiveTab
                ? 'Your active orders will appear here.'
                : 'Orders delivered in the last 24 hours will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.4,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          if (isActiveTab) ...[
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onStart,
              child: Container(
                width: 220,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD25E),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF02104C).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Color(0xFF0B1F5B), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'START AN ORDER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF0B1F5B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton List Loader
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final o = 0.08 + 0.1 * _c.value;
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(o),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 28),
            ...List.generate(
              2,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 24),
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(o),
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
