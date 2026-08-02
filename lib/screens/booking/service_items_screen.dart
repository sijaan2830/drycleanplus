import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_models.dart';

class ServiceItemsScreen extends StatefulWidget {
  const ServiceItemsScreen({super.key});

  @override
  State<ServiceItemsScreen> createState() => _ServiceItemsScreenState();
}

class _ServiceItemsScreenState extends State<ServiceItemsScreen> {
  Map<String, int> _itemQuantities = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Select Items',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Consumer<BookingProvider>(
          builder: (context, provider, child) {
            final selectedService = provider.selectedService;
            final serviceItems = selectedService != null
                ? provider.getServiceItems(selectedService)
                : <ServiceItem>[];

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServiceTitle(selectedService),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select items and quantities for your order',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: serviceItems.length,
                    itemBuilder: (context, index) {
                      final item = serviceItems[index];
                      final quantity = _itemQuantities[item.uniqueKey] ?? 0;
                      
                      return _buildItemCard(item, quantity);
                    },
                  ),
                ),
                // Bottom section with total and continue button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Items: ${_getTotalItems()}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Total: £${_getTotalPrice().toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0066FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _getTotalItems() > 0
                              ? () {
                                  _saveSelectedItems(context);
                                  Navigator.of(context).pushNamed('/address_selection');
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Continue to Address',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(ServiceItem item, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemType,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0066FF),
                  ),
                ),
              ],
            ),
          ),
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: quantity > 0
                      ? () {
                          setState(() {
                            if (quantity > 1) {
                              _itemQuantities[item.uniqueKey] = quantity - 1;
                            } else {
                              _itemQuantities.remove(item.uniqueKey);
                            }
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove, size: 20),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    quantity.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _itemQuantities[item.uniqueKey] = quantity + 1;
                    });
                  },
                  icon: const Icon(Icons.add, size: 20),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceTitle(String? service) {
    switch (service) {
      case 'Dry Clean':
        return 'Dry Clean Service';
      case 'Duvets & Bedding':
        return 'Duvets & Bedding Service';
      case 'Household Items':
        return 'Household Items Service';
      case 'Laundry & Ironing':
        return 'Laundry & Ironing Service';
      default:
        return 'Select Items';
    }
  }

  int _getTotalItems() {
    return _itemQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  double _getTotalPrice() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final selectedService = provider.selectedService;
    if (selectedService == null) return 0.0;

    final serviceItems = provider.getServiceItems(selectedService);
    double total = 0.0;

    _itemQuantities.forEach((key, quantity) {
      final item = serviceItems.firstWhere(
        (item) => item.uniqueKey == key,
        orElse: () => ServiceItem(
          category: '',
          itemType: '',
          price: '0.00',
        ),
      );
      total += item.numericPrice * quantity;
    });

    return total;
  }

  void _saveSelectedItems(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final selectedService = provider.selectedService;
    if (selectedService == null) return;

    final serviceItems = provider.getServiceItems(selectedService);
    final Map<String, ServiceItem> selectedItems = {};

    _itemQuantities.forEach((key, quantity) {
      if (quantity > 0) {
        final item = serviceItems.firstWhere(
          (item) => item.uniqueKey == key,
        );
        
        // Add the item multiple times based on quantity
        for (int i = 0; i < quantity; i++) {
          final uniqueKeyWithQuantity = '${item.uniqueKey}_$i';
          selectedItems[uniqueKeyWithQuantity] = item;
        }
      }
    });

    // Update provider with selected items
    final updatedBookingData = provider.bookingData.copyWith(
      selectedItems: selectedItems,
      totalPrice: _getTotalPrice(),
    );
    provider.updateBookingData(updatedBookingData);
  }
}
