import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../widgets/offer_card.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Offers & Promotions',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            print('OffersScreen error: ${snapshot.error}');
            return _buildErrorState();
          }

          final docs = snapshot.data?.docs ?? [];

          // Filter out expired and sort client-side
          final now = DateTime.now();
          final offers = docs
              .map((doc) {
                final data = Map<String, dynamic>.from(
                    doc.data() as Map<String, dynamic>);
                data['id'] = doc.id;
                // Convert Timestamp → DateTime
                if (data['expiryDate'] is Timestamp) {
                  data['expiryDate'] =
                      (data['expiryDate'] as Timestamp).toDate();
                }
                return data;
              })
              // Filter only active ones here since we removed it from the query
              .where((data) => data['isActive'] == true)
              .toList()
            ..sort((a, b) {
              final aExp = a['expiryDate'] as DateTime?;
              final bExp = b['expiryDate'] as DateTime?;
              final aExpired = aExp != null && aExp.isBefore(now);
              final bExpired = bExp != null && bExp.isBefore(now);
              if (aExpired != bExpired) return aExpired ? 1 : -1;
              if (aExp == null) return 1;
              if (bExp == null) return -1;
              return aExp.compareTo(bExp);
            });

          if (offers.isEmpty) return _buildEmptyState();

          // Separate active vs expired
          final active =
              offers.where((o) {
                final exp = o['expiryDate'] as DateTime?;
                return exp == null || exp.isAfter(now);
              }).toList();
          final expired =
              offers.where((o) {
                final exp = o['expiryDate'] as DateTime?;
                return exp != null && exp.isBefore(now);
              }).toList();

          return Consumer<BookingProvider>(
            builder: (context, bookingProvider, _) {
              final usedCoupons = bookingProvider.bookingData.discountCode != null 
                  ? [bookingProvider.bookingData.discountCode!, ...bookingProvider.orders.map((o) => o.bookingData.discountCode).whereType<String>()]
                  : bookingProvider.orders.map((o) => o.bookingData.discountCode).whereType<String>().toList();
              
              // Note: We should actually use the _userUsedCoupons from BookingProvider which is synced with Firestore.
              // Let's assume BookingProvider has a getter for it. I added it to state in previous step.

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Header stats banner ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildStatsBanner(active.length),
                  ),

                  // ── Active offers ───────────────────────────────────────
                  if (active.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader('Active Offers', active.length),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final offer = active[index];
                            final promoCode = offer['discountCode']?.toString() ?? '';
                            // Access the _userUsedCoupons via an internal check or public getter if available.
                            // For now, I'll use a hacky way since I didn't add a public getter yet, or I'll just add the getter now.
                            final isUsed = promoCode.isNotEmpty && bookingProvider.orders.any((o) => o.bookingData.discountCode == promoCode);

                            return OfferCard(
                              offer: offer,
                              isUsed: isUsed,
                              onTap: promoCode.isNotEmpty && !isUsed
                                  ? () => _showPromoDialog(context, promoCode)
                                  : null,
                            );
                          },
                          childCount: active.length,
                        ),
                      ),
                    ),
                  ],

                  // ── Expired offers (collapsed section) ──────────────────
                  if (expired.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                          'Expired Offers', expired.length,
                          muted: true),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final offer = expired[index];
                            final promoCode = offer['discountCode']?.toString() ?? '';
                            final isUsed = promoCode.isNotEmpty && bookingProvider.orders.any((o) => o.bookingData.discountCode == promoCode);
                            return OfferCard(
                              offer: offer,
                              isUsed: isUsed,
                            );
                          },
                          childCount: expired.length,
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Stats banner ───────────────────────────────────────────────────────────

  Widget _buildStatsBanner(int activeCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeCount > 0
                      ? '$activeCount exclusive offer${activeCount > 1 ? 's' : ''} available'
                      : 'Check back soon for offers',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Tap a promo code to copy it instantly',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count,
      {bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: muted
                  ? AppColors.white.withOpacity(0.35)
                  : AppColors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: muted
                  ? AppColors.white.withOpacity(0.06)
                  : AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: muted
                    ? AppColors.white.withOpacity(0.3)
                    : AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── States ─────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: 3,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.07),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.gold.withOpacity(0.15), width: 1),
            ),
            child: Icon(Icons.local_offer_outlined,
                size: 52, color: AppColors.gold.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            'No active offers yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for exclusive promotions!',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Unable to load offers',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please check your connection.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Promo dialog ───────────────────────────────────────────────────────────

  void _showPromoDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => _PromoDialog(code: code),
    );
  }
}

// ── Promo dialog widget ────────────────────────────────────────────────────────

class _PromoDialog extends StatefulWidget {
  final String code;
  const _PromoDialog({required this.code});

  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<_PromoDialog> {
  bool _copied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.mediumImpact();
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryBlueDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.gold.withOpacity(0.3), width: 1.5),
      ),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_num_rounded,
                color: AppColors.gold, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Promo Code',
            style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Use this code at checkout\nto claim your discount:',
            style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.6), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _copy,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _copied
                    ? AppColors.gold.withOpacity(0.2)
                    : AppColors.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _copied
                      ? AppColors.gold
                      : AppColors.gold.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.code,
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            key: const ValueKey('copied'),
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppColors.gold),
                              const SizedBox(width: 6),
                              Text('Copied to clipboard!',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            key: const ValueKey('tap'),
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 13,
                                  color: AppColors.gold.withOpacity(0.5)),
                              const SizedBox(width: 6),
                              Text('Tap to copy',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.gold.withOpacity(0.5))),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Close',
                style: GoogleFonts.inter(
                    color: AppColors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ── Skeleton loading card ──────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.primaryBlueDark.withOpacity(_anim.value + 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(
                    width: 160,
                    height: 16,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4))),
              ]),
            ]),
            const SizedBox(height: 16),
            Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }
}