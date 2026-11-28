import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/loyalty_provider.dart';
import '../providers/user_provider.dart';

class LoyaltyScreen extends StatefulWidget {
  final int initialTab;
  const LoyaltyScreen({super.key, this.initialTab = 0});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  late int _tabIndex;
  final Set<int> _expandedRounds = {};
  bool _shownAutoPopup = false;

  static const _skyA = Color(0xFF4CC3F4);
  static const _skyB = Color(0xFF2AA7E1);
  static const _forestA = Color(0xFF0E3E2C);
  static const _forestB = Color(0xFF17553E);
  static const _lime = Color(0xFF7FD13B);
  static const _ink = Color(0xFF0A2433);
  static const _navy = Color(0xFF0B2A6B);

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUnlockSheet());
  }

  void _maybeShowUnlockSheet() {
    if (!mounted || _shownAutoPopup) return;
    final lp = context.read<LoyaltyProvider>();
    if (lp.hasUncelebratedReward && lp.lastUnlockedReward != null) {
      _shownAutoPopup = true;
      _showRewardUnlockedModal(lp.lastUnlockedReward!, markCelebrated: true);
    }
  }

  String _money(double v) => '£${v.toStringAsFixed(2)}';
  String _shortDate(DateTime d) => DateFormat('d MMM').format(d);
  String _fullDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

  void _showRewardUnlockedModal(LoyaltyRewardRecord reward, {bool markCelebrated = false}) {
    if (markCelebrated) {
      context.read<LoyaltyProvider>().markRewardCelebrated(reward.round);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 36, 12, 16),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_forestA, _forestB],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12))],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(color: _lime, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _lime.withValues(alpha: 0.4), blurRadius: 18)]),
                  child: const Icon(Icons.card_giftcard_rounded, color: _forestA, size: 34),
                ),
                const SizedBox(height: 16),
                Text('Reward unlocked!', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  _money(reward.creditEarned),
                  style: GoogleFonts.plusJakartaSans(fontSize: 44, fontWeight: FontWeight.w900, color: _lime, height: 1.05),
                ),
                const SizedBox(height: 4),
                Text('free cleaning credit', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your 5 orders', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
                      const SizedBox(height: 10),
                      for (final o in reward.orders)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '#${o.orderId} · ${_shortDate(o.date)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(_money(o.paidAmount), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                            ],
                          ),
                        ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total paid', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                          Text(_money(reward.totalSpent), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_money(reward.totalSpent)} ÷ 5', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _forestA)),
                            Text(_money(reward.creditEarned), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: _forestA)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _tabIndex = 1);
                    },
                    style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: _forestA, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text('See my rewards', style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Back to my card', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LoyaltyProvider>();
    final user = context.watch<UserProvider>();
    final customerName = user.fullName.isNotEmpty
        ? user.fullName
        : (user.firstName.isNotEmpty ? user.firstName : 'Valued Customer');

    if (lp.hasUncelebratedReward && !_shownAutoPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUnlockSheet());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _BrandLogoPill(compact: true),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(999)),
              child: Text('Card ${lp.cardNumber}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: _navy)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _tabIndex == 0
                      ? _buildMyCardTab(lp, customerName, user.firstName)
                      : _tabIndex == 1
                          ? _buildRewardsTab(lp)
                          : _buildHowItWorksTab(),
                ),
              ),
            ),
          ),
          _buildBottomSwitcher(),
        ],
      ),
    );
  }

  Widget _buildMyCardTab(LoyaltyProvider lp, String fullName, String firstName) {
    final displayFirst = firstName.trim().isNotEmpty ? firstName.trim() : 'there';
    final left = lp.ordersRemaining;

    // Combine current round orders + recent orders from completed rounds (newest first)
    final recentOrders = <LoyaltyOrderEntry>[
      ...lp.currentRoundOrders.reversed,
      for (final r in lp.rewardHistory) ...r.orders.reversed,
    ].take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            left == 5 && lp.availableCredit > 0
                ? 'Hi $displayFirst, your free credit is ready!'
                : 'Hi $displayFirst, $left order${left == 1 ? '' : 's'} to go',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.4),
          ),
        ),

        // ── Main Digital Loyalty Card ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_skyA, _skyB]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _skyB.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${lp.currentCount} of 5 orders', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(999)),
                    child: Text('Round ${lp.activeRound}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: _ink)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Complete 5 orders, get the average FREE!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w900, color: _ink),
              ),
              const SizedBox(height: 14),

              // 5 stamp circles + 6th FREE gift circle (responsive grid / wrap)
              Row(
                children: [
                  for (int i = 0; i < 5; i++) ...[
                    Expanded(
                      child: _buildStampCircle(
                        index: i + 1,
                        entry: i < lp.currentRoundOrders.length ? lp.currentRoundOrders[i] : null,
                        isNext: i == lp.currentRoundOrders.length,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: _buildFreeGiftCircle()),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${lp.currentCount} of 5 orders done. Just $left more to unlock your free credit.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 14),

              // White Card Summary Strip (matching example)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Card No', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text(lp.cardNumber, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Next reward building', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              Text(_money(lp.nextRewardBuilding), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: _forestA)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Free credit ready', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _forestA)),
                          Text(_money(lp.availableCredit), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: _forestA)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Completed and paid orders count', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: _ink.withValues(alpha: 0.78))),
                  Text('Thank you for your business!', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: _ink.withValues(alpha: 0.78))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Next reward so far Card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Next reward so far', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                  Text(_money(lp.nextRewardBuilding), style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lp.currentCount == 0
                    ? 'Complete your next paid order to start building credit. Every £1 you pay adds 20p.'
                    : '${_money(lp.currentTotalPaid)} spent across ${lp.currentCount} order${lp.currentCount == 1 ? '' : 's'}. Every £1 you pay adds 20p. Your average order is ${_money(lp.averageOrderSoFar)}.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Free credit ready to use Banner ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_forestA, _forestB]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free credit ready to use', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(_money(lp.availableCredit), style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => setState(() => _tabIndex = 1),
                style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: _forestA, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('View', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Recent qualifying orders ─────────────────────────────────────────────
        Text('Recent qualifying orders', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 8),
        if (recentOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text(
              'No completed and paid orders counted yet. Once an order is delivered and marked as paid, your stamp appears here live.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.45),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                for (int i = 0; i < recentOrders.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    dense: true,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 18, color: _forestA),
                    ),
                    title: Text('Order #${recentOrders[i].orderId}', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
                    subtitle: Text('${_shortDate(recentOrders[i].date)} · Completed, paid', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                    trailing: Text(_money(recentOrders[i].paidAmount), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _forestA)),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStampCircle({required int index, LoyaltyOrderEntry? entry, required bool isNext}) {
    final done = entry != null;
    return AspectRatio(
      aspectRatio: 0.78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _forestA, width: 1.5),
            ),
            child: done
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(color: _lime, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 12, color: _forestA),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_money(entry.paidAmount), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: _forestA)),
                      ),
                      Text(_shortDate(entry.date), style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_laundry_service_outlined, size: 20, color: _skyB),
                      const SizedBox(height: 3),
                      Text(
                        isNext ? 'Next\norder' : 'Order\n$index',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 8.5, height: 1.15, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
          ),
          Positioned(
            top: -5,
            left: -3,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(color: _forestA, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$index', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeGiftCircle() {
    return AspectRatio(
      aspectRatio: 0.78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _forestA, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 20, color: _forestA),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Text('FREE', style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.w900, color: _forestA)),
                ),
              ],
            ),
          ),
          Positioned(
            top: -5,
            left: -3,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(color: _forestA, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.star_rounded, size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: My rewards ──────────────────────────────────────────────────────
  Widget _buildRewardsTab(LoyaltyProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('My rewards', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 12),

        // Available free credit hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_forestA, _forestB]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available free credit', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(_money(lp.availableCredit), style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                lp.rewardHistory.isNotEmpty
                    ? 'From Round ${lp.rewardHistory.first.round} · earned ${_fullDate(lp.rewardHistory.first.unlockedAt)}'
                    : 'Complete 5 orders to unlock your first reward',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: lp.availableCredit > 0
                      ? () {
                          lp.setUseCreditInCheckout(true);
                          Navigator.of(context).pushNamed('/service_selection');
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.25),
                    foregroundColor: _forestA,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    lp.availableCredit > 0
                        ? 'Choose it at checkout on your next order'
                        : 'Unlock free credit after 5 orders',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Active Round Building Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_skyA, _skyB]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Round ${lp.activeRound} reward', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                      Text('${lp.currentCount} of 5 orders · ${lp.ordersRemaining} to go', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _ink.withValues(alpha: 0.8))),
                    ],
                  ),
                  Text(_money(lp.nextRewardBuilding), style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 0; i < 5; i++) ...[
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: i < lp.currentCount ? _navy : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    if (i < 4) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Unlocks when order 5 is completed and paid. The amount grows with each order.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: _ink.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('Reward history', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 8),
        if (lp.rewardHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text('No unlocked rewards yet. After your 5th qualifying order, your average credit will appear here.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B))),
          )
        else
          for (final rec in lp.rewardHistory) _buildRewardHistoryCard(rec),
      ],
    );
  }

  Widget _buildRewardHistoryCard(LoyaltyRewardRecord rec) {
    final expanded = _expandedRounds.contains(rec.round);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Round ${rec.round} reward', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 2),
                  Text('${_shortDate(rec.unlockedAt)} · 5 orders · ${_money(rec.totalSpent)} paid', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${_money(rec.creditEarned)}', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: _forestA)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(999)),
                    child: Text('Unlocked', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: _forestA)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              setState(() {
                if (expanded) {
                  _expandedRounds.remove(rec.round);
                } else {
                  _expandedRounds.add(rec.round);
                }
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(expanded ? 'Hide the 5 orders' : 'Show the 5 orders', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            for (final o in rec.orders)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${o.orderId} · ${_shortDate(o.date)}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569))),
                    Text(_money(o.paidAmount), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_money(rec.totalSpent)} ÷ 5 orders', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _forestA)),
                Text('${_money(rec.creditEarned)} credit', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: _forestA)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 3: How it works ────────────────────────────────────────────────────
  Widget _buildHowItWorksTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How it works', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: [
              _stepRow(1, 'Order as usual', 'Each completed and paid order is added to your card automatically.'),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),
              _stepRow(2, 'Reach 5 orders', 'Watch your progress and reward grow live in the app.'),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),
              _stepRow(3, 'Get free credit', 'You receive the average value of those 5 orders. Then a new round starts.'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Example card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_skyA, _skyB]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text('Example', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 4),
              Text('You spend £150 across 5 orders', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(999)),
                child: Text('£150 ÷ 5 = £30', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Text('£30.00 free cleaning credit', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('What counts', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: [
              _ruleRow(true, 'Orders that are both completed and paid'),
              const SizedBox(height: 10),
              _ruleRow(true, 'The amount you pay yourself'),
              const SizedBox(height: 10),
              _ruleRow(false, 'Cancelled or refunded orders do not count'),
              const SizedBox(height: 10),
              _ruleRow(false, 'Any part paid with free credit does not count'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRow(int num, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: _forestA, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$num', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.4, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ruleRow(bool allowed, String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: allowed ? _lime : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Icon(allowed ? Icons.check_rounded : Icons.close_rounded, size: 14, color: allowed ? _forestA : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSwitcher() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _tabBtn(0, Icons.credit_card_rounded, 'My card'),
              _tabBtn(1, Icons.card_giftcard_rounded, 'Rewards'),
              _tabBtn(2, Icons.help_outline_rounded, 'How it works'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(int idx, IconData icon, String label) {
    final active = _tabIndex == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = idx),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDCFCE7) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: active ? _forestA : const Color(0xFF64748B)),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? _forestA : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogoPill extends StatelessWidget {
  final bool compact;
  const _BrandLogoPill({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0E3E2C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'DC', style: GoogleFonts.plusJakartaSans(fontSize: compact ? 13 : 15, fontWeight: FontWeight.w900, color: Colors.white)),
                TextSpan(text: '+', style: GoogleFonts.plusJakartaSans(fontSize: compact ? 13 : 15, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('DrycleanPlus', style: GoogleFonts.plusJakartaSans(fontSize: compact ? 16 : 18, fontWeight: FontWeight.w800, color: const Color(0xFF0E3E2C))),
      ],
    );
  }
}
