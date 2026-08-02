import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/route_helpers.dart';
import '../../widgets/persistent_footer_app.dart';
import '../orders_screen.dart';
import '../../models/booking_models.dart' as models;

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Consumer<BookingProvider>(
          builder: (context, provider, child) {
            final orders = provider.orders;
            final models.Order? latestOrder = orders.isNotEmpty ? orders.first : null;
            
            // Show skeleton loading while waiting for order data
            if (latestOrder == null) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success Animation Skeleton
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Title Skeleton
                        Container(
                          width: 200,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle Skeleton
                        Container(
                          width: 250,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Order Details Skeleton
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.white.withOpacity(0.1)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Buttons Skeleton
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.white.withOpacity(0.1)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Animation
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.gold,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Success Message
                      Text(
                        'Booking Confirmed!',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your order has been successfully placed',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Order Details
                      if (latestOrder != null) 
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: AppCardDecoration.blueCardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Details',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('Order Number', latestOrder.orderId),
                              _buildStatusRow('Status', latestOrder.status),
                              _buildDetailRow('Order Type', latestOrder.type),
                              _buildDetailRow('Collection', '${latestOrder.bookingData.collectionDate} • ${latestOrder.bookingData.collectionTime}'),
                              _buildDetailRow('Delivery', '${latestOrder.bookingData.deliveryDate} • ${latestOrder.bookingData.deliveryTime}'),
                              _buildDetailRow('Items', '${latestOrder.bookingData.selectedItemsCount} items'),
                              _buildDetailRow('Total Amount', '£${_getTotalAmountWithTax(latestOrder)}', isPrice: true),
                              _buildDetailRow('Created At', _formatDateTime(latestOrder.createdAt)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      // What's Next
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: AppCardDecoration.blueCardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What\'s Next?',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildNextStep(
                              '1',
                              'Collection',
                              'Our driver will arrive at your selected time',
                              Icons.access_time,
                            ),
                            const SizedBox(height: 12),
                            _buildNextStep(
                              '2',
                              'Processing',
                              'Your items will be professionally cleaned',
                              Icons.local_laundry_service,
                            ),
                            const SizedBox(height: 12),
                            _buildNextStep(
                              '3',
                              'Delivery',
                              'Clean items will be delivered back to you',
                              Icons.local_shipping,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Update the footer tab index to Home (index 0)
                                persistentFooterAppState?.setTab(0);
                                // Navigate to Home
                                navigatorKey.currentState?.pushAndRemoveUntil(
                                  noTransitionRoute(const MainTabScreen(tabIndex: 0), routeName: '/home'),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'Back to Home',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // Update the footer tab index to More (index 3)
                                persistentFooterAppState?.setTab(3);
                                // Navigate to More screen (which contains Orders)
                                navigatorKey.currentState?.pushAndRemoveUntil(
                                  noTransitionRoute(const MainTabScreen(tabIndex: 3), routeName: '/more'),
                                  (route) => false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: AppColors.gold, width: 2),
                              ),
                              child: Text(
                                'Track Order',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getTotalAmountWithTax(models.Order order) {
    // Calculate total amount with tax and fees (same as payment screen)
    final subtotal = order.bookingData.calculatedTotalPrice;
    const serviceFee = 2.99;
    const deliveryFee = 0.0;
    const taxRate = 0.20; // 20% tax
    
    final tax = (subtotal + serviceFee + deliveryFee) * taxRate;
    final total = subtotal + serviceFee + deliveryFee + tax;
    
    return total.toStringAsFixed(2);
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: isPrice 
              ? GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                )
              : GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    Color statusColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = AppColors.grey;
        statusText = 'Pending';
        break;
      case 'processing':
        statusColor = AppColors.primaryBlue;
        statusText = 'Processing';
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusText = 'Completed';
        break;
      case 'delivered':
        statusColor = AppColors.success;
        statusText = 'Delivered';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = AppColors.grey;
        statusText = status;
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNextStep(String number, String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold, width: 1),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
