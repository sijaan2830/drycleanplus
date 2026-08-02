import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_models.dart' as models;
import '../models/services_data.dart';
import '../services/firestore_service.dart';

class BookingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  models.BookingData _bookingData = models.BookingData();
  List<models.Order> _orders = [];
  bool _isLoading = false;
  String? _selectedService;
  
  // User profile data
  models.Address? _userDefaultAddress;
  List<models.Address> _userAddresses = [];
  String _userFirstName = '';
  String _userLastName = '';
  String _userEmail = '';
  String _userPhone = '';
  int _userOrderCount = 0;
  List<String> _userUsedCoupons = [];
  
  // Stream subscriptions
  StreamSubscription? _addressesSubscription;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _userDataSubscription;

  models.BookingData get bookingData => _bookingData;
  List<models.Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get selectedService => _selectedService;
  models.Address? get userDefaultAddress => _userDefaultAddress;
  List<models.Address> get userAddresses => _userAddresses;
  String get userFirstName => _userFirstName;
  String get userLastName => _userLastName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  int get userOrderCount => _userOrderCount;
  
  // Generate formatted order ID: DC202600001, DC202600002, etc.
  Future<String> _generateOrderId() async {
    try {
      final currentYear = DateTime.now().year;
      final yearPrefix = 'DC${currentYear.toString().substring(2)}'; // DC2026
      
      // Get and increment order counter from Firestore
      final counterDoc = FirebaseFirestore.instance.collection('counters').doc('orders');
      
      // Use transaction to ensure atomic increment
      String orderId = '';
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterDoc);
        
        if (!snapshot.exists) {
          // Initialize counter if it doesn't exist
          transaction.set(counterDoc, {'currentNumber': 1});
          orderId = '$yearPrefix${1.toString().padLeft(6, '0')}';
        } else {
          final currentNumber = snapshot.get('currentNumber') as int;
          final nextNumber = currentNumber + 1;
          transaction.update(counterDoc, {'currentNumber': nextNumber});
          orderId = '$yearPrefix${nextNumber.toString().padLeft(6, '0')}';
        }
      });
      
      print('Generated order ID: $orderId');
      return orderId;
    } catch (e) {
      print('Error generating order ID: $e');
      // Fallback to timestamp-based ID
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'DC$timestamp';
    }
  }

  // Service items mapped from ServicesData
  static const Map<String, List<models.ServiceItem>> _serviceItems = {
    'Dry Clean': [
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Suit', price: '£8.95'),
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Coat', price: '£7.95'),
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Dress', price: '£5.95'),
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Blouse', price: '£3.95'),
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Shirt', price: '£3.45'),
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Trousers', price: '£4.45'),
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Skirt', price: '£3.95'),
      const models.ServiceItem(category: 'Dry Clean', itemType: 'Jacket', price: '£5.95'),
    ],
    'Duvets & Bedding': [
      const models.ServiceItem(category: 'Duvets & Bedding', itemType: 'Single Duvet', price: '£11.95'),
      const models.ServiceItem(category: 'Duvets & Bedding', itemType: 'Double Duvet', price: '£15.95'),
      const models.ServiceItem(category: 'Duvets & Bedding', itemType: 'King Duvet', price: '£19.95'),
      const models.ServiceItem(category: 'Duvets & Bedding', itemType: 'Super King Duvet', price: '£24.95'),
      const models.ServiceItem(category: 'Duvets & Bedding', itemType: 'Pillows', price: '£6.95'),
      const models.ServiceItem(category: 'Duvets & Bedding', itemType: 'Bedspread', price: '£12.95'),
    ],
    'Household Items': [
      const models.ServiceItem(category: 'Household Items', itemType: 'Curtains', price: '£15.95'),
      const models.ServiceItem(category: 'Household Items', itemType: 'Tablecloth', price: '£8.95'),
      const models.ServiceItem(category: 'Household Items', itemType: 'Small Rug', price: '£15.95'),
      const models.ServiceItem(category: 'Household Items', itemType: 'Large Rug', price: '£25.95'),
      const models.ServiceItem(category: 'Household Items', itemType: 'Throw', price: '£9.95'),
    ],
    'Laundry & Ironing': [
      const models.ServiceItem(category: 'Laundry & Ironing', itemType: 'T-Shirt', price: '£1.95'),
      const models.ServiceItem(category: 'Laundry & Ironing', itemType: 'Shirt', price: '£2.45'),
      const models.ServiceItem(category: 'Laundry & Ironing', itemType: 'Trousers', price: '£3.45'),
      const models.ServiceItem(category: 'Laundry & Ironing', itemType: 'Jeans', price: '£3.95'),
      const models.ServiceItem(category: 'Laundry & Ironing', itemType: 'Dress', price: '£5.95'),
      const models.ServiceItem(category: 'Laundry & Ironing', itemType: 'Jacket', price: '£4.95'),
      const models.ServiceItem(category: 'Laundry & Ironing', itemType: 'Bed Sheets', price: '£4.95'),
    ],
  };

  static const List<String> _collectionTimeSlots = [
    '8:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 2:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  static const List<String> _deliveryTimeSlots = [
    '8:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 2:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  List<models.ServiceItem> getServiceItems(String serviceType) {
    return _serviceItems[serviceType] ?? [];
  }

  List<String> getCollectionTimeSlots() {
    return _collectionTimeSlots;
  }

  List<String> getDeliveryTimeSlots() {
    return _deliveryTimeSlots;
  }

  void setSelectedService(String service) {
    _selectedService = service;
    notifyListeners();
  }

  void updateBookingData(models.BookingData newData) {
    _bookingData = newData;
    notifyListeners();
  }

  // ==================== FIRESTORE REAL-TIME LISTENERS ====================

  /// Initialize real-time listeners for user data
  void initializeListeners() {
    // Cancel existing subscriptions to prevent duplicates
    _addressesSubscription?.cancel();
    _ordersSubscription?.cancel();
    _userDataSubscription?.cancel();
    
    // Listen to user addresses
    _addressesSubscription = _firestoreService.getAddressesStream().listen(
      (snapshot) {
        _userAddresses = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return models.Address.fromJson({...data, 'id': doc.id});
        }).toList();
        
        // Sort addresses: default first, then by id (as fallback)
        _userAddresses.sort((a, b) {
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          return b.id.compareTo(a.id);
        });
        
        // Set default address
        _userDefaultAddress = _userAddresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _userAddresses.isNotEmpty ? _userAddresses.first : models.Address(
            id: '',
            line1: '',
            city: '',
            postalCode: '',
          ),
        );
        
        // Update booking data with user addresses
        if (_userAddresses.isNotEmpty) {
          _bookingData = _bookingData.copyWith(
            addresses: _userAddresses,
            selectedAddress: _userDefaultAddress,
          );
        }
        
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to addresses: $error');
      },
    );

    // Listen to user orders
    _ordersSubscription = _firestoreService.getOrdersStream().listen(
      (snapshot) {
        _orders = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return models.Order.fromJson({...data, 'id': doc.id});
        }).toList();
        
        // Remove duplicates by ID
        final uniqueOrders = <String, models.Order>{};
        for (final order in _orders) {
          uniqueOrders[order.id] = order;
        }
        _orders = uniqueOrders.values.toList();
        
        // Sort orders by createdAt descending (now done in Dart since we removed orderBy from Firestore)
        _orders.sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          return bDate.compareTo(aDate);
        });
        
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to orders: $error');
      },
    );

    // Listen to user data (contact info, order count)
    _userDataSubscription = _firestoreService.getUserDataStream().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>?;
          if (data != null) {
            _userFirstName = data['firstName'] ?? '';
            _userLastName = data['lastName'] ?? '';
            _userEmail = data['email'] ?? '';
            _userPhone = data['phone'] ?? '';
            _userOrderCount = (data['orderCount'] as int?) ?? 0;
            _userUsedCoupons = data['usedCoupons'] != null 
                ? List<String>.from(data['usedCoupons'])
                : [];
            
            // Update booking data with user contact info
            if (_userFirstName.isNotEmpty) {
              _bookingData = _bookingData.copyWith(
                firstName: _userFirstName,
                lastName: _userLastName,
                email: _userEmail,
                phone: _userPhone,
              );
            }
            
            notifyListeners();
          }
        }
      },
      onError: (error) {
        print('Error listening to user data: $error');
      },
    );
  }

  /// Dispose all stream subscriptions
  @override
  void dispose() {
    _addressesSubscription?.cancel();
    _ordersSubscription?.cancel();
    _userDataSubscription?.cancel();
    super.dispose();
  }

  // ==================== ADDRESS OPERATIONS ====================

  /// Add address to Firestore
  Future<void> addAddress(models.Address address) async {
    try {
      // Convert Address to map to avoid type issues
      final addressMap = address.toJson();
      final addressId = await _firestoreService.addAddress(addressMap);
      if (addressId != null) {
        // The stream will automatically update _userAddresses
        print('Address added successfully: $addressId');
      }
    } catch (e) {
      print('Error adding address: $e');
    }
  }

  /// Update address in Firestore
  Future<void> updateAddress(models.Address address) async {
    try {
      // Convert Address to map to avoid type issues
      final addressMap = address.toJson();
      await _firestoreService.updateAddress(addressMap);
      print('Address updated successfully');
    } catch (e) {
      print('Error updating address: $e');
    }
  }

  /// Delete address from Firestore
  Future<void> removeAddress(String addressId) async {
    try {
      await _firestoreService.deleteAddress(addressId);
      
      // If the removed address was selected, clear the selection
      if (_bookingData.selectedAddress?.id == addressId) {
        _bookingData = _bookingData.copyWith(selectedAddress: null);
      }
      
      print('Address deleted successfully');
    } catch (e) {
      print('Error deleting address: $e');
    }
  }

  void selectAddress(models.Address address) {
    _bookingData = _bookingData.copyWith(selectedAddress: address);
    notifyListeners();
  }

  void selectDeliveryAddress(models.Address address) {
    _bookingData = _bookingData.copyWith(deliveryAddress: address);
    notifyListeners();
  }

  // User profile methods
  void setUserDefaultAddress(models.Address address) {
    _userDefaultAddress = address;
    selectAddress(address);
    notifyListeners();
  }

  void clearUserDefaultAddress() {
    _userDefaultAddress = null;
    notifyListeners();
  }

  bool get hasUserDefaultAddress => _userDefaultAddress != null;
  
  /// Check if user has complete contact info
  bool get hasUserContactInfo => _userFirstName.isNotEmpty && _userLastName.isNotEmpty && _userPhone.isNotEmpty;

  // ==================== CONTACT INFO OPERATIONS ====================

  /// Update contact info in Firestore
  Future<void> updateContactInfoInFirestore({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      await _firestoreService.updateUserContactInfo(
        firstName: firstName ?? _userFirstName,
        lastName: lastName ?? _userLastName,
        email: email ?? _userEmail,
        phone: phone ?? _userPhone,
      );
      
      // Update local state
      _userFirstName = firstName ?? _userFirstName;
      _userLastName = lastName ?? _userLastName;
      _userEmail = email ?? _userEmail;
      _userPhone = phone ?? _userPhone;
      
      notifyListeners();
      print('Contact info updated successfully');
    } catch (e) {
      print('Error updating contact info: $e');
    }
  }

  void updateContactInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? specialInstructions,
    String? customerType,
    String? companyName,
  }) {
    _bookingData = _bookingData.copyWith(
      firstName: firstName ?? _bookingData.firstName,
      lastName: lastName ?? _bookingData.lastName,
      email: email ?? _bookingData.email,
      phone: phone ?? _bookingData.phone,
      specialInstructions: specialInstructions ?? _bookingData.specialInstructions,
      customerType: customerType ?? _bookingData.customerType,
      companyName: companyName ?? _bookingData.companyName,
    );
    notifyListeners();
  }

  // ==================== SERVICE ITEMS ====================

  void addServiceItem(models.ServiceItem item) {
    final updatedItems = Map<String, models.ServiceItem>.from(_bookingData.selectedItems);
    updatedItems[item.uniqueKey] = item;
    
    _bookingData = _bookingData.copyWith(
      selectedItems: updatedItems,
      totalPrice: _bookingData.subtotal,
    );
    notifyListeners();
  }

  void removeServiceItem(String itemKey) {
    final updatedItems = Map<String, models.ServiceItem>.from(_bookingData.selectedItems);
    updatedItems.remove(itemKey);
    
    _bookingData = _bookingData.copyWith(
      selectedItems: updatedItems,
      totalPrice: _bookingData.subtotal,
    );
    notifyListeners();
  }

  void updateServiceItemQuantity(String itemKey, int quantity) {
    if (quantity <= 0) {
      removeServiceItem(itemKey);
      return;
    }
    
    final item = _bookingData.selectedItems[itemKey];
    if (item != null) {
      final updatedItems = Map<String, models.ServiceItem>.from(_bookingData.selectedItems);
      notifyListeners();
    }
  }

  // ==================== DATE/TIME ====================

  void setCollectionDateTime(String date, String time) {
    _bookingData = _bookingData.copyWith(
      collectionDate: date,
      collectionTime: time,
    );
    notifyListeners();
    
    // Save to Firestore
    _firestoreService.saveTimeSlotSelection(
      collectionDate: date,
      collectionTime: time,
      deliveryDate: _bookingData.deliveryDate ?? '',
      deliveryTime: _bookingData.deliveryTime ?? '',
      collectionMethod: _bookingData.collectionMethod ?? '',
      deliveryMethod: _bookingData.deliveryMethod ?? '',
      instructions: _bookingData.instructions ?? '',
    );
  }

  void setDeliveryDateTime(String date, String time) {
    _bookingData = _bookingData.copyWith(
      deliveryDate: date,
      deliveryTime: time,
    );
    notifyListeners();
    
    // Save to Firestore
    _firestoreService.saveTimeSlotSelection(
      collectionDate: _bookingData.collectionDate ?? '',
      collectionTime: _bookingData.collectionTime ?? '',
      deliveryDate: date,
      deliveryTime: time,
      collectionMethod: _bookingData.collectionMethod ?? '',
      deliveryMethod: _bookingData.deliveryMethod ?? '',
      instructions: _bookingData.instructions ?? '',
    );
  }

  void acceptTerms(bool accepted) {
    _bookingData = _bookingData.copyWith(acceptedTerms: accepted);
    notifyListeners();
  }

  void setCollectionMethod(String method) {
    _bookingData = _bookingData.copyWith(collectionMethod: method);
    notifyListeners();
    
    // Save to Firestore
    _firestoreService.saveTimeSlotSelection(
      collectionDate: _bookingData.collectionDate ?? '',
      collectionTime: _bookingData.collectionTime ?? '',
      deliveryDate: _bookingData.deliveryDate ?? '',
      deliveryTime: _bookingData.deliveryTime ?? '',
      collectionMethod: method,
      deliveryMethod: _bookingData.deliveryMethod ?? '',
      instructions: _bookingData.instructions ?? '',
    );
  }

  void setDeliveryMethod(String method) {
    _bookingData = _bookingData.copyWith(deliveryMethod: method);
    notifyListeners();
    
    // Save to Firestore
    _firestoreService.saveTimeSlotSelection(
      collectionDate: _bookingData.collectionDate ?? '',
      collectionTime: _bookingData.collectionTime ?? '',
      deliveryDate: _bookingData.deliveryDate ?? '',
      deliveryTime: _bookingData.deliveryTime ?? '',
      collectionMethod: _bookingData.collectionMethod ?? '',
      deliveryMethod: method,
      instructions: _bookingData.instructions ?? '',
    );
  }

  void setInstructions(String instructions) {
    _bookingData = _bookingData.copyWith(instructions: instructions);
    notifyListeners();
    
    // Save to Firestore
    _firestoreService.saveTimeSlotSelection(
      collectionDate: _bookingData.collectionDate ?? '',
      collectionTime: _bookingData.collectionTime ?? '',
      deliveryDate: _bookingData.deliveryDate ?? '',
      deliveryTime: _bookingData.deliveryTime ?? '',
      collectionMethod: _bookingData.collectionMethod ?? '',
      deliveryMethod: _bookingData.deliveryMethod ?? '',
      instructions: instructions,
    );
  }

  void setPrepaidPackName(String prepaidPackName) {
    _bookingData = _bookingData.copyWith(prepaidPackName: prepaidPackName);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Load last time slot selection from Firestore
  Future<void> loadLastTimeSlotSelection() async {
    try {
      final lastSelection = await _firestoreService.getLastTimeSlotSelection();
      if (lastSelection != null) {
        _bookingData = _bookingData.copyWith(
          collectionDate: lastSelection['collectionDate'] ?? '',
          collectionTime: lastSelection['collectionTime'] ?? '',
          deliveryDate: lastSelection['deliveryDate'] ?? '',
          deliveryTime: lastSelection['deliveryTime'] ?? '',
          collectionMethod: lastSelection['collectionMethod'] ?? '',
          deliveryMethod: lastSelection['deliveryMethod'] ?? '',
          instructions: lastSelection['instructions'] ?? '',
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading last time slot selection: $e');
    }
  }

  // ==================== ORDER OPERATIONS ====================

  /// Create order and save to Firestore
  Future<models.Order> createOrder() async {
    setLoading(true);
    
    try {
      final orderId = await _generateOrderId();
      final isPrepaidPack = _selectedService == 'Prepaid Pack';
      final prepaidPackName = _bookingData.prepaidPackName ?? '';
      
      // Calculate total amount with tax and fees
      final basePrice = _bookingData.subtotal;
      final discSubtotal = _bookingData.discountedSubtotal;
      const serviceFee = 2.99;
      const deliveryFee = 0.0;
      const taxRate = 0.20; // 20% tax
      final tax = (discSubtotal + serviceFee + deliveryFee) * taxRate;
      final totalAmount = discSubtotal + serviceFee + deliveryFee + tax;
      
      // Create order with temporary ID - will be updated with Firestore ID
      final order = models.Order(
        id: '', // Will be set by Firestore
        orderId: orderId,
        bookingData: _bookingData,
        type: isPrepaidPack ? 'prepaid_pack' : 'regular',
        status: 'pending',
        createdAt: DateTime.now(),
        transactionAmount: totalAmount, // Include total amount with tax and fees
      );
      
      final usedDiscountCode = _bookingData.discountCode;
      
      print('=== BookingProvider: Creating order with ID: $orderId ===');
      print('=== BookingProvider: Order data: ${order.toJson()} ===');
      
      // Save to Firestore - convert order to JSON
      final firestoreOrderId = await _firestoreService.createOrder(order.toJson());
      
      if (firestoreOrderId != null) {
        print('=== BookingProvider: Order created in Firestore with ID: $firestoreOrderId ===');
        
        // Update time slot booking counts
        await _updateTimeSlotBookings();
        
        // Mark coupon as used if one was applied
        if (usedDiscountCode != null && usedDiscountCode.isNotEmpty) {
          final userId = _firestoreService.userId;
          if (userId != null) {
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'usedCoupons': FieldValue.arrayUnion([usedDiscountCode]),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            // Update local state if needed (though the listener will handle it)
            if (!_userUsedCoupons.contains(usedDiscountCode)) {
              _userUsedCoupons.add(usedDiscountCode);
            }
          }
        }
        
        // Update order count
        _userOrderCount++;
        
        // The stream listener will automatically add the new order to _orders
        // No need to add manually - this ensures real-time sync works properly
        notifyListeners();
        
        // Reset booking data for next order
        _bookingData = models.BookingData();
        _selectedService = null;
        
        // Return order with Firestore ID
        return order.copyWith(id: firestoreOrderId);
      } else {
        throw Exception('Failed to create order in Firestore');
      }
    } finally {
      setLoading(false);
    }
  }

  /// Update time slot bookings when order is created
  Future<void> _updateTimeSlotBookings() async {
    try {
      // Update collection time slot
      if (_bookingData.hasCollectionDateTime) {
        final collectionDay = _getDayId(_bookingData.collectionDate ?? '');
        final collectionTime = _bookingData.collectionTime ?? '';
        final collectionSlotId = _findSlotId(collectionDay, collectionTime);
        
        if (collectionSlotId != null) {
          await _firestoreService.updateCollectionTimeSlotBookingCount(
            collectionDay,
            collectionSlotId,
            1, // Increment by 1 for new booking
          );
        }
      }
      
      // Update delivery time slot
      if (_bookingData.hasDeliveryDateTime) {
        final deliveryDay = _getDayId(_bookingData.deliveryDate ?? '');
        final deliveryTime = _bookingData.deliveryTime ?? '';
        final deliverySlotId = _findSlotId(deliveryDay, deliveryTime);
        
        if (deliverySlotId != null) {
          await _firestoreService.updateDeliveryTimeSlotBookingCount(
            deliveryDay,
            deliverySlotId,
            1, // Increment by 1 for new booking
          );
        }
      }
    } catch (e) {
      print('Error updating time slot bookings: $e');
    }
  }

  /// Helper method to get day ID from day name
  String _getDayId(String dayName) {
    final dayMap = {
      'Monday': 'monday',
      'Tuesday': 'tuesday',
      'Wednesday': 'wednesday',
      'Thursday': 'thursday',
      'Friday': 'friday',
      'Saturday': 'saturday',
      'Sunday': 'sunday',
    };
    return dayMap[dayName] ?? dayName.toLowerCase();
  }

  /// Helper method to find slot ID from time range
  String? _findSlotId(String dayId, String timeRange) {
    // Extract start time from time range (e.g., "08:00 - 09:00" -> "08:00")
    final startTime = timeRange.split(' - ')[0].trim();
    return 'slot_${_getSlotNumber(startTime)}';
  }

  /// Helper method to get slot number from start time
  int _getSlotNumber(String startTime) {
    final timeMap = {
      '08:00': 1,
      '09:00': 2,
      '10:00': 3,
      '11:00': 4,
      '14:00': 5,
      '15:00': 6,
      '16:00': 7,
    };
    return timeMap[startTime] ?? 1;
  }

  /// Update order status in Firestore
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestoreService.updateOrderStatus(orderId, newStatus);
      
      // Update local state
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final now = DateTime.now();
        final normalizedStatus = newStatus.toLowerCase();
        final isCompleted = normalizedStatus == 'delivered' || normalizedStatus == 'completed';
        
        _orders[index] = _orders[index].copyWith(
          status: newStatus,
          updatedAt: now,
          deliveredAt: isCompleted ? now : _orders[index].deliveredAt,
        );
        notifyListeners();
      }
      
      print('Order status updated: $orderId -> $newStatus');
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  void clearBookingData() {
    _bookingData = models.BookingData();
    _selectedService = null;
    notifyListeners();
  }

  // ==================== COUPON OPERATIONS ====================

  Future<Map<String, dynamic>> applyCoupon(String code) async {
    if (code.trim().isEmpty) {
      return {'success': false, 'message': 'Please enter a coupon code'};
    }

    try {
      setLoading(true);
      final upperCode = code.trim().toUpperCase();
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('discountCode', isEqualTo: upperCode)
          .where('isActive', isEqualTo: true)
          .get();

      // Check if user has already used this coupon (Layer 1: Profile State)
      if (_userUsedCoupons.contains(upperCode)) {
        setLoading(false);
        return {'success': false, 'message': 'You have already used this coupon code.'};
      }

      // Check if user has already used this coupon (Layer 2: Order History Query)
      final userId = _firestoreService.userId;
      if (userId != null) {
        final previousOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .where('discountCode', isEqualTo: upperCode)
            .limit(1)
            .get();
            
        if (previousOrders.docs.isNotEmpty) {
          setLoading(false);
          // Sync the local state if it was missing
          if (!_userUsedCoupons.contains(upperCode)) {
            _userUsedCoupons.add(upperCode);
          }
          return {'success': false, 'message': 'You have already used this coupon code.'};
        }
      }

      if (querySnapshot.docs.isEmpty) {
        setLoading(false);
        return {'success': false, 'message': 'Invalid or inactive coupon code'};
      }

      final offerData = querySnapshot.docs.first.data();
      final expiryDate = offerData['expiryDate'] as Timestamp?;
      
      if (expiryDate != null && expiryDate.toDate().isBefore(DateTime.now())) {
        setLoading(false);
        return {'success': false, 'message': 'This coupon code has expired'};
      }

      final double discountValue = (offerData['discountValue'] as num?)?.toDouble() ?? 0.0;
      final String discountType = offerData['discountType'] as String? ?? 'percentage';
      
      double calculatedDiscount = 0.0;
      final currentSubtotal = _bookingData.subtotal;

      if (discountType == 'percentage') {
        calculatedDiscount = currentSubtotal * (discountValue / 100);
      } else {
        calculatedDiscount = discountValue;
      }

      _bookingData = _bookingData.copyWith(
        discountCode: upperCode,
        discountAmount: calculatedDiscount,
      );
      
      setLoading(false);
      notifyListeners();
      return {
        'success': true, 
        'message': 'Coupon applied successfully!',
        'discount': calculatedDiscount
      };
    } catch (e) {
      setLoading(false);
      print('Error applying coupon: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  void removeCoupon() {
    _bookingData = _bookingData.copyWith(
      discountCode: null,
      discountAmount: 0.0,
    );
    notifyListeners();
  }

  // ==================== VALIDATION ====================

  String? validateAddress() {
    if (!_bookingData.hasSelectedAddress) {
      return 'Please select a collection address';
    }
    return null;
  }

  String? validateDateTime() {
    if (!_bookingData.hasCollectionDateTime) {
      return 'Please select collection date and time';
    }
    if (!_bookingData.hasDeliveryDateTime) {
      return 'Please select delivery date and time';
    }
    return null;
  }

  String? validateContactInfo() {
    if (_bookingData.firstName.isEmpty) {
      return 'Please enter your first name';
    }
    if (_bookingData.email.isEmpty) {
      return 'Please enter your email';
    }
    if (_bookingData.phone.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!_bookingData.acceptedTerms) {
      return 'Please accept the terms and conditions';
    }
    return null;
  }

  bool get canProceedToPayment {
    return _bookingData.isReadyForPayment;
  }

  // Firestore service getter
  FirestoreService get firestoreService => _firestoreService;
}
