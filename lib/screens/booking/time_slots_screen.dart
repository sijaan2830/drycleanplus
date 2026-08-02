import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/time_slot_model.dart';
import '../../providers/time_slot_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/skeleton_loading.dart';
import '../../utils/route_helpers.dart';
import 'address_selection_screen.dart';
import 'booking_overview_screen.dart';
import 'contact_info_screen.dart';
import 'payment_screen.dart';
import 'booking_confirmation_screen.dart';

class TimeSlotsScreen extends StatefulWidget {
  final bool isEditMode;
  
  const TimeSlotsScreen({super.key, this.isEditMode = false});

  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  String _selectedCollectionDate = '';
  String _selectedCollectionTime = '';
  String _selectedDeliveryDate = '';
  String _selectedDeliveryTime = '';
  String _collectionMethod = 'Collect from me in person';
  String _deliveryMethod = 'Deliver to me in person';
  String? _selectedCollectionDay;
  String? _selectedDeliveryDay;
  final TextEditingController _instructionsController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize time slots listener for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timeSlotProvider = Provider.of<TimeSlotProvider>(context, listen: false);
      timeSlotProvider.initializeTimeSlotsListener();
      
      // Debug log for available days and slots
      print('=== TimeSlotsScreen: Debug Information ===');
      
      final availableCollectionDays = timeSlotProvider.getAvailableCollectionDays();
      print('Available Collection Days: $availableCollectionDays');
      
      final availableDeliveryDays = timeSlotProvider.getAvailableDeliveryDays();
      print('Available Delivery Days: $availableDeliveryDays');
      
      if (availableCollectionDays.isNotEmpty) {
        _selectedCollectionDate = availableCollectionDays.first;
        final collectionSlots = timeSlotProvider.getAvailableCollectionTimeSlotsForDay(_selectedCollectionDate);
        print('Collection Slots for ${_selectedCollectionDate}: $collectionSlots');
        
        if (collectionSlots.isNotEmpty) {
          _selectedCollectionTime = '${collectionSlots.first.start} - ${collectionSlots.first.end}';
          print('Selected Collection Time: $_selectedCollectionTime');
        }
      }
      
      if (availableDeliveryDays.isNotEmpty) {
        _selectedDeliveryDate = availableDeliveryDays.first;
        final deliverySlots = timeSlotProvider.getAvailableDeliveryTimeSlotsForDay(_selectedDeliveryDate);
        print('Delivery Slots for ${_selectedDeliveryDate}: $deliverySlots');
        
        if (deliverySlots.isNotEmpty) {
          _selectedDeliveryTime = '${deliverySlots.first.start} - ${deliverySlots.first.end}';
          print('Selected Delivery Time: $_selectedDeliveryTime');
        }
      }
      
      // Set loading to false immediately to show data instantly
      setState(() => _isLoading = false);
      print('=== TimeSlotsScreen: Initialization Complete ===');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        title: const Text(
          'Collection & Delivery',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Consumer2<BookingProvider, TimeSlotProvider>(
        builder: (context, bookingProvider, timeSlotProvider, child) {
          if (_isLoading || timeSlotProvider.isLoading) {
            return _buildSkeletonLoading();
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Show selected service info
                if (bookingProvider.selectedService != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_laundry_service, color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Service: ${bookingProvider.selectedService}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Collection Section
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildCollectionSection(timeSlotProvider),
                ),
                
                // Delivery Section  
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildDeliverySection(timeSlotProvider),
                ),

                const SizedBox(height: 12),
                const Text('Add instructions for driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white)),
                const SizedBox(height: 6),
                TextField(
                  controller: _instructionsController,
                  maxLines: 2,
                  onChanged: (value) {
                    // Real-time update to provider
                    bookingProvider.setInstructions(value);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.goldBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.3)),
                  ),
                  style: const TextStyle(color: AppColors.white),
                ),
                const SizedBox(height: 2),
                Text("*Don't add cleaning instructions here", style: TextStyle(color: AppColors.white.withOpacity(0.6), fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20, 
          right: 20, 
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryBlueDark,
          border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.3), width: 1)),
        ),
        child: Consumer<BookingProvider>(
          builder: (context, provider, child) {
            final canProceed = _canProceed();
            return ElevatedButton(
              onPressed: canProceed ? () {
                print('NEXT button clicked!');
                _proceedToBookingOverview(provider);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? AppColors.gold : Colors.grey.withOpacity(0.3),
                foregroundColor: AppColors.primaryBlueDark,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'NEXT', 
                style: TextStyle(
                  color: canProceed ? AppColors.primaryBlueDark : AppColors.white.withOpacity(0.5), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 18
                )
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollectionSection(TimeSlotProvider timeSlotProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Collection Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
        const SizedBox(height: 12),
        
        _buildSummaryItem(
          Icons.calendar_today_outlined,
          _selectedCollectionDate,
          () => _showCollectionDatePicker(timeSlotProvider),
        ),
        
        _buildSummaryItem(
          Icons.access_time,
          _selectedCollectionTime,
          () => _showCollectionTimePicker(timeSlotProvider),
        ),
        
        _buildSummaryItem(
          Icons.person_outline,
          _collectionMethod,
          () => _showMethodPicker(isCollection: true),
        ),
      ],
    );
  }

  Widget _buildDeliverySection(TimeSlotProvider timeSlotProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
        const SizedBox(height: 12),
        
        _buildSummaryItem(
          Icons.calendar_today_outlined,
          _selectedDeliveryDate,
          () => _showDeliveryDatePicker(timeSlotProvider),
        ),
        
        _buildSummaryItem(
          Icons.access_time,
          _selectedDeliveryTime,
          () => _showDeliveryTimePicker(timeSlotProvider),
        ),
        
        _buildSummaryItem(
          Icons.person_outline,
          _deliveryMethod,
          () => _showMethodPicker(isCollection: false),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service info skeleton
          const SkeletonLoading(height: 56, borderRadius: 12),
          const SizedBox(height: 20),
          // Collection time section
          const SkeletonLoading(width: 180, height: 24, borderRadius: 4),
          const SizedBox(height: 20),
          _buildSkeletonSummaryItem(),
          _buildSkeletonSummaryItem(),
          _buildSkeletonSummaryItem(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          // Delivery time section
          const SkeletonLoading(width: 160, height: 24, borderRadius: 4),
          const SizedBox(height: 20),
          _buildSkeletonSummaryItem(),
          _buildSkeletonSummaryItem(),
          _buildSkeletonSummaryItem(),
          const SizedBox(height: 30),
          // Instructions section
          const SkeletonLoading(width: 200, height: 16, borderRadius: 4),
          const SizedBox(height: 8),
          const SkeletonLoading(height: 100, borderRadius: 12),
          const SizedBox(height: 4),
          const SkeletonLoading(width: 220, height: 12, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildSkeletonSummaryItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SkeletonLoading(width: 24, height: 24, borderRadius: 12),
          const SizedBox(width: 16),
          const SkeletonLoading(width: 150, height: 18, borderRadius: 4),
          const Spacer(),
          const SkeletonLoading(width: 28, height: 28, borderRadius: 14),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onEdit,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 0.5),
                ),
                child: const Icon(Icons.edit, color: AppColors.white, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollectionDatePicker(TimeSlotProvider timeSlotProvider) {
    Navigator.of(context).push(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/picker'),
        pageBuilder: (context, animation, secondaryAnimation) => CollectionDatePickerPage(
          currentValue: _selectedCollectionDate,
          timeSlotProvider: timeSlotProvider,
          onSelect: (value) {
            setState(() {
              _selectedCollectionDate = value;
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _showDeliveryDatePicker(TimeSlotProvider timeSlotProvider) {
    Navigator.of(context).push(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/picker'),
        pageBuilder: (context, animation, secondaryAnimation) => DeliveryDatePickerPage(
          currentValue: _selectedDeliveryDate,
          timeSlotProvider: timeSlotProvider,
          onSelect: (value) {
            setState(() {
              _selectedDeliveryDate = value;
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _showCollectionTimePicker(TimeSlotProvider timeSlotProvider) {
    Navigator.of(context).push(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/picker'),
        pageBuilder: (context, animation, secondaryAnimation) => CollectionTimePickerPage(
          dayLabel: _selectedCollectionDate,
          currentValue: _selectedCollectionTime,
          timeSlotProvider: timeSlotProvider,
          onSelect: (value) {
            setState(() {
              _selectedCollectionTime = value;
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _showDeliveryTimePicker(TimeSlotProvider timeSlotProvider) {
    Navigator.of(context).push(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/picker'),
        pageBuilder: (context, animation, secondaryAnimation) => DeliveryTimePickerPage(
          dayLabel: _selectedDeliveryDate,
          currentValue: _selectedDeliveryTime,
          timeSlotProvider: timeSlotProvider,
          onSelect: (value) {
            setState(() {
              _selectedDeliveryTime = value;
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          );
        },
      ),
    );
  }

  bool _canProceed() {
    return _selectedCollectionDate.isNotEmpty &&
           _selectedCollectionTime.isNotEmpty &&
           _selectedDeliveryDate.isNotEmpty &&
           _selectedDeliveryTime.isNotEmpty;
  }

  void _proceedToBookingOverview(BookingProvider provider) {
    if (_canProceed()) {
      // Update booking data with selected dates and times
      provider.setCollectionDateTime(_selectedCollectionDate, _selectedCollectionTime);
      provider.setDeliveryDateTime(_selectedDeliveryDate, _selectedDeliveryTime);
      provider.setInstructions(_instructionsController.text);
      
      print('Proceeding to booking overview...');
      print('Has user address: ${provider.hasUserDefaultAddress}');
      print('Has user contact info: ${provider.hasUserContactInfo}');
      
      // Check if user has a saved address
      if (provider.hasUserDefaultAddress || provider.bookingData.selectedAddress != null) {
        // User has address, check contact info
        if (provider.hasUserContactInfo) {
          // User has both address and contact info, go directly to booking overview
          Navigator.of(context).pushNamed('/booking_overview');
        } else {
          // User has address but no contact info, show contact info page
          Navigator.of(context).pushNamed('/contact_info');
        }
      } else {
        // User has no address, show address selection page (from booking flow)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddressSelectionScreen(isFromBookingFlow: true),
          ),
        );
      }
    }
  }

  void _showMethodPicker({required bool isCollection}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryBlueDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.gold, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select ${isCollection ? 'collection' : 'delivery'} method',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
                    ),
                    Text(
                      'Select preference',
                      style: TextStyle(color: AppColors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._getMethodOptions(isCollection).map((m) {
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isCollection) {
                      _collectionMethod = m;
                    } else {
                      _deliveryMethod = m;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.goldBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCollection ? Icons.person_outline : Icons.delivery_dining_outlined,
                        color: AppColors.gold,
                        size: 22,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        m,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<String> _getMethodOptions(bool isCollection) {
    if (isCollection) {
      return [
        'Collect from me in person',
        'Collect from outside',
        'Collect from reception/porter',
      ];
    } else {
      return [
        'Deliver to me in person',
        'Deliver outside',
        'Deliver to reception/porter',
      ];
    }
  }
}

class CollectionDatePickerPage extends StatelessWidget {
  final String currentValue;
  final TimeSlotProvider timeSlotProvider;
  final ValueChanged<String> onSelect;

  const CollectionDatePickerPage({
    super.key,
    required this.currentValue,
    required this.timeSlotProvider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final allDays = timeSlotProvider.collectionDaySchedules.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select a day', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                        const SizedBox(height: 4),
                        Text('Select collection day', style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 15)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: allDays.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.white.withOpacity(0.1), height: 1),
                itemBuilder: (context, index) {
                  final day = allDays[index];
                  final isSelected = day.name == currentValue;
                  final isDayOpen = day.isOpen;
                  
                  return InkWell(
                    onTap: isDayOpen ? () {
                      onSelect(day.name);
                      Navigator.pop(context);
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: isSelected && isDayOpen
                          ? BoxDecoration(
                              color: AppColors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              day.name,
                              style: TextStyle(
                               fontSize: 17,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                                color: isDayOpen ? AppColors.white : AppColors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                          if (isDayOpen)
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryDatePickerPage extends StatelessWidget {
  final String currentValue;
  final TimeSlotProvider timeSlotProvider;
  final ValueChanged<String> onSelect;

  const DeliveryDatePickerPage({
    super.key,
    required this.currentValue,
    required this.timeSlotProvider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final allDays = timeSlotProvider.deliveryDaySchedules.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select a day', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                        const SizedBox(height: 4),
                        Text('Select delivery day', style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 15)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: allDays.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.white.withOpacity(0.1), height: 1),
                itemBuilder: (context, index) {
                  final day = allDays[index];
                  final isSelected = day.name == currentValue;
                  final isDayOpen = day.isOpen;
                  
                  return InkWell(
                    onTap: isDayOpen ? () {
                      onSelect(day.name);
                      Navigator.pop(context);
                    } : null,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: isSelected && isDayOpen
                          ? BoxDecoration(
                              color: AppColors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              day.name,
                              style: TextStyle(
                               fontSize: 17,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                                color: isDayOpen ? AppColors.white : AppColors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                          if (isDayOpen)
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionTimePickerPage extends StatelessWidget {
  final String dayLabel;
  final String currentValue;
  final TimeSlotProvider timeSlotProvider;
  final ValueChanged<String> onSelect;

  const CollectionTimePickerPage({
    super.key,
    required this.dayLabel,
    required this.currentValue,
    required this.timeSlotProvider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dayId = _getDayIdFromLabel(dayLabel);
    final allSlots = timeSlotProvider.getCollectionTimeSlotsForDay(dayId);
    
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('For $dayLabel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                        const SizedBox(height: 4),
                        Text('Select collection time', style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 15)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: allSlots.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.white.withOpacity(0.1), height: 1),
                itemBuilder: (context, index) {
                  final slot = allSlots[index];
                  final slotLabel = '${slot.start} - ${slot.end}';
                  final isSelected = slotLabel == currentValue;
                  final isSlotAvailable = slot.isAvailable;
                  
                  return InkWell(
                    onTap: isSlotAvailable ? () {
                      onSelect(slotLabel);
                      Navigator.pop(context);
                    } : null,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: isSelected && isSlotAvailable
                          ? BoxDecoration(
                              color: AppColors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      slotLabel,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isSlotAvailable ? AppColors.white : AppColors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  // Slot Counter Badge
                                  if (isSlotAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: slot.availableSlots <= 2 ? Colors.red[50] : Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            size: 14,
                                            color: slot.availableSlots <= 2 ? Colors.red : Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${slot.availableSlots}/${slot.maxSlots}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: slot.availableSlots <= 2 ? Colors.red[700] : Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isSlotAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'FULL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (isSlotAvailable)
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getDayIdFromLabel(String dayLabel) {
    final dayMap = {
      'Monday': 'monday',
      'Tuesday': 'tuesday',
      'Wednesday': 'wednesday',
      'Thursday': 'thursday',
      'Friday': 'friday',
      'Saturday': 'saturday',
      'Sunday': 'sunday',
    };
    return dayMap[dayLabel] ?? dayLabel.toLowerCase();
  }
}

class DeliveryTimePickerPage extends StatelessWidget {
  final String dayLabel;
  final String currentValue;
  final TimeSlotProvider timeSlotProvider;
  final ValueChanged<String> onSelect;

  const DeliveryTimePickerPage({
    super.key,
    required this.dayLabel,
    required this.currentValue,
    required this.timeSlotProvider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dayId = _getDayIdFromLabel(dayLabel);
    final allSlots = timeSlotProvider.getDeliveryTimeSlotsForDay(dayId);
    
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('For $dayLabel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                        const SizedBox(height: 4),
                        Text('Select delivery time', style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 15)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: allSlots.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.white.withOpacity(0.1), height: 1),
                itemBuilder: (context, index) {
                  final slot = allSlots[index];
                  final slotLabel = '${slot.start} - ${slot.end}';
                  final isSelected = slotLabel == currentValue;
                  final isSlotAvailable = slot.isAvailable;
                  
                  return InkWell(
                    onTap: isSlotAvailable ? () {
                      onSelect(slotLabel);
                      Navigator.pop(context);
                    } : null,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: isSelected && isSlotAvailable
                          ? BoxDecoration(
                              color: AppColors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      slotLabel,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isSlotAvailable ? AppColors.white : AppColors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  // Slot Counter Badge
                                  if (isSlotAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: slot.availableSlots <= 2 ? Colors.red[50] : Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            size: 14,
                                            color: slot.availableSlots <= 2 ? Colors.red : Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${slot.availableSlots}/${slot.maxSlots}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: slot.availableSlots <= 2 ? Colors.red[700] : Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isSlotAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'FULL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (isSlotAvailable)
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getDayIdFromLabel(String dayLabel) {
    final dayMap = {
      'Monday': 'monday',
      'Tuesday': 'tuesday',
      'Wednesday': 'wednesday',
      'Thursday': 'thursday',
      'Friday': 'friday',
      'Saturday': 'saturday',
      'Sunday': 'sunday',
    };
    return dayMap[dayLabel] ?? dayLabel.toLowerCase();
  }
}
