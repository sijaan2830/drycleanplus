import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../widgets/app_ui.dart';
import '../widgets/offer_card.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Offers & Promotions',
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('offers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _OffersSkeleton();
          }
          if (snapshot.hasError) {
            debugPrint('OffersScreen error: ${snapshot.error}');
            return const _Message(
              icon: Icons.wifi_off_rounded,
              title: 'Unable to load offers',
              text: 'Please check your connection.',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final now = DateTime.now();
          final offers = docs
              .map((doc) {
                final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
                data['id'] = doc.id;
                if (data['expiryDate'] is Timestamp) {
                  data['expiryDate'] = (data['expiryDate'] as Timestamp).toDate();
                }
                return data;
              })
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

          final active = offers.where((o) {
            final exp = o['expiryDate'] as DateTime?;
            return exp == null || exp.isAfter(now);
          }).toList();

          final expired = offers.where((o) {
            final exp = o['expiryDate'] as DateTime?;
            return exp != null && exp.isBefore(now);
          }).toList();

          return Consumer<BookingProvider>(
            builder: (context, bookingProvider, _) {
              bool isUsed(String code) =>
                  code.isNotEmpty && bookingProvider.orders.any((o) => o.bookingData.discountCode == code);

              Widget card(Map<String, dynamic> offer, {bool allowTap = true}) {
                final code = offer['discountCode']?.toString() ?? '';
                final used = isUsed(code);
                return OfferCard(
                  offer: offer,
                  isUsed: used,
                  onTap: allowTap && code.isNotEmpty && !used ? () => _showPromoDialog(context, code) : null,
                );
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Active offers section header
                  SliverToBoxAdapter(
                    child: _sectionLabel('Active offers', active.length, isWhiteBadge: active.isNotEmpty),
                  ),

                  // If no active offers, show exact .empty card from HTML
                  if (active.isEmpty)
                    SliverToBoxAdapter(
                      child: _emptyBanner(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _Entrance(index: i, child: card(active[i])),
                          childCount: active.length,
                        ),
                      ),
                    ),

                  // Expired offers section
                  if (expired.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _sectionLabel('Expired offers', expired.length, isWhiteBadge: true),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _Entrance(
                            index: i + active.length,
                            child: card(expired[i], allowTap: false),
                          ),
                          childCount: expired.length,
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Section label matching HTML .lb:
  /// font-size: 12.5px, font-weight: 800, letter-spacing: .14em, uppercase, color: #DCE8FF
  /// .ct: chip badge; .ct.w: white badge with #1553D6 text when highlighted
  Widget _sectionLabel(String title, int count, {required bool isWhiteBadge}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
              color: const Color(0xFFDCE8FF),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: isWhiteBadge ? Colors.white : Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isWhiteBadge ? const Color(0xFF1553D6) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty banner matching HTML .empty:
  /// border: 1px solid rgba(255,255,255,.22)
  /// background: linear-gradient(160deg, rgba(8,26,92,.55), rgba(6,20,72,.72))
  /// .ei: 56x56 white circle, box-shadow: 0 0 0 7px rgba(255,255,255,.14)
  Widget _emptyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1.0),
          end: Alignment(0.6, 1.0),
          colors: [Color(0x8C081A5C), Color(0xB8061448)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white.withOpacity(0.14), width: 7),
            ),
            child: const Center(
              child: Icon(Icons.local_offer_rounded, color: Color(0xFF1553D6), size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Check back soon for offers',
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a promo code to copy it instantly',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE6EEFF),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoDialog(BuildContext context, String code) {
    showDialog(context: context, builder: (_) => _PromoDialog(code: code));
  }
}

class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index.clamp(0, 6) * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Message({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.14),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Icon(icon, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.5, height: 1.4, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoDialog extends StatefulWidget {
  final String code;
  const _PromoDialog({required this.code});

  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<_PromoDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF071A45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFC73A),
            ),
            child: const Icon(Icons.local_offer_rounded, color: Color(0xFF0B1A3D), size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Promo Code',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Use this code at checkout\nto claim your discount:',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _copy,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: _copied ? const Color(0x33009668) : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _copied ? const Color(0xFF8CF0BC) : Colors.white.withOpacity(0.4),
                  width: 1.6,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.code,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Row(
                            key: const ValueKey('copied'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF8CF0BC)),
                              const SizedBox(width: 6),
                              Text(
                                'Copied to clipboard!',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8CF0BC),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('tap'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy_rounded, size: 15, color: Colors.white.withOpacity(0.8)),
                              const SizedBox(width: 6),
                              Text(
                                'Tap to copy',
                                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withOpacity(0.8)),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ],
    );
  }
}

class _OffersSkeleton extends StatefulWidget {
  const _OffersSkeleton();

  @override
  State<_OffersSkeleton> createState() => _OffersSkeletonState();
}

class _OffersSkeletonState extends State<_OffersSkeleton> with SingleTickerProviderStateMixin {
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
          padding: const EdgeInsets.all(16),
          children: List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(o),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        );
      },
    );
  }
}
