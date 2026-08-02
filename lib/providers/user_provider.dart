import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class UserProvider extends ChangeNotifier {
  // User profile data
  String _firstName = '';
  String _lastName = '';
  String _phone = '';
  String _email = '';
  String _customerType = 'individual';
  String? _companyName;
  
  // Saved address data
  String? _savedAddressId;
  String? _savedAddressLine1;
  String? _savedAddressLine2;
  String? _savedCity;
  String? _savedPostcode;
  
  // Coupon tracking
  List<String> _usedCoupons = [];
  
  // Getters
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get phone => _phone;
  String get email => _email;
  String get customerType => _customerType;
  String? get companyName => _companyName;
  
  String get fullName => '$_firstName $_lastName'.trim();
  
  bool get hasUserData => _firstName.isNotEmpty || _phone.isNotEmpty;
  bool get hasAddress => _savedAddressLine1 != null && _savedPostcode != null;
  
  String? get savedAddressLine1 => _savedAddressLine1;
  String? get savedAddressLine2 => _savedAddressLine2;
  String? get savedCity => _savedCity;
  String? get savedPostcode => _savedPostcode;
  String? get savedAddressId => _savedAddressId;
  List<String> get usedCoupons => _usedCoupons;

  // Initialize from SharedPreferences and Firestore
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First load from SharedPreferences for immediate UI
    _firstName = prefs.getString('user_firstName') ?? '';
    _lastName = prefs.getString('user_lastName') ?? '';
    _phone = prefs.getString('user_phone') ?? '';
    _email = prefs.getString('user_email') ?? '';
    _customerType = prefs.getString('user_customerType') ?? 'individual';
    _companyName = prefs.getString('user_companyName');
    
    // Load saved address
    _savedAddressId = prefs.getString('saved_address_id');
    _savedAddressLine1 = prefs.getString('saved_address_line1');
    _savedAddressLine2 = prefs.getString('saved_address_line2');
    _savedCity = prefs.getString('saved_address_city');
    _savedPostcode = prefs.getString('saved_address_postcode');
    _usedCoupons = prefs.getStringList('user_usedCoupons') ?? [];
    
    // Then try to load from Firestore if user is logged in
    final userId = prefs.getString('user_uid');
    if (userId != null && userId.isNotEmpty) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          
          // Update local data with Firestore data
          _firstName = data['firstName'] ?? _firstName;
          _lastName = data['lastName'] ?? _lastName;
          _phone = data['phoneNumber'] ?? _phone;
          _email = data['email'] ?? _email;
          _companyName = data['companyName'] ?? _companyName;
          
          // Load address data from Firestore
          if (data['defaultAddress'] != null) {
            final defaultAddress = data['defaultAddress'];
            _savedAddressId = defaultAddress['id'];
            _savedAddressLine1 = defaultAddress['line1'];
            _savedAddressLine2 = defaultAddress['line2'];
            _savedCity = defaultAddress['city'];
            _savedPostcode = defaultAddress['postalCode'];
          }
          
          // Load used coupons
          if (data['usedCoupons'] != null) {
            _usedCoupons = List<String>.from(data['usedCoupons']);
          }
          
          // Save to SharedPreferences for offline access
          await prefs.setString('user_firstName', _firstName);
          await prefs.setString('user_lastName', _lastName);
          await prefs.setString('user_phone', _phone);
          await prefs.setString('user_email', _email);
          if (_companyName != null) {
            await prefs.setString('user_companyName', _companyName!);
          }
          
          // Save address to SharedPreferences
          if (_savedAddressId != null) {
            await prefs.setString('saved_address_id', _savedAddressId ?? '');
            await prefs.setString('saved_address_line1', _savedAddressLine1 ?? '');
            await prefs.setString('saved_address_line2', _savedAddressLine2 ?? '');
            await prefs.setString('saved_address_city', _savedCity ?? '');
            await prefs.setString('saved_address_postcode', _savedPostcode ?? '');
          }
          
          // Save used coupons to SharedPreferences
          await prefs.setStringList('user_usedCoupons', _usedCoupons);
        }
      } catch (e) {
        print('Error loading user data from Firestore: $e');
      }
    }
    
    notifyListeners();
  }

  // Load user data from Firestore specifically
  Future<void> loadUserDataFromFirestore(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final prefs = await SharedPreferences.getInstance();
        
        // Save user ID to SharedPreferences
        await prefs.setString('user_uid', userId);
        
        // Update local data
        _firstName = data['firstName'] ?? '';
        _lastName = data['lastName'] ?? '';
        _phone = data['phoneNumber'] ?? '';
        _email = data['email'] ?? '';
        _companyName = data['companyName'];
        
        // Save to SharedPreferences
        await prefs.setString('user_firstName', _firstName);
        await prefs.setString('user_lastName', _lastName);
        await prefs.setString('user_phone', _phone);
        await prefs.setString('user_email', _email);
        if (_companyName != null) {
          await prefs.setString('user_companyName', _companyName!);
        }

        // Load used coupons
        if (data['usedCoupons'] != null) {
          _usedCoupons = List<String>.from(data['usedCoupons']);
          await prefs.setStringList('user_usedCoupons', _usedCoupons);
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data from Firestore: $e');
    }
  }

  // Save user data to both SharedPreferences and Firestore
  Future<void> saveUserData({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? customerType,
    String? companyName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update local state
    if (firstName != null) {
      _firstName = firstName;
      await prefs.setString('user_firstName', firstName);
    }
    
    if (lastName != null) {
      _lastName = lastName;
      await prefs.setString('user_lastName', lastName);
    }
    
    if (phone != null) {
      _phone = phone;
      await prefs.setString('user_phone', phone);
    }
    
    if (email != null) {
      _email = email;
      await prefs.setString('user_email', email);
    }
    
    if (customerType != null) {
      _customerType = customerType;
      await prefs.setString('user_customerType', customerType);
    }
    
    if (companyName != null) {
      _companyName = companyName;
      await prefs.setString('user_companyName', companyName);
    }
    
    // Also save to Firestore if user is logged in
    final userId = prefs.getString('user_uid');
    if (userId != null && userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'firstName': _firstName,
          'lastName': _lastName,
          'phoneNumber': _phone,
          'email': _email,
          'companyName': _companyName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving user data to Firestore: $e');
      }
    }
    
    notifyListeners();
  }

  // Save address data to both SharedPreferences and Firestore
  Future<void> saveAddressData({
    String? addressId,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update local state
    if (addressId != null) {
      _savedAddressId = addressId;
      await prefs.setString('saved_address_id', addressId);
    }
    
    if (addressLine1 != null) {
      _savedAddressLine1 = addressLine1;
      await prefs.setString('saved_address_line1', addressLine1);
    }
    
    if (addressLine2 != null) {
      _savedAddressLine2 = addressLine2;
      await prefs.setString('saved_address_line2', addressLine2);
    }
    
    if (city != null) {
      _savedCity = city;
      await prefs.setString('saved_address_city', city);
    }
    
    if (postcode != null) {
      _savedPostcode = postcode;
      await prefs.setString('saved_address_postcode', postcode);
    }
    
    // Also save to Firestore if user is logged in
    final userId = prefs.getString('user_uid');
    if (userId != null && userId.isNotEmpty && _savedAddressId != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'defaultAddress': {
            'id': _savedAddressId,
            'line1': _savedAddressLine1,
            'line2': _savedAddressLine2,
            'city': _savedCity,
            'postalCode': _savedPostcode,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving address data to Firestore: $e');
      }
    }
    
    notifyListeners();
  }

  // Update phone number specifically
  Future<void> updatePhone(String phone) async {
    _phone = phone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
    notifyListeners();
  }

  // Update name
  Future<void> updateName(String firstName, String lastName) async {
    _firstName = firstName;
    _lastName = lastName;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_firstName', firstName);
    await prefs.setString('user_lastName', lastName);
    
    notifyListeners();
  }

  // Clear all user data
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('user_firstName');
    await prefs.remove('user_lastName');
    await prefs.remove('user_phone');
    await prefs.remove('user_email');
    await prefs.remove('user_customerType');
    await prefs.remove('user_companyName');
    
    _firstName = '';
    _lastName = '';
    _phone = '';
    _email = '';
    _customerType = 'individual';
    _companyName = null;
    _usedCoupons = [];
    
    await prefs.remove('user_usedCoupons');
    
    notifyListeners();
  }

  // Check if coupon is used
  bool hasUsedCoupon(String code) {
    return _usedCoupons.contains(code.toUpperCase());
  }

  // Mark coupon as used
  Future<void> markCouponAsUsed(String code) async {
    final upperCode = code.toUpperCase();
    if (_usedCoupons.contains(upperCode)) return;

    _usedCoupons.add(upperCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_usedCoupons', _usedCoupons);

    final userId = prefs.getString('user_uid');
    if (userId != null && userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'usedCoupons': FieldValue.arrayUnion([upperCode]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error marking coupon as used in Firestore: $e');
      }
    }
  }
}
