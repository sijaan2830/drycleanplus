import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_models.dart';
import '../../widgets/app_ui.dart';

class ServiceItemsScreen extends StatefulWidget {
  const ServiceItemsScreen({super.key});

  @override
  State<ServiceItemsScreen> createState() => _ServiceItemsScreenState();
}

class _ServiceItemsScreenState extends State<ServiceItemsScreen> {
  final Map<String, int> _itemQuantities = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlueDark,
      appBar: AppBar(
        title: Text(
          'Select Items',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlueDark,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: AppBackground(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select items and quantities for your order',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            color: Colors.white.withOpacity(0.82),
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
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueDeep,
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.18), width: 1.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Total: £${_getTotalPrice().toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
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
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primaryBlueDark,
                              disabledBackgroundColor: Colors.white.withOpacity(0.2),
                              disabledForegroundColor: Colors.white.withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Continue to Address',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildItemCard(ServiceItem item, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
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
                  icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _itemQuantities[item.uniqueKey] = quantity + 1;
                    });
                  },
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceTitle(String? service) {
    if (service == null || service.isEmpty) return 'Service';
    return service;
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

    for (final item in serviceItems) {
      final quantity = _itemQuantities[item.uniqueKey] ?? 0;
      if (quantity > 0) {
        final priceString = item.price.replaceAll('£', '');
        final price = double.tryParse(priceString) ?? 0.0;
        total += price * quantity;
      }
    }

    return total;
  }

  void _saveSelectedItems(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final selectedService = provider.selectedService;
    if (selectedService == null) return;

    final serviceItems = provider.getServiceItems(selectedService);
    for (final item in serviceItems) {
      final quantity = _itemQuantities[item.uniqueKey] ?? 0;
      if (quantity > 0) {
        provider.setServiceItemQuantity(item, quantity);
      }
    }
  }
}
