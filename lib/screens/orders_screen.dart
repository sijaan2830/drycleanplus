import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/booking_models.dart' as models;
import '../widgets/skeleton_loading.dart';
import '../widgets/bottom_navigation.dart';
import 'track_order_screen.dart';
import '../providers/booking_provider.dart';
import '../utils/route_helpers.dart';
import '../widgets/persistent_footer_app.dart';

import '../widgets/professional_empty_state.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedIndex = 3;
  int _selectedTab = 0; // 0 = Active, 1 = Completed
  bool _isLoading = true;
  bool _isOrderDetailsLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Show skeleton loader for 1 second, then initialize real-time stream
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // 1. Start the listeners
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.initializeListeners();
        
        // 2. Stop the local loading spinner
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/more');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'My Orders',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading 
          ? _buildSkeletonLoading()
          : Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                final orders = bookingProvider.orders;
                final activeOrders = orders.where((o) => 
                  o.status != 'completed' && o.status != 'delivered'
                ).toList();
                final completedOrders = orders.where((o) {
                  final isCompleted = o.status == 'completed' || o.status == 'delivered';
                  if (!isCompleted) return false;
                  
                  // Hide from this tab if it's already moved to "Past Orders" (older than 24h)
                  // Use deliveredAt -> updatedAt -> createdAt for consistency
                  final relevantDate = o.deliveredAt ?? o.updatedAt ?? o.createdAt;
                  final cutoff = DateTime.now().subtract(const Duration(hours: 24));
                  return relevantDate.isAfter(cutoff);
                }).toList();
                
                final displayOrders = _selectedTab == 0 ? activeOrders : completedOrders;
                
                return RefreshIndicator(
                  onRefresh: () async {
                    bookingProvider.initializeListeners();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.gold,
                  backgroundColor: AppColors.primaryBlueDark,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          children: [
                            // Order Status Tabs
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: AppColors.gold, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedTab = 0;
                                        });
                                      },
                                      child: Container(
                                        height: 40,
                                        margin: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: _selectedTab == 0 
                                              ? AppColors.gold
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Active',
                                            style: GoogleFonts.inter(
                                              color: _selectedTab == 0 
                                                  ? AppColors.primaryBlue
                                                  : AppColors.white,
                                              fontWeight: _selectedTab == 0 
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedTab = 1;
                                        });
                                      },
                                      child: Container(
                                        height: 40,
                                        margin: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: _selectedTab == 1 
                                              ? AppColors.gold
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Completed',
                                            style: GoogleFonts.inter(
                                              color: _selectedTab == 1 
                                                  ? AppColors.primaryBlue
                                                  : AppColors.white,
                                              fontWeight: _selectedTab == 1 
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Order Cards
                            if (displayOrders.isEmpty)
                              ProfessionalEmptyState(
                                icon: Icons.inbox_outlined,
                                title: _selectedTab == 0 
                                    ? 'No active orders'
                                    : 'No completed orders',
                                message: _selectedTab == 0 
                                    ? 'Your active orders will appear here'
                                    : 'Your completed orders will appear here',
                                actionLabel: _selectedTab == 0 ? 'Start an order' : null,
                                onAction: _selectedTab == 0 ? () => Navigator.of(context).pushNamed('/home') : null,
                              )
                            else
                              ...displayOrders.map((order) => _buildOrderCard(order)),
                            
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Order Status Tabs Skeleton
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueDark,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Order Card Skeletons
          ...List.generate(3, (index) => _buildOrderCardSkeleton()),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildOrderCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(
                width: 120,
                height: 16,
                borderRadius: 4,
              ),
              SkeletonLoading(
                width: 80,
                height: 24,
                borderRadius: 12,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date and Items Row Skeleton
          Row(
            children: [
              SkeletonLoading(
                width: 80,
                height: 14,
                borderRadius: 4,
              ),
              const SizedBox(width: 16),
              SkeletonLoading(
                width: 60,
                height: 14,
                borderRadius: 4,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Amount Row Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(
                width: 100,
                height: 14,
                borderRadius: 4,
              ),
              SkeletonLoading(
                width: 60,
                height: 16,
                borderRadius: 4,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Track Order Button Skeleton
          SkeletonLoading(
            height: 44,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(models.Order order) {
    final statusInfo = _getStatusInfo(order.status);
    final itemCount = order.bookingData.selectedItems.length;
    final subtotal = order.bookingData.calculatedTotalPrice;
    const serviceFee = 2.99;
    const deliveryFee = 0.0;
    const taxRate = 0.20; // 20% tax
    
    final tax = (subtotal + serviceFee + deliveryFee) * taxRate;
    final totalAmount = subtotal + serviceFee + deliveryFee + tax;
    final date = '${order.createdAt.day} ${_getMonth(order.createdAt.month)} ${order.createdAt.year}';
    final isPrepaidPack = order.type == 'prepaid_pack';
    final prepaidPackName = order.bookingData.prepaidPackName ?? 'Prepaid Pack';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecoration.blueCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with flexible layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and prepaid tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (isPrepaidPack) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.gold, width: 0.5),
                        ),
                        child: Text(
                          prepaidPackName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusInfo['color'], width: 1),
                  ),
                  child: Text(
                    statusInfo['label'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusInfo['color'],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date and Items Row
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppColors.gold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.inventory_2,
                color: AppColors.gold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isPrepaidPack ? 'Prepaid Pack' : '$itemCount items',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
              Text(
                '£${totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Track Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showOrderDetails(order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Track Order',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'color': const Color(0xFF9CA3AF),
          'label': 'Pending',
        };
      case 'processing':
        return {
          'color': const Color(0xFF3B82F6),
          'label': 'Processing',
        };
      case 'in_progress':
        return {
          'color': const Color(0xFFF59E0B),
          'label': 'In Progress',
        };
      case 'out_for_delivery':
        return {
          'color': const Color(0xFF10B981),
          'label': 'Out for Delivery',
        };
      case 'completed':
      case 'delivered':
        return {
          'color': const Color(0xFF10B981),
          'label': 'Delivered',
        };
      default:
        return {
          'color': const Color(0xFF9CA3AF),
          'label': status,
        };
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _showOrderDetails(models.Order order) {
    // Navigate to the new track order page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrackOrderScreen(order: order),
      ),
    );
  }
}
