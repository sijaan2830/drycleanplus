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

  static const _navyDark = Color(0xFF0A1D4E);
  static const _navyMid = Color(0xFF143C8C);
  static const _royalBlue = Color(0xFF1C61E4);
  static const _emerald = Color(0xFF0E5A3E);
  static const _mint = Color(0xFF22C55E);
  static const _gold = Color(0xFFFFC73A);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _canvas = Color(0xFFF4F7FB);

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
        margin: const EdgeInsets.fromLTRB(12, 40, 12, 16),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B3224), Color(0xFF13523B)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _mint.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: _mint.withValues(alpha: 0.6), width: 2),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: _gold, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reward Unlocked!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _money(reward.creditEarned),
                  style: GoogleFonts.plusJakartaSans(fontSize: 42, fontWeight: FontWeight.w900, color: _gold, height: 1.05),
                ),
                const SizedBox(height: 4),
                Text(
                  'Free Cleaning Credit Added to Your Pass',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ROUND ${reward.round} QUALIFYING ORDERS',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: _muted, letterSpacing: 0.6)),
                      const SizedBox(height: 10),
                      for (final o in reward.orders)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '#${o.orderId} · ${_shortDate(o.date)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _ink, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(_money(o.paidAmount), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                            ],
                          ),
                        ),
                      const Divider(height: 18, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total paid across 5 orders', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: _muted)),
                          Text(_money(reward.totalSpent), style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Average credit (${_money(reward.totalSpent)} ÷ 5)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _emerald)),
                            Text(_money(reward.creditEarned), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: _emerald)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _tabIndex = 1);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _navyDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('View & Redeem Credit', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Back to Loyalty Pass', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
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
    final fullName = user.fullName.isNotEmpty
        ? user.fullName
        : (user.firstName.isNotEmpty ? user.firstName : 'Valued Customer');

    if (lp.hasUncelebratedReward && !_shownAutoPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUnlockSheet());
    }

    return Scaffold(
      backgroundColor: _canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Sapphire Header + Digital Wallet Pass ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2874F0), _royalBlue, _navyDark],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        children: [
                          // Top Bar
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Loyalty Card',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  'PASS #${lp.cardNumber}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Wallet Pass Card
                          _buildWalletPassCard(lp, fullName),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Segmented Pill Switcher & Active Tab Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSegmentedTabs(),
                      const SizedBox(height: 18),
                      if (_tabIndex == 0)
                        _buildOverviewTab(lp)
                      else if (_tabIndex == 1)
                        _buildRewardsTab(lp)
                      else
                        _buildHowItWorksTab(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Luxury dark-navy / obsidian wallet card — completely overflow-safe at any phone width.
  Widget _buildWalletPassCard(LoyaltyProvider lp, String fullName) {
    final bool hasCredit = lp.availableCredit > 0;
    final int count = lp.currentCount.clamp(0, 5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1638), Color(0xFF0F2D5E), Color(0xFF0E4335)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand row
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.satisfy(fontSize: 21, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
                  children: const [
                    TextSpan(text: 'Dryclean', style: TextStyle(color: Color(0xFF4ADE80))),
                    TextSpan(text: 'Plus+', style: TextStyle(color: Color(0xFFF87171))),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _gold.withValues(alpha: 0.45)),
                ),
                child: Text(
                  'ROUND ${lp.activeRound}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Big Progress Stat Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count of 5 orders',
                      style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0
                          ? 'Complete 5 paid orders for free average credit'
                          : '${lp.ordersRemaining} more order${lp.ordersRemaining == 1 ? '' : 's'} to unlock reward',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Free Credit', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white60)),
                  Text(
                    _money(lp.availableCredit),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: hasCredit ? const Color(0xFF4ADE80) : Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Clean 5-Node Progress Rail + Bonus Star
          Row(
            children: [
              for (int i = 0; i < 5; i++) ...[
                Expanded(
                  child: _PassNode(
                    step: i + 1,
                    done: i < count,
                    active: i == count,
                  ),
                ),
                if (i < 4)
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 2.5,
                      color: i < count - 1
                          ? const Color(0xFF4ADE80)
                          : Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
              ],
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _gold,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 10)],
                ),
                child: const Icon(Icons.card_giftcard_rounded, size: 17, color: _navyDark),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Sleek Glass Summary Strip inside Wallet Pass
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CARDHOLDER', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.6)),
                      const SizedBox(height: 2),
                      Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.16)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('NEXT CREDIT BUILDING', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(_money(lp.nextRewardBuilding), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: _gold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    const labels = ['My Card', 'Rewards', 'How It Works'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _tabIndex == i ? _navyDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _tabIndex == i ? Colors.white : _muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 0: Clean 5-Step Stamp Timeline + Live Building Metrics ──────────────
  Widget _buildOverviewTab(LoyaltyProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Metrics Row (Spent & Average)
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Spent this round',
                value: _money(lp.currentTotalPaid),
                sub: 'Adds 20p per £1 spent',
                icon: Icons.payments_outlined,
                accent: _royalBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Avg. order value',
                value: _money(lp.averageOrderSoFar),
                sub: '${lp.currentCount} qualifying order${lp.currentCount == 1 ? '' : 's'}',
                icon: Icons.trending_up_rounded,
                accent: _emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 5-Step Clean Stamp Tracker Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Round ${lp.activeRound} Stamps', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  Text('${lp.currentCount}/5 Complete', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: _royalBlue)),
                ],
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < 5; i++) ...[
                _StampTimelineRow(
                  step: i + 1,
                  entry: i < lp.currentRoundOrders.length ? lp.currentRoundOrders[i] : null,
                  isNext: i == lp.currentRoundOrders.length,
                  money: _money,
                  shortDate: _shortDate,
                ),
                if (i < 4) const Divider(height: 18, color: Color(0xFFF1F5F9)),
              ],
              const Divider(height: 22, color: Color(0xFFE2E8F0)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: _emerald, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '5th order reward (${_money(lp.currentTotalPaid)} ÷ 5)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _emerald),
                      ),
                    ),
                    Text(
                      _money(lp.nextRewardBuilding),
                      style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w900, color: _emerald),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Available Credit Callout
        if (lp.availableCredit > 0)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0E3E2C), Color(0xFF17664B)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Cleaning Credit Ready', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(_money(lp.availableCredit), style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: _gold)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => setState(() => _tabIndex = 1),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _emerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Redeem', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Tab 1: Rewards & History ───────────────────────────────────────────────
  Widget _buildRewardsTab(LoyaltyProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E3E2C), Color(0xFF155E44)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: const Color(0xFF0E3E2C).withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Available Free Credit', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                  const Icon(Icons.verified_rounded, color: _gold, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(_money(lp.availableCredit), style: GoogleFonts.plusJakartaSans(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                lp.rewardHistory.isNotEmpty
                    ? 'Latest unlocked: Round ${lp.rewardHistory.first.round} on ${_fullDate(lp.rewardHistory.first.unlockedAt)}'
                    : 'Reach 5 completed & paid orders to unlock credit automatically',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70),
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
                    backgroundColor: _gold,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: _navyDark,
                    disabledForegroundColor: Colors.white60,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    lp.availableCredit > 0 ? 'Apply at Checkout on Next Order' : 'No Credit Available Yet',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('Reward History', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 10),
        if (lp.rewardHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                  child: const Icon(Icons.history_rounded, color: _royalBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Your completed 5-order rounds and earned free credit will appear here automatically.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _muted, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          for (final rec in lp.rewardHistory) _buildHistoryTile(rec),
      ],
    );
  }

  Widget _buildHistoryTile(LoyaltyRewardRecord rec) {
    final expanded = _expandedRounds.contains(rec.round);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard_rounded, color: _emerald, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Round ${rec.round} Reward', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
                    Text('${_shortDate(rec.unlockedAt)} · 5 orders · ${_money(rec.totalSpent)} paid', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
              Text('+${_money(rec.creditEarned)}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: _emerald)),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedRounds.remove(rec.round);
                } else {
                  _expandedRounds.add(rec.round);
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(
                expanded ? 'Hide 5 orders' : 'Show the 5 qualifying orders',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _royalBlue),
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            for (final o in rec.orders)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${o.orderId} · ${_shortDate(o.date)}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _muted)),
                    Text(_money(o.paidAmount), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_money(rec.totalSpent)} ÷ 5', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: _emerald)),
                Text('${_money(rec.creditEarned)} credit', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: _emerald)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 2: How It Works ────────────────────────────────────────────────────
  Widget _buildHowItWorksTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _guideStep(1, 'Order as usual', 'Each completed and paid order counts automatically toward your loyalty card.'),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),
              _guideStep(2, 'Collect 5 qualifying orders', 'Watch your live card fill up order by order in real time.'),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),
              _guideStep(3, 'Get the average FREE', 'Receive free cleaning credit equal to the average spend of all 5 orders.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_navyDark, _navyMid]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text('EXAMPLE', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('Spend £150 across 5 paid orders', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Text('£150 ÷ 5 = £30.00 FREE', style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w900, color: _gold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What Counts', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 12),
              _ruleRow(true, 'Orders that are both completed (delivered) and paid'),
              const SizedBox(height: 10),
              _ruleRow(true, 'Only the amount you pay yourself'),
              const SizedBox(height: 10),
              _ruleRow(false, 'Cancelled or unpaid orders do not count'),
              const SizedBox(height: 10),
              _ruleRow(false, 'Any portion paid using free credit does not count'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guideStep(int n, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: _navyDark, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$n', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _gold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 2),
              Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _muted, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ruleRow(bool ok, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: ok ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, size: 14, color: ok ? _emerald : _muted),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _ink))),
      ],
    );
  }
}

class _PassNode extends StatelessWidget {
  final int step;
  final bool done;
  final bool active;
  const _PassNode({required this.step, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: done
              ? const Color(0xFF22C55E)
              : active
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: done
                ? const Color(0xFF4ADE80)
                : active
                    ? const Color(0xFFFFC73A)
                    : Colors.white.withValues(alpha: 0.25),
            width: active ? 2 : 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                '$step',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? const Color(0xFFFFC73A) : Colors.white70,
                ),
              ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color accent;
  const _MetricTile({required this.label, required this.value, required this.sub, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _StampTimelineRow extends StatelessWidget {
  final int step;
  final LoyaltyOrderEntry? entry;
  final bool isNext;
  final String Function(double) money;
  final String Function(DateTime) shortDate;

  const _StampTimelineRow({
    required this.step,
    required this.entry,
    required this.isNext,
    required this.money,
    required this.shortDate,
  });

  @override
  Widget build(BuildContext context) {
    final done = entry != null;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFFDCFCE7)
                : isNext
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(
              color: done
                  ? const Color(0xFF22C55E)
                  : isNext
                      ? const Color(0xFF1C61E4)
                      : const Color(0xFFE2E8F0),
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF0E5A3E))
              : Text(
                  '$step',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isNext ? const Color(0xFF1C61E4) : const Color(0xFF94A3B8),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                done
                    ? 'Order #${entry!.orderId}'
                    : (isNext ? 'Order $step · Up next' : 'Order $step'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: done || isNext ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                done
                    ? '${shortDate(entry!.date)} · Completed & paid'
                    : (isNext ? 'Completed & paid orders count here' : 'Pending future order'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (done)
          Text(
            money(entry!.paidAmount),
            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w900, color: const Color(0xFF0E5A3E)),
          ),
      ],
    );
  }
}
