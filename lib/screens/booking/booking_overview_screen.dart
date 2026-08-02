import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_models.dart';
import '../../widgets/skeleton_loading.dart';
import '../service_overview_screen.dart';
import 'time_slots_screen.dart';
import 'address_selection_screen.dart';
import 'contact_info_screen.dart';
import 'payment_screen.dart';

class BookingOverviewScreen extends StatefulWidget {
  const BookingOverviewScreen({super.key});

  @override
  State<BookingOverviewScreen> createState() => _BookingOverviewScreenState();
}

class _BookingOverviewScreenState extends State<BookingOverviewScreen> {
  bool _isLoading = true;
  bool _showCouponField = false;
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBlueDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Cancel Order',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            'Are you sure you want to cancel this order?',
            style: TextStyle(fontSize: 14, color: AppColors.white.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'No',
                style: TextStyle(color: AppColors.white.withOpacity(0.5), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Provider.of<BookingProvider>(context, listen: false).clearBookingData();
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        title: const Text(
          'Review order',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _showCancelConfirmation(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          final bookingData = provider.bookingData;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Summary
                  if (_isLoading)
                    _buildPriceSkeleton()
                  else
                    _buildPriceSummary(bookingData, context, provider),

                  const SizedBox(height: 24),
                  _goldDivider(),
                  const SizedBox(height: 24),

                  // Order Details
                  const Text(
                    'Order details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white),
                  ),
                  const SizedBox(height: 20),

                  // Collection
                  _sectionHeader(
                    title: 'Collection',
                    onEdit: () => _navigateTo(context, const TimeSlotsScreen(isEditMode: true), '/time_slots'),
                  ),
                  const SizedBox(height: 8),
                  Consumer<BookingProvider>(
                    builder: (context, p, _) => Text(
                      '${p.bookingData.collectionDate ?? 'Not selected'}, ${p.bookingData.collectionTime ?? 'Not selected'}\nCollect from me in person',
                      style: const TextStyle(color: AppColors.white, height: 1.45, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delivery
                  const Text(
                    'Delivery',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.white),
                  ),
                  const SizedBox(height: 6),
                  Consumer<BookingProvider>(
                    builder: (context, p, _) => Text(
                      '${p.bookingData.deliveryDate ?? 'Not selected'}, ${p.bookingData.deliveryTime ?? 'Not selected'}\nDeliver to me in person',
                      style: const TextStyle(color: AppColors.white, height: 1.45, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _goldDivider(),
                  const SizedBox(height: 24),

                  // Services
                  _sectionHeader(
                    title: 'Services',
                    onEdit: () {
                      final svc = Provider.of<BookingProvider>(context, listen: false).selectedService ?? 'Dry Clean';
                      _navigateTo(context, ServiceOverviewScreen(serviceType: svc, isEditMode: true), '/service_overview');
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<BookingProvider>(
                    builder: (context, p, _) {
                      final Map<String, List<ServiceItem>> grouped = {};
                      for (var item in p.bookingData.selectedItems.values) {
                        grouped.putIfAbsent(item.category, () => []).add(item);
                      }
                      return Column(
                        children: grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _serviceHeader(entry.key),
                              const SizedBox(height: 12),
                              ...entry.value.map((item) => _serviceItemRow(item)),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),

                  _dimDivider(),
                  const SizedBox(height: 24),

                  // Collection Address
                  _sectionHeader(
                    title: 'Collection address',
                    onEdit: () => _navigateTo(context, const AddressSelectionScreen(isEditMode: true), '/address_selection'),
                  ),
                  const SizedBox(height: 8),
                  Consumer<BookingProvider>(
                    builder: (context, p, _) => Text(
                      p.bookingData.selectedAddress?.fullAddress ?? 'No address selected',
                      style: const TextStyle(color: AppColors.white, height: 1.45, fontSize: 14),
                    ),
                  ),

                  _dimDivider(),
                  const SizedBox(height: 24),

                  // Contact Information
                  _sectionHeader(
                    title: 'Contact information',
                    titleColor: AppColors.gold,
                    onEdit: () => _navigateTo(context, const ContactInfoScreen(isEditMode: true), '/contact_info'),
                  ),
                  const SizedBox(height: 8),
                  Consumer<BookingProvider>(
                    builder: (context, p, _) => Text(
                      '${p.bookingData.firstName} ${p.bookingData.lastName}\n${p.bookingData.phone}',
                      style: const TextStyle(color: AppColors.white, height: 1.45, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      bottomSheet: _buildBottomPayButton(),
    );
  }

  // ─── Navigation helper ───────────────────────────────────────────────────

  Future<void> _navigateTo(BuildContext context, Widget screen, String routeName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (_) => screen,
      ),
    );
  }

  bool _validateOrder(BookingData data) {
    if (data.selectedAddress == null) {
      _showWarning('Please select a collection address');
      return false;
    }
    
    // Check collection date/time
    if (data.collectionDate == null || data.collectionDate!.isEmpty || 
        data.collectionTime == null || data.collectionTime!.isEmpty) {
      _showWarning('Please select a collection date and time');
      return false;
    }
    
    // Check delivery date/time
    if (data.deliveryDate == null || data.deliveryDate!.isEmpty || 
        data.deliveryTime == null || data.deliveryTime!.isEmpty) {
      _showWarning('Please select a delivery date and time');
      return false;
    }
    
    // Check contact info
    if (data.firstName.trim().isEmpty || data.phone.trim().isEmpty) {
      _showWarning('Please complete your contact information (Name & Phone)');
      return false;
    }
    
    return true;
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Dividers ────────────────────────────────────────────────────────────

  Widget _goldDivider() => Container(height: 1.5, color: AppColors.goldBorder);

  Widget _dimDivider() => Container(height: 1, color: Colors.white.withOpacity(0.1));

  // ─── Section header row ──────────────────────────────────────────────────

  Widget _sectionHeader({
    required String title,
    Color? titleColor,
    VoidCallback? onEdit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: titleColor ?? AppColors.white,
          ),
        ),
        if (onEdit != null) _editButton(onPressed: onEdit),
      ],
    );
  }

  // ─── Edit button ─────────────────────────────────────────────────────────

  Widget _editButton({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed ?? () {},
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: const Icon(Icons.edit, color: AppColors.primaryBlueDark, size: 12),
      ),
    );
  }

  // ─── Service header with icon ─────────────────────────────────────────────

  Widget _serviceHeader(String service) {
    final IconData icon;
    switch (service.toLowerCase()) {
      case 'dry clean':         icon = Icons.dry_cleaning; break;
      case 'laundry & ironing': icon = Icons.iron; break;
      case 'duvets & bedding':  icon = Icons.bed; break;
      case 'household items':   icon = Icons.home; break;
      default:                  icon = Icons.local_laundry_service;
    }

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBlueDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withOpacity(0.45), width: 1),
          ),
          child: Icon(icon, color: AppColors.gold, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text('Selected service', style: TextStyle(color: AppColors.white.withOpacity(0.5), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // ─── Individual service item row ──────────────────────────────────────────

  Widget _serviceItemRow(ServiceItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 20),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1),
            ),
            child: const Icon(Icons.dry_cleaning, color: AppColors.gold, size: 11),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemType, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('£${item.price} · No special request', style: TextStyle(color: AppColors.white.withOpacity(0.55), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Price skeleton ───────────────────────────────────────────────────────

  Widget _buildPriceSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          SkeletonLoading(width: 140, height: 20, borderRadius: 4),
          SkeletonLoading(width: 60, height: 20, borderRadius: 4),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          SkeletonLoading(width: 60, height: 14, borderRadius: 4),
          SkeletonLoading(width: 40, height: 14, borderRadius: 4),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          SkeletonLoading(width: 70, height: 14, borderRadius: 4),
          SkeletonLoading(width: 40, height: 14, borderRadius: 4),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          SkeletonLoading(width: 80, height: 14, borderRadius: 4),
          SkeletonLoading(width: 40, height: 14, borderRadius: 4),
        ]),
      ],
    );
  }

  // ─── Price summary ────────────────────────────────────────────────────────

  Widget _buildPriceSummary(BookingData bookingData, BuildContext context, BookingProvider provider) {
    final subtotal = bookingData.subtotal;
    final discount = bookingData.discountAmount;
    final discountedSubtotal = bookingData.discountedSubtotal;
    const serviceFee = 2.99;
    const deliveryFee = 0.0;
    final preTaxTotal = discountedSubtotal + serviceFee + deliveryFee;
    final taxAmount = preTaxTotal * 0.20;
    final total = preTaxTotal + taxAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Pay now (incl. 20% tax)',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white),
            ),
            Text(
              '£${total.toStringAsFixed(2)}',
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gold),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Price rows
        _priceRow('Subtotal', '£${subtotal.toStringAsFixed(2)}'),
        if (discount > 0)
          _priceRow('Discount (${bookingData.discountCode})', '-£${discount.toStringAsFixed(2)}', isDiscount: true),
        _priceRow('Service fee', '£${serviceFee.toStringAsFixed(2)}'),
        _priceRow('Delivery fee', deliveryFee == 0.0 ? 'FREE' : '£${deliveryFee.toStringAsFixed(2)}'),
        _priceRow('Tax (20%)', '£${taxAmount.toStringAsFixed(2)}'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _goldDivider(),
        ),
        _priceRow('Total', '£${total.toStringAsFixed(2)}', isTotal: true),

        const SizedBox(height: 20),

        // Coupon Toggle
        GestureDetector(
          onTap: () => setState(() => _showCouponField = !_showCouponField),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: Row(
              children: [
                Icon(
                  _showCouponField ? Icons.keyboard_arrow_up : Icons.local_offer_outlined,
                  color: AppColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Have a coupon code?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withOpacity(_showCouponField ? 1.0 : 0.7),
                  ),
                ),
                const Spacer(),
                Icon(
                  _showCouponField ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  color: AppColors.gold.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        if (_showCouponField || bookingData.discountCode != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 1.5),
                  ),
                  child: TextField(
                    controller: _couponController,
                    enabled: bookingData.discountCode == null,
                    cursorColor: AppColors.gold,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withOpacity(0.35)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      filled: true,
                      fillColor: AppColors.primaryBlueDark,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      prefixIcon: Icon(Icons.confirmation_num_outlined, color: AppColors.gold.withOpacity(0.8), size: 18),
                    ),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 1.5),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: bookingData.discountCode != null
                      ? null
                      : () async {
                          final result = await provider.applyCoupon(_couponController.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: result['success'] ? Colors.green : Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.primaryBlueDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                  ),
                  child: Text(
                    bookingData.discountCode != null ? 'Applied' : 'Apply',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
          if (bookingData.discountCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Coupon ${bookingData.discountCode} applied',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isDiscount ? Colors.greenAccent : AppColors.white,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isTotal ? AppColors.gold : (isDiscount ? Colors.greenAccent : AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom pay button ────────────────────────────────────────────────────

  Widget _buildBottomPayButton() {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final bookingData = provider.bookingData;
        final discountedSubtotal = bookingData.discountedSubtotal;
        const serviceFee = 2.99;
        const deliveryFee = 0.0;
        final preTaxTotal = discountedSubtotal + serviceFee + deliveryFee;
        final taxAmount = preTaxTotal * 0.20;
        final total = preTaxTotal + taxAmount;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.primaryBlueDark,
            border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.3))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: bookingData.selectedItems.isNotEmpty
                    ? () {
                        if (_validateOrder(bookingData)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PaymentScreen(amount: total)),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.primaryBlueDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'PAY NOW  £${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}