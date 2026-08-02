import 'dart:math' as math;
import 'package:flutter/material.dart';
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
import '../services/firestore_service.dart';

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
    // Load prepaid packs from Firestore
    _loadPrepaidPacksFromFirestore();
  }

  Future<void> _loadPrepaidPacksFromFirestore() async {
    try {
      print('=== PrepaidPacksScreen: Loading prepaid packs from Firestore ===');
      final snapshot = await _firestoreService.getPrepaidPacks();
      print('Firestore snapshot docs count: ${snapshot.docs.length}');
      
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _prepaidPacks = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Prepaid pack doc data: $data');
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
        print('Loaded prepaid packs: $_prepaidPacks');
      } else {
        print('No prepaid packs found in Firestore');
      }
    } catch (e) {
      print('Error loading prepaid packs: $e');
    }
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
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        automaticallyImplyLeading: false, 
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Prepaid packs',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Unlock savings on your frequent items',
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showInfoDialog();
            },
            icon: const Icon(Icons.info_outline, color: AppColors.gold),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildToggleTabs(),
            const SizedBox(height: 24),
            Consumer<PrepaidProvider>(
              builder: (context, prepaidProvider, child) {
                if (_isInitialLoading || prepaidProvider.isLoading) {
                  return _buildSkeletonLoading();
                } else if (_isShopTabSelected) {
                  return Column(
                    children: [
                      if (_prepaidPacks.isNotEmpty) ...[
                        for (final pack in _prepaidPacks)
                          if (pack['isActive'] == true)
                            _buildPackSectionFromFirestore(
                              pack['name'] ?? '',
                              pack['description'] ?? '',
                              (pack['discounts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
                            ),
                        if (_prepaidPacks.isEmpty)
                          const Center(
                            child: Text(
                              'No prepaid packs available',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                      ],
                    ],
                  );
                } else {
                  return _buildMyPacksSection(prepaidProvider);
                }
              },
            ),
            SizedBox(height: widget._showBottomNav ? 100 : 50), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTabs() {
    return Consumer<PrepaidProvider>(
      builder: (context, prepaidProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isShopTabSelected = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isShopTabSelected 
                          ? AppColors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: Text(
                      'Shop',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _isShopTabSelected 
                            ? AppColors.primaryBlue
                            : AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isShopTabSelected = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isShopTabSelected 
                          ? AppColors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: Text(
                      'My Packs (${prepaidProvider.activePacksCount})',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: !_isShopTabSelected 
                            ? AppColors.primaryBlue
                            : AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header skeleton
          Row(
            children: [
              const SkeletonLoading(width: 36, height: 36, borderRadius: 8),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoading(width: 150, height: 16, borderRadius: 4),
                  const SizedBox(height: 4),
                  SkeletonLoading(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pack cards skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withOpacity(0.15), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoading(width: 60, height: 24, borderRadius: 4),
                      const SizedBox(height: 12),
                      const SkeletonLoading(width: double.infinity, height: 14, borderRadius: 4),
                      const SizedBox(height: 8),
                      const SkeletonLoading(width: 80, height: 14, borderRadius: 4),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SkeletonLoading(width: 60, height: 20, borderRadius: 4),
                          const SkeletonLoading(width: 40, height: 16, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withOpacity(0.15), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoading(width: 60, height: 24, borderRadius: 4),
                      const SizedBox(height: 12),
                      const SkeletonLoading(width: double.infinity, height: 14, borderRadius: 4),
                      const SizedBox(height: 8),
                      const SkeletonLoading(width: 80, height: 14, borderRadius: 4),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SkeletonLoading(width: 60, height: 20, borderRadius: 4),
                          const SkeletonLoading(width: 40, height: 16, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Second section header skeleton
          Row(
            children: [
              const SkeletonLoading(width: 36, height: 36, borderRadius: 8),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoading(width: 150, height: 16, borderRadius: 4),
                  const SizedBox(height: 4),
                  SkeletonLoading(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Second pack cards skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withOpacity(0.15), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoading(width: 60, height: 24, borderRadius: 4),
                      const SizedBox(height: 12),
                      const SkeletonLoading(width: double.infinity, height: 14, borderRadius: 4),
                      const SizedBox(height: 8),
                      const SkeletonLoading(width: 80, height: 14, borderRadius: 4),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SkeletonLoading(width: 60, height: 20, borderRadius: 4),
                          const SkeletonLoading(width: 40, height: 16, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withOpacity(0.15), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoading(width: 60, height: 24, borderRadius: 4),
                      const SizedBox(height: 12),
                      const SkeletonLoading(width: double.infinity, height: 14, borderRadius: 4),
                      const SizedBox(height: 8),
                      const SkeletonLoading(width: 80, height: 14, borderRadius: 4),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SkeletonLoading(width: 60, height: 20, borderRadius: 4),
                          const SkeletonLoading(width: 40, height: 16, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyPacksSection(PrepaidProvider prepaidProvider) {
    final myPacks = prepaidProvider.activePacks;
    
    if (myPacks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No prepaid packs yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Purchase a pack to save on your frequent items',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.white.withOpacity(0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isShopTabSelected = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Browse Packs',
                style: GoogleFonts.inter(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: myPacks.map((pack) => _buildMyPackCard(pack)).toList(),
    );
  }

  Widget _buildMyPackCard(PrepaidPack pack) {
    final progress = pack.itemCount > 0 ? pack.remainingCount / pack.itemCount : 0.0;
    final daysLeft = pack.expiryDate != null 
        ? pack.expiryDate!.difference(DateTime.now()).inDays 
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pack.description,
                      style: GoogleFonts.inter(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pack.isActive 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pack.isActive ? 'Active' : (pack.isExpired ? 'Expired' : 'Used'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: pack.isActive 
                        ? AppColors.gold
                        : AppColors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pack.remainingCount} remaining',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '${pack.usedCount}/${pack.itemCount} used',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: daysLeft < 30 ? Colors.orange : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '$daysLeft days left',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: daysLeft < 30 ? Colors.orange : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackSectionFromFirestore(String title, String subtitle, List<Map<String, dynamic>> discounts) {
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
            itemCount: discounts.length,
            itemBuilder: (context, index) {
              final item = discounts[index];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      final count = int.tryParse(item['count']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 5;
                      final price = double.tryParse(item['new'] ?? '0') ?? 0.0;
                      _purchasePack(title, subtitle, count, price, item['label'] ?? '');
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${item['count']} ${item['label']}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "was £${item['old']}",
                            style: GoogleFonts.inter(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.white.withOpacity(0.55),
                              fontSize: 11,
                            ),
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
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Discount sticker — top-right corner ───────────────────────
                  Positioned(
                    top: -12,
                    right: 0,
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: CustomPaint(
                        painter: SunburstPainter(color: const Color(0xFFD32F2F)),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${item['off']}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'OFF',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
