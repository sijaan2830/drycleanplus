import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/booking_models.dart';
import '../utils/route_helpers.dart';
import '../widgets/persistent_footer_app.dart';
import '../providers/booking_provider.dart';

class TrackOrderScreen extends StatefulWidget {
  final Order order;

  const TrackOrderScreen({
    super.key,
    required this.order,
  });

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  late Order _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    
    // Initialize listeners if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.initializeListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        // Update current order from provider if it exists
        final updatedOrder = bookingProvider.orders.firstWhere(
          (order) => order.id == widget.order.id,
          orElse: () => _currentOrder,
        );
        
        // Always update to ensure instant reflection
        _currentOrder = updatedOrder;

        return Scaffold(
          backgroundColor: AppColors.primaryBlue,
          appBar: AppBar(
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Track Order',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Add refresh button for manual refresh
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.white),
                onPressed: () {
                  bookingProvider.initializeListeners();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: AppColors.gold,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Order ${_currentOrder.orderId}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tracking Steps
                Text(
                  'Order Status',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildTrackingStep(
                  'Order Placed',
                  'Your order has been placed successfully',
                  true,
                  true,
                ),
                const SizedBox(height: 16),
                _buildTrackingStep(
                  'Processing',
                  'Your order is being processed',
                  ['processing', 'in_progress', 'out_for_delivery', 'delivered'].contains(_currentOrder.status),
                  ['processing', 'in_progress', 'out_for_delivery', 'delivered'].contains(_currentOrder.status),
                ),
                const SizedBox(height: 16),
                _buildTrackingStep(
                  'In Progress',
                  'Your items are being cleaned',
                  ['in_progress', 'out_for_delivery', 'delivered'].contains(_currentOrder.status),
                  ['in_progress', 'out_for_delivery', 'delivered'].contains(_currentOrder.status),
                ),
                const SizedBox(height: 16),
                _buildTrackingStep(
                  'Out for Delivery',
                  'Your order is on the way',
                  ['out_for_delivery', 'delivered'].contains(_currentOrder.status),
                  ['out_for_delivery', 'delivered'].contains(_currentOrder.status),
                ),
                const SizedBox(height: 16),
                _buildTrackingStep(
                  'Delivered',
                  'Your order has been delivered',
                  ['delivered'].contains(_currentOrder.status),
                  ['delivered'].contains(_currentOrder.status),
                ),
                const SizedBox(height: 32),
                
                // Order Details Section
                Text(
                  'Order Details',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark.withOpacity(0.3),
                    border: Border.all(color: AppColors.white.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Status', _getOrderStatusText()),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date', '${_currentOrder.createdAt.day} ${_getMonth(_currentOrder.createdAt.month)} ${_currentOrder.createdAt.year}'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Total Items', '${_currentOrder.bookingData.selectedItems.length}'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Total Amount', '£${_getTotalAmountWithTax()}'),
                    ],
                  ),
                ),
                const SizedBox(height: 50), // Reduced padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackingStep(String title, String description, bool isActive, bool isCompleted) {
    final isCurrentStep = _isCurrentStep(title);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? (_currentOrder.status == 'cancelled' ? AppColors.error : AppColors.gold)
                    : AppColors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: isCurrentStep && !isCompleted 
                    ? Border.all(color: AppColors.gold, width: 2)
                    : null,
              ),
              child: isCompleted
                  ? Icon(
                      _currentOrder.status == 'cancelled' ? Icons.close : Icons.check,
                      color: AppColors.primaryBlue,
                      size: 14,
                    )
                  : isCurrentStep
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
            ),
            if (title != 'Completed' && title != 'Cancelled')
              Container(
                width: 2,
                height: 40,
                color: isCompleted 
                    ? (_currentOrder.status == 'cancelled' ? AppColors.error : AppColors.gold)
                    : AppColors.white.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isActive || isCurrentStep 
                      ? (_currentOrder.status == 'cancelled' ? AppColors.error : AppColors.white)
                      : AppColors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isActive || isCurrentStep 
                      ? (_currentOrder.status == 'cancelled' ? AppColors.error.withOpacity(0.7) : AppColors.white.withOpacity(0.8))
                      : AppColors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isCurrentStep(String title) {
    switch (_currentOrder.status) {
      case 'pending':
        return title == 'Processing';
      case 'processing':
        return title == 'In Progress';
      case 'in_progress':
        return title == 'Out for Delivery';
      case 'out_for_delivery':
        return title == 'Delivered';
      case 'delivered':
        return title == 'Delivered';
      case 'cancelled':
        return false; // Cancelled orders don't have a current step
      default:
        return false;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
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
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  String _getTotalAmountWithTax() {
    // Calculate total amount with tax and fees (same as payment screen)
    final subtotal = _currentOrder.bookingData.calculatedTotalPrice;
    const serviceFee = 2.99;
    const deliveryFee = 0.0;
    const taxRate = 0.20; // 20% tax
    
    final tax = (subtotal + serviceFee + deliveryFee) * taxRate;
    final total = subtotal + serviceFee + deliveryFee + tax;
    
    return total.toStringAsFixed(2);
  }

  String _getOrderStatusText() {
    switch (_currentOrder.status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'in_progress':
        return 'In Progress';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
