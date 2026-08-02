import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/theme.dart';
import '../widgets/skeleton_loading.dart';

class PastOrdersScreen extends StatefulWidget {
  const PastOrdersScreen({super.key});

  @override
  State<PastOrdersScreen> createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Show skeleton loader for 1.2 seconds to match other screens
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Past Orders',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading 
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildSkeletonCard(),
            )
          : user == null
              ? _buildLoginPrompt(context)
              : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (context, index) => _buildSkeletonCard(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Sort client-side to avoid index error
                final sortedDocs = docs.toList()..sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // Descending
                });

                // Filter: status is 'delivered' or 'completed'
                final pastOrders = sortedDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // Check status
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  return status == 'delivered' || status == 'completed';
                }).toList() ?? [];

                if (pastOrders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pastOrders.length,
                  itemBuilder: (context, index) {
                    final data = pastOrders[index].data() as Map<String, dynamic>;
                    return _buildOrderCard(data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    DateTime? orderDate;
    if (createdAt is Timestamp) {
      orderDate = createdAt.toDate();
    }

    // Get items from multiple possible fields
    final items = (data['items'] as List<dynamic>?) ??
        (data['selectedItems'] as List<dynamic>?) ?? [];
    
    final totalPrice = data['transactionAmount'] ?? 
                      data['totalAmount'] ?? 
                      data['totalPrice'] ?? 
                      (data['bookingData'] != null ? 
                        (data['bookingData']['transactionAmount'] ?? data['bookingData']['calculatedTotalPrice']) : null);
    final serviceType = data['serviceType'] ?? data['service'] ??
        data['selectedService'] ?? 'Dry Clean Service';
    final orderId = data['orderId'] ?? data['id'] ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  serviceType.toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981), width: 1),
                ),
                child: Text(
                  'Delivered',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Order ID
          if (orderId != '—') ...[
            Row(
              children: [
                const Icon(Icons.tag, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Order: $orderId',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.white.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Date
          if (orderDate != null) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  '${orderDate.day}/${orderDate.month}/${orderDate.year}  '
                  '${orderDate.hour.toString().padLeft(2, '0')}:'
                  '${orderDate.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Items list
          if (items.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.dry_cleaning, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    items.map((i) {
                      if (i is Map) {
                        return i['itemType'] ?? i['name'] ?? 'Item';
                      }
                      return i.toString();
                    }).join(', '),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
              Text(
                totalPrice != null
                    ? (totalPrice.toString().startsWith('£')
                        ? '£${double.tryParse(totalPrice.toString().replaceAll('£', ''))?.toStringAsFixed(2) ?? totalPrice}'
                        : '£${double.tryParse(totalPrice.toString())?.toStringAsFixed(2) ?? totalPrice}')
                    : '—',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: AppColors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No past orders yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivered orders older than 24 hours\nwill appear here automatically.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.3),
            ),
            textAlign: TextAlign.center,
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
          const Icon(Icons.error_outline, size: 60, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            'Could not load orders.\nPlease try again.',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 60, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            'Please sign in to view your past orders.',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(width: 100, height: 16, borderRadius: 4),
              SkeletonLoading(width: 80, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonLoading(width: 200, height: 14, borderRadius: 4),
          const SizedBox(height: 8),
          SkeletonLoading(width: 150, height: 14, borderRadius: 4),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(width: 120, height: 14, borderRadius: 4),
              SkeletonLoading(width: 60, height: 16, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}
