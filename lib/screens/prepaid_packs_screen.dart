import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/app_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/skeleton_loading.dart';
import '../providers/booking_provider.dart';
import '../providers/prepaid_provider.dart';
import '../models/booking_models.dart';
import '../utils/route_helpers.dart';
import '../widgets/persistent_footer_app.dart';
import '../widgets/app_sliders.dart';
import '../services/firestore_service.dart';
import '../widgets/prepaid_pack_card.dart';

class PrepaidPacksScreen extends StatefulWidget {
  final bool? showBottomNav;

  const PrepaidPacksScreen({super.key, this.showBottomNav});

  bool get _showBottomNav => showBottomNav ?? true;

  @override
  State<PrepaidPacksScreen> createState() => _PrepaidPacksScreenState();
}

class _PrepaidPacksScreenState extends State<PrepaidPacksScreen> {
  int _selectedIndex = 2;
  bool _isShopTabSelected = true;
  bool _isInitialLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _prepaidPacks = [];
  StreamSubscription? _packsSubscription;

  @override
  void initState() {
    super.initState();
    // Show skeleton loader briefly when navigating to this screen
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });
    // Stream prepaid packs in real-time from Firestore (Admin Panel sync)
    _listenToPrepaidPacks();
  }

  void _listenToPrepaidPacks() {
    _packsSubscription = _firestoreService.getPrepaidPacksStream().listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _prepaidPacks = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'description': data['description'] ?? '',
              'discounts': data['discounts'] ?? [],
              'isActive': data['isActive'] ?? true,
              'order': data['order'] ?? 0,
            };
          }).toList()
            ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
        });
      },
      onError: (e) {
        print('Error streaming prepaid packs: $e');
      },
    );
  }

  @override
  void dispose() {
    _packsSubscription?.cancel();
    super.dispose();
  }

  void _purchasePack(String name, String description, int count, double price, String itemType) {
    // Create a prepaid pack order and navigate to time slots first
    final provider = Provider.of<BookingProvider>(context, listen: false);
    
    // Create a service item for the prepaid pack
    final packItem = ServiceItem(
      category: 'Prepaid Pack',
      itemType: '$name - $count $itemType',
      price: '£${price.toStringAsFixed(2)}',
    );
    
    // Clear existing items and add the pack
    provider.clearBookingData();
    provider.addServiceItem(packItem);
    provider.setSelectedService('Prepaid Pack');
    provider.setPrepaidPackName(name); // Set the prepaid pack name
    
    // Navigate to time slots page first
    Navigator.of(context).pushNamed('/time_slots');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prepaid packs',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Unlock savings on your frequent items',
                                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.82)),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.white.withOpacity(0.16),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _showInfoDialog,
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 21),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildToggleTabs(),
                      const SizedBox(height: 12),
                      Consumer<PrepaidProvider>(
                        builder: (context, prepaidProvider, child) {
                          final Widget content;
                          if (_isInitialLoading || prepaidProvider.isLoading) {
                            content = KeyedSubtree(key: const ValueKey('loading'), child: _buildSkeletonLoading());
                          } else if (_isShopTabSelected) {
                            final active = _prepaidPacks.where((p) => p['isActive'] == true).toList();
                            content = KeyedSubtree(
                              key: const ValueKey('shop'),
                              child: active.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: Center(
                                        child: Text(
                                          'No prepaid packs available',
                                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        _buildPromoBanner(),
                                        for (final pack in active)
                                          _buildPackSectionFromFirestore(
                                            pack['name'] ?? '',
                                            pack['description'] ?? '',
                                            (pack['discounts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
                                          ),
                                      ],
                                    ),
                            );
                          } else {
                            content = KeyedSubtree(key: const ValueKey('mine'), child: _buildMyPacksSection(prepaidProvider));
                          }
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
                                child: child,
                              ),
                            ),
                            child: content,
                          );
                        },
                      ),
                      SizedBox(height: widget._showBottomNav ? 80 : 25),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTabs() {
    return Consumer<PrepaidProvider>(
      builder: (context, prepaidProvider, child) {
        Widget tab(bool shop, String label) {
          final on = _isShopTabSelected == shop;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!on) HapticFeedback.selectionClick();
                setState(() => _isShopTabSelected = shop);
              },
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: on ? const Color(0xFF1553D6) : Colors.white,
                  ),
                  child: Text(label),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: _isShopTabSelected ? Alignment.centerLeft : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    tab(true, 'Shop'),
                    tab(false, 'My Packs (${prepaidProvider.activePacksCount})'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF081A5C).withOpacity(0.55),
              const Color(0xFF061448).withOpacity(0.72),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFC73A),
              ),
              child: const Icon(Icons.percent_rounded, color: Color(0xFF0B1A3D), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  children: const [
                    TextSpan(text: 'Pay once, '),
                    TextSpan(
                      text: 'save up to 15%',
                      style: TextStyle(color: Color(0xFFFFC73A), fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' on every visit.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonSection(),
          const SizedBox(height: 12),
          _buildSkeletonSection(),
        ],
      ),
    );
  }

  Widget _buildSkeletonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Skeleton
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Row(
            children: [
              const SkeletonLoading(width: 38, height: 38, borderRadius: 11),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoading(width: 160, height: 16, borderRadius: 6),
                  SizedBox(height: 5),
                  SkeletonLoading(width: 110, height: 12, borderRadius: 6),
                ],
              ),
            ],
          ),
        ),
        // Horizontal sliding skeleton cards with live sparkle and shimmer
        SizedBox(
          height: 218,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => const SkeletonLoading(
              width: 168,
              height: 202,
              borderRadius: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyPacksSection(PrepaidProvider prepaidProvider) {
    final myPacks = prepaidProvider.activePacks;

    if (myPacks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 30, 32, 10),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.14),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'No prepaid packs yet',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Purchase a pack to save on your frequent items',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.4, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 220,
              child: AppButton(
                label: 'BROWSE PACKS',
                icon: Icons.storefront_rounded,
                onPressed: () => setState(() => _isShopTabSelected = true),
              ),
            ),
          ],
        ),
      );
    }

    final totalRemaining = myPacks.fold<int>(0, (sum, p) => sum + p.remainingCount);
    int? minDaysLeft;
    for (final p in myPacks) {
      if (p.expiryDate != null) {
        final days = p.expiryDate!.difference(DateTime.now()).inDays;
        if (minDaysLeft == null || days < minDaysLeft) {
          minDaysLeft = days;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Summary Glass Box (.glass.sum) ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF081A5C).withOpacity(0.55),
                  const Color(0xFF061448).withOpacity(0.72),
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$totalRemaining',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFC73A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'items left',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE6EEFF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.18),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${myPacks.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFC73A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'active packs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE6EEFF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.18),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        minDaysLeft != null ? '$minDaysLeft' : '—',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFC73A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'days to expiry',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE6EEFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── My Pack Cards (.pk) ──
          for (final pack in myPacks) ...[
            _buildMyPackCard(pack),
            const SizedBox(height: 10),
          ],

          // ── More Footer (.more) ──
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need more?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse packs and save up to 15%.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFFE6EEFF),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1553D6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () => setState(() => _isShopTabSelected = true),
                  child: Text(
                    'Shop packs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPackCard(PrepaidPack pack) {
    final progress = pack.itemCount > 0 ? (pack.remainingCount / pack.itemCount).clamp(0.0, 1.0) : 0.0;
    final daysLeft = pack.expiryDate != null ? pack.expiryDate!.difference(DateTime.now()).inDays : null;
    final gradientColors = PrepaidPackCard.getGradient(pack.name);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF050F32).withOpacity(0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background bubbles (.dc)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: 34,
              left: -22,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top section (.top)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Progress Ring (.rg) 80x80
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 8,
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                color: const Color(0xFFFFC73A),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${pack.remainingCount}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  'left',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Information (.in)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    pack.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDDF6E9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF12A56A),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Active',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0A6B43),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            if (pack.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                pack.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Segmented Progress Bar (.seg)
                            Row(
                              children: List.generate(
                                pack.itemCount.clamp(1, 10),
                                (index) {
                                  final isUsed = index >= pack.remainingCount;
                                  return Expanded(
                                    child: Container(
                                      height: 6,
                                      margin: EdgeInsets.only(right: index < pack.itemCount - 1 ? 3 : 0),
                                      decoration: BoxDecoration(
                                        color: isUsed ? Colors.white.withOpacity(0.28) : const Color(0xFFFFC73A),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Meta row: "2/5 used" and "74 days left"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${pack.usedCount}/${pack.itemCount} used',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (daysLeft != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.28),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          daysLeft < 0 ? 'Expired' : '$daysLeft days left',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
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

                // Bottom Action Footer (.ft.bk)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/service_selection');
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050F3C).withOpacity(0.35),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Book with this pack',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFC73A),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF0B1A3D),
                            size: 15,
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
      ),
    );
  }

  bool _isBestValueItem(Map<String, dynamic> item, int index, List<Map<String, dynamic>> discounts) {
    if (item['isBestValue'] == true) return true;
    if (discounts.length <= 1) return false;
    if (item['isBestValue'] == false) return false;

    int bestIndex = discounts.length - 1;
    double maxOff = -1;
    for (int i = 0; i < discounts.length; i++) {
      final offStr = discounts[i]['off']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
      final offVal = double.tryParse(offStr) ?? 0.0;
      if (offVal > maxOff) {
        maxOff = offVal;
        bestIndex = i;
      }
    }
    return index == bestIndex;
  }

  Widget _buildPackSectionFromFirestore(String title, String subtitle, List<Map<String, dynamic>> discounts) {
    final gradientColors = PrepaidPackCard.getGradient(title);

    IconData getIcon(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('trouser')) return Icons.dry_cleaning_rounded;
      if (lower.contains('suit')) return Icons.work_outline_rounded;
      if (lower.contains('duvet') || lower.contains('bedding')) return Icons.bed_rounded;
      if (lower.contains('shirt')) return Icons.checkroom_rounded;
      return Icons.local_laundry_service_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (.sh)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 0,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(getIcon(title), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFFE6EEFF),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cards - Horizontal sliding scrollable cards
          SizedBox(
            height: 218,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: discounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = discounts[i];
                return PrepaidPackCard(
                  width: 168,
                  packName: title,
                  item: item,
                  isBestValue: _isBestValueItem(item, i, discounts),
                  onTap: () {
                    final count = int.tryParse(item['count']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 5;
                    final price = double.tryParse(item['new']?.toString() ?? '0') ?? 0.0;
                    _purchasePack(title, subtitle, count, price, item['label']?.toString() ?? '');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackSection(String title, String subtitle, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold, width: 1),
                ),
                child: const Icon(
                  Icons.dry_cleaning,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  final count = int.tryParse(item['count']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 5;
                  final price = double.tryParse(item['new'] ?? '0') ?? 0.0;
                  _purchasePack(title, subtitle, count, price, item['label'] ?? '');
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: AppCardDecoration.blueCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${item['count']} ${item['label']}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.gold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "£${item['old']}",
                            style: GoogleFonts.inter(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.white.withOpacity(0.5),
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${item['off']} OFF",
                            style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                                "£${item['new']}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Prepaid Packs Info',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_rounded, color: AppColors.gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'About Prepaid Packs',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoPoint('Save up to 15% on regular prices', const Color(0xFF1A1A1A)),
                  _buildInfoPoint('Valid for 90 days from purchase', const Color(0xFF1A1A1A)),
                  _buildInfoPoint('Use instantly for any service of same type', const Color(0xFF1A1A1A)),
                  _buildInfoPoint('Track usage in your "My Packs" tab', const Color(0xFF1A1A1A)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'GOT IT',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildInfoPoint(String text, [Color textColor = Colors.black]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SunburstPainter extends CustomPainter {
  final Color color;
  final int points;

  SunburstPainter({required this.color, this.points = 18});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.82;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withRed((color.red - 20).clamp(0, 255)),
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: outerRadius))
      ..style = PaintingStyle.fill;

    final path = Path();
    final angleStep = (math.pi * 2) / (points * 2);

    for (int i = 0; i <= points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(i * angleStep - math.pi / 2);
      final y = centerY + radius * math.sin(i * angleStep - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.4), 3, false);
    canvas.drawPath(path, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
