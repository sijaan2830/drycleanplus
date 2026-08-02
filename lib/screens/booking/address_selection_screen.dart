import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/booking_models.dart';
import '../../config/theme.dart';
import 'add_address_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  final bool isEditMode;
  final bool isFromBookingFlow;
  
  const AddressSelectionScreen({super.key, this.isEditMode = false, this.isFromBookingFlow = false});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  int _selectedIndex = 2;
  Address? _selectedAddress;

  bool _hasCheckedDefault = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedDefault) {
      _hasCheckedDefault = true;
      _checkForDefaultAddress();
    }
  }

  void _checkForDefaultAddress() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isFromBookingFlow = (args != null && args['isFromBookingFlow'] == true) || widget.isFromBookingFlow;
    
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Check if user has a saved address in their profile (from account page)
    if (userProvider.hasAddress && !widget.isEditMode) {
      // Create an Address object from the saved user profile data
      final savedAddress = Address(
        id: userProvider.savedAddressId ?? 'user_profile_address',
        line1: userProvider.savedAddressLine1!,
        line2: userProvider.savedAddressLine2,
        city: userProvider.savedCity ?? '',
        postalCode: userProvider.savedPostcode!,
        isDefault: true,
      );
      
      // Set it as the default address in booking provider
      bookingProvider.setUserDefaultAddress(savedAddress);
      
      if (isFromBookingFlow) {
        // Go to contact info
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/contact_info', arguments: {'isFromBookingFlow': true});
        });
      } else {
        // Go to service selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/service_selection');
        });
      }
      return;
    }
    
    // If user already has a default address in booking provider and not in edit mode, skip this page
    if (bookingProvider.hasUserDefaultAddress && !widget.isEditMode && !isFromBookingFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/service_selection');
      });
      return;
    }
    
    // If from booking flow and user has address in booking provider, check contact info
    if (isFromBookingFlow && bookingProvider.hasUserDefaultAddress) {
      // User has address, check if they have contact info
      if (bookingProvider.hasUserContactInfo) {
        // User has both address and contact info, go directly to booking overview
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/booking_overview', arguments: {'isFromBookingFlow': true});
        });
      } else {
        // User has address but no contact info, go to contact info
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/contact_info', arguments: {'isFromBookingFlow': true});
        });
      }
      return;
    }
    
    // Load existing addresses from provider
    _loadAddressesFromProvider();
  }

  void _loadAddressesFromProvider() {
    // Don't add default addresses - only show real-time added addresses
    // Users will need to add their own addresses
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Your addresses',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.gold, height: 1.0),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          // Use userAddresses from Firestore instead of bookingData.addresses
          final addresses = provider.userAddresses;
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Saved Addresses',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We will use the default address for processing your orders, unless you choose a different one from the list below.',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Address Cards
                      ...addresses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final address = entry.value;
                        final isSelected = _selectedAddress == address;
                        
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedAddress = address;
                            Provider.of<BookingProvider>(context, listen: false).setUserDefaultAddress(address);
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: isSelected 
                              ? AppCardDecoration.selectedCardDecoration
                              : AppCardDecoration.blueCardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.5),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      address.buildingName ?? 'Address (home)',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () async {
                                        // TODO: Navigate to edit address screen
                                        // For now, just show a snackbar
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Edit address functionality coming soon'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.gold, width: 1.5),
                                          borderRadius: BorderRadius.circular(20),
                                          color: AppColors.primaryBlueDark,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          child: Text(
                                            'Edit',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36, top: 8),
                                  child: Text(
                                    address.fullAddress,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (address.buildingName?.isNotEmpty == true) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 36, top: 12),
                                    child: Container(
                                      height: 1,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 36, top: 8),
                                    child: Text(
                                      address.buildingName!,
                                      style: TextStyle(
                                        color: AppColors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Divider(thickness: 1, color: AppColors.gold),
                      ),
                      
                      Text(
                        'Other addresses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddAddressScreen(),
                              ),
                            );
                            setState(() {
                              final provider = Provider.of<BookingProvider>(context, listen: false);
                              _selectedAddress = provider.bookingData.selectedAddress;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.gold, size: 24),
                          label: const Text(
                            'Add a new address',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Sticky Footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueDark,
                  border: Border(top: BorderSide(color: AppColors.gold, width: 1.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '* Changing the address might affect your selected services and timeslots.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _selectedAddress != null
                            ? () async {
                                // Check if we're in booking flow from arguments
                                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                                final isFromBookingFlow = args?['isFromBookingFlow'] == true || widget.isFromBookingFlow;
                                
                                // Save address permanently to user profile
                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                await userProvider.saveAddressData(
                                  addressId: _selectedAddress!.id,
                                  addressLine1: _selectedAddress!.line1,
                                  addressLine2: _selectedAddress!.line2,
                                  city: _selectedAddress!.city,
                                  postcode: _selectedAddress!.postalCode,
                                );
                                
                                if (widget.isEditMode) {
                                  // Return to account page after editing address
                                  Navigator.of(context).pop();
                                } else if (isFromBookingFlow) {
                                  Navigator.of(context).pushNamed('/contact_info', arguments: {'isFromBookingFlow': true});
                                } else {
                                  Navigator.of(context).pushNamed('/service_selection');
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedAddress != null
                              ? AppColors.primaryBlue
                              : AppColors.grey,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.gold, width: 1.5),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'SELECT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
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
    );
  }
}
