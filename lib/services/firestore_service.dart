import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:drycleanplus_app/models/booking_models.dart' as models;
import 'package:flutter/material.dart';

/// FirestoreService handles all Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _servicesCollection => _firestore.collection('services');
  CollectionReference get _prepaidPacksCollection => _firestore.collection('prepaid_packs');
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
  // Public getter for user ID
  String? get userId => _userId;

  /// Initialize default data for the app
  Future<void> initializeUserData() async {
    try {
      // Create default service categories if they don't exist
      await _createDefaultServiceCategories();
      
      // Create default prepaid packs if they don't exist
      await _createDefaultPrepaidPacks();
      
      // Create default collection and delivery time slots
      print('Creating default collection slots...');
      await createDefaultCollectionTimeSlots();
      print('Creating default delivery slots...');
      await createDefaultDeliveryTimeSlots();
      
      // Create Firestore indexes for better query performance
      await _createFirestoreIndexes();
      
      print('Default data initialized successfully');
      
      // Debug: Check if slots were created
      final collectionDays = await _collectionSlotsCollection.get();
      final deliveryDays = await _deliverySlotsCollection.get();
      print('Collection days created: ${collectionDays.docs.length}');
      print('Delivery days created: ${deliveryDays.docs.length}');
      
      if (collectionDays.docs.isNotEmpty) {
        final firstDaySlots = await _collectionSlotsCollection.doc(collectionDays.docs.first.id).collection('slots').get();
        print('Slots in first collection day: ${firstDaySlots.docs.length}');
      }
      
      if (deliveryDays.docs.isNotEmpty) {
        final firstDaySlots = await _deliverySlotsCollection.doc(deliveryDays.docs.first.id).collection('slots').get();
        print('Slots in first delivery day: ${firstDaySlots.docs.length}');
      }
    } catch (e) {
      print('Error initializing default data: $e');
    }
  }

  /// Create Firestore indexes for better query performance
  Future<void> _createFirestoreIndexes() async {
    try {
      // Create indexes for orders collection
      await _firestore.collection('orders').doc('--indexes--').set({
        'indexes': [
          {
            'fields': ['userId', 'createdAt'],
            'queryScope': 'COLLECTION'
          },
          {
            'fields': ['orderId'],
            'queryScope': 'COLLECTION'
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create indexes for addresses subcollection
      await _firestore.collection('users').doc('--indexes--').set({
        'indexes': [
          {
            'fields': ['isDefault', 'createdAt'],
            'queryScope': 'COLLECTION'
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Firestore indexes created');
    } catch (e) {
      print('Error creating Firestore indexes: $e');
    }
  }

  /// Create default service categories
  Future<void> _createDefaultServiceCategories() async {
    try {
      print('=== DEBUG: Creating default service categories ===');
      final servicesSnapshot = await _servicesCollection.limit(1).get();
      
      if (servicesSnapshot.docs.isEmpty) {
        print('No services found, creating default services...');
        
        // Create default service categories with itemized pricing if they don't exist
        final defaultServices = [
          {
            'name': 'Dry Clean',
            'icon': 'assets/icons/dry cleaning.png',
            'description': 'Expert dry cleaning for delicate fabrics and formal wear.',
            'isActive': true,
            'order': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'items': [
              {'name': 'Suit', 'price': '£8.95'},
              {'name': 'Coat', 'price': '£7.95'},
              {'name': 'Dress', 'price': '£5.95'},
              {'name': 'Blouse', 'price': '£3.95'},
              {'name': 'Shirt', 'price': '£3.45'},
              {'name': 'Trousers', 'price': '£4.45'},
              {'name': 'Skirt', 'price': '£3.95'},
              {'name': 'Scarf', 'price': '£1.45'},
              {'name': 'Tie', 'price': '£1.95'},
              {'name': 'Jacket', 'price': '£5.95'},
            ],
          },
          {
            'name': 'Duvets & Bedding',
            'icon': 'assets/icons/Duvets & Bedding.png',
            'description': 'Specialized cleaning for duvets, pillows, and bedding items.',
            'isActive': true,
            'order': 2,
            'createdAt': FieldValue.serverTimestamp(),
            'items': [
              {'name': 'Single Duvet', 'price': '£11.95'},
              {'name': 'Double Duvet', 'price': '£15.95'},
              {'name': 'King Duvet', 'price': '£19.95'},
              {'name': 'Super King Duvet', 'price': '£24.95'},
              {'name': 'Pillows', 'price': '£6.95'},
              {'name': 'Pillow Shams', 'price': '£4.95'},
              {'name': 'Bedspread', 'price': '£12.95'},
              {'name': 'Mattress Protector', 'price': '£8.95'},
            ],
          },
          {
            'name': 'Household Items',
            'icon': 'assets/icons/Household Items.png',
            'description': 'Professional cleaning for curtains, rugs, and household textiles.',
            'isActive': true,
            'order': 3,
            'createdAt': FieldValue.serverTimestamp(),
            'items': [
              {'name': 'Curtains', 'price': '£15.95'},
              {'name': 'Voile Curtains', 'price': '£12.95'},
              {'name': 'Roman Blinds', 'price': '£14.95'},
              {'name': 'Roller Blinds', 'price': '£12.95'},
              {'name': 'Tablecloth', 'price': '£8.95'},
              {'name': 'Napkins', 'price': '£2.95'},
              {'name': 'Small Rug', 'price': '£15.95'},
              {'name': 'Large Rug', 'price': '£25.95'},
              {'name': 'Throw', 'price': '£9.95'},
            ],
          },
          {
            'name': 'Laundry & Ironing',
            'icon': 'assets/icons/Laundry & Ironing.png',
            'description': 'For everyday laundry, bedsheets and towels with professional ironing.',
            'isActive': true,
            'order': 4,
            'createdAt': FieldValue.serverTimestamp(),
            'items': [
              {'name': 'T-Shirt', 'price': '£1.95'},
              {'name': 'Shirt', 'price': '£2.45'},
              {'name': 'Trousers', 'price': '£3.45'},
              {'name': 'Jeans', 'price': '£3.95'},
              {'name': 'Dress', 'price': '£5.95'},
              {'name': 'Jacket', 'price': '£4.95'},
              {'name': 'Shorts', 'price': '£2.45'},
              {'name': 'Skirt', 'price': '£2.95'},
              {'name': 'Blouse', 'price': '£2.95'},
              {'name': 'Bed Sheets', 'price': '£4.95'},
              {'name': 'Pillowcase', 'price': '£1.95'},
              {'name': 'Towel', 'price': '£2.45'},
            ],
          },
        ];
        
        print('Creating ${defaultServices.length} default services...');
        
        // Create each service in Firestore using service name as document ID
        for (final service in defaultServices) {
          final items = service['items'] as List?;
          print('Creating service: ${service['name']} with ${items?.length ?? 0} items');
          try {
            // Use service name as document ID instead of auto-generated UID
            final serviceName = service['name'].toString().toLowerCase().replaceAll(' ', '_');
            await _servicesCollection.doc(serviceName).set(service);
            print('✓ Successfully created service: ${service['name']} with ID: $serviceName');
          } catch (e) {
            print('✗ Error creating service ${service['name']}: $e');
          }
        }
        print('Default service categories created');
      }
    } catch (e) {
      print('Error creating default services: $e');
    }
  }

  /// Create default prepaid packs
  Future<void> _createDefaultPrepaidPacks() async {
    try {
      final packsSnapshot = await _prepaidPacksCollection.limit(1).get();
      
      if (packsSnapshot.docs.isEmpty) {
        // Create default prepaid packs matching app's prepaid packs with discount info
        final defaultPacks = [
          {
            'name': 'Trousers prepaid pack',
            'description': 'For dry cleaning or wash & iron',
            'discounts': [
              {
                'count': '5',
                'label': 'Trousers',
                'old': '44.75',
                'new': '42',
                'off': '6%'
              },
              {
                'count': '10',
                'label': 'Trousers',
                'old': '89.50',
                'new': '80',
                'off': '11%'
              },
            ],
            'isActive': true,
            'order': 1,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': '2-Piece suits prepaid pack',
            'description': 'For dry cleaning',
            'discounts': [
              {
                'count': '5×2-piece',
                'label': 'Suit',
                'old': '74.75',
                'new': '71',
                'off': '5%'
              },
              {
                'count': '10×2-piece',
                'label': 'Suit',
                'old': '149.50',
                'new': '135',
                'off': '10%'
              },
            ],
            'isActive': true,
            'order': 2,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Shirts prepaid pack',
            'description': 'For dry cleaning or wash & iron',
            'discounts': [
              {
                'count': '10',
                'label': 'Shirt',
                'old': '38.50',
                'new': '34.50',
                'off': '10%'
              },
            ],
            'isActive': true,
            'order': 3,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Duvets prepaid pack',
            'description': 'For dry cleaning',
            'discounts': [
              {
                'count': '3',
                'label': 'Single Duvet',
                'old': '39.85',
                'new': '35.85',
                'off': '10%'
              },
            ],
            'isActive': true,
            'order': 4,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Bedding prepaid pack',
            'description': 'For dry cleaning',
            'discounts': [
              {
                'count': '4',
                'label': 'Bed Sheets',
                'old': '23.80',
                'new': '21.50',
                'off': '10%'
              },
            ],
            'isActive': true,
            'order': 5,
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        for (final pack in defaultPacks) {
          final packName = pack['name'].toString().toLowerCase().replaceAll(' ', '_');
          await _prepaidPacksCollection.doc(packName).set(pack);
        }
        print('Default prepaid packs created');
      }
    } catch (e) {
      print('Error creating default prepaid packs: $e');
    }
  }

  // ==================== TIME SLOT MANAGEMENT ====================

  // Main collection and delivery slots collection references
  CollectionReference get _collectionSlotsCollection => _firestore.collection('collection_slots');
  CollectionReference get _deliverySlotsCollection => _firestore.collection('delivery_slots');

  // Get all days as stream for collection
  Stream<QuerySnapshot> getCollectionDaysStream() {
    return _collectionSlotsCollection
        .orderBy('order') // Ensure days are in order (Mon, Tue, etc.)
        .snapshots();
  }

  // Get all days as stream for delivery
  Stream<QuerySnapshot> getDeliveryDaysStream() {
    return _deliverySlotsCollection
        .orderBy('order') // Ensure days are in order (Mon, Tue, etc.)
        .snapshots();
  }

  // Get slots for a specific day (collection)
  Stream<QuerySnapshot> getCollectionSlotsForDayStream(String dayId) {
    return _collectionSlotsCollection
        .doc(dayId)
        .collection('slots')
        .orderBy('start')
        .snapshots();
  }

  // Get slots for a specific day (delivery)
  Stream<QuerySnapshot> getDeliverySlotsForDayStream(String dayId) {
    return _deliverySlotsCollection
        .doc(dayId)
        .collection('slots')
        .orderBy('start')
        .snapshots();
  }

  // Update slot booking count (collection)
  Future<void> updateCollectionSlotBookingCount(String dayId, String slotId, int increment) async {
    try {
      await _collectionSlotsCollection
          .doc(dayId)
          .collection('slots')
          .doc(slotId)
          .update({
        'current': FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating collection slot booking count: $e');
    }
  }

  // Update slot booking count (delivery)
  Future<void> updateDeliverySlotBookingCount(String dayId, String slotId, int increment) async {
    try {
      await _deliverySlotsCollection
          .doc(dayId)
          .collection('slots')
          .doc(slotId)
          .update({
        'current': FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating delivery slot booking count: $e');
    }
  }

  /// Create default collection slots with subcollection structure
  Future<void> createDefaultCollectionTimeSlots() async {
    try {
      // Check if any collection slots exist
      final existingSnapshot = await _collectionSlotsCollection.limit(1).get();
      
      if (existingSnapshot.docs.isEmpty) {
        // Only create default slots if none exist
        final batch = _firestore.batch();
        
        // Define days with order and open status
        final days = [
          {'id': 'monday', 'day_name': 'Monday', 'order': 1, 'isOpen': true},
          {'id': 'tuesday', 'day_name': 'Tuesday', 'order': 2, 'isOpen': true},
          {'id': 'wednesday', 'day_name': 'Wednesday', 'order': 3, 'isOpen': true},
          {'id': 'thursday', 'day_name': 'Thursday', 'order': 4, 'isOpen': true},
          {'id': 'friday', 'day_name': 'Friday', 'order': 5, 'isOpen': true},
          {'id': 'saturday', 'day_name': 'Saturday', 'order': 6, 'isOpen': true},
          {'id': 'sunday', 'day_name': 'Sunday', 'order': 7, 'isOpen': true},
        ];
        
        // Define 7 slots per day with open status
        final defaultSlots = [
          {'start': '08:00', 'end': '09:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '09:00', 'end': '10:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '10:00', 'end': '11:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '11:00', 'end': '12:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '14:00', 'end': '15:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '15:00', 'end': '16:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '16:00', 'end': '17:00', 'max': 5, 'current': 0, 'isOpen': true},
        ];
        
        // Create days and slots
        for (final day in days) {
          // Create day document
          final dayRef = _collectionSlotsCollection.doc(day['id'] as String);
          batch.set(dayRef, {
            'day_name': day['day_name'],
            'order': day['order'],
            'isOpen': day['isOpen'],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Create slots subcollection
          for (int i = 0; i < defaultSlots.length; i++) {
            final slotData = defaultSlots[i];
            final slotRef = dayRef.collection('slots').doc('slot_${i+1}');
            batch.set(slotRef, {
              ...slotData,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        
        await batch.commit();
        print('Default collection time slots created');
      }
    } catch (e) {
      print('Error creating default collection time slots: $e');
    }
  }

  /// Create default delivery slots with subcollection structure
  Future<void> createDefaultDeliveryTimeSlots() async {
    try {
      // Check if any delivery slots exist
      final existingSnapshot = await _deliverySlotsCollection.limit(1).get();
      
      if (existingSnapshot.docs.isEmpty) {
        // Only create default slots if none exist
        final batch = _firestore.batch();
        
        // Define days with order and open status
        final days = [
          {'id': 'monday', 'day_name': 'Monday', 'order': 1, 'isOpen': true},
          {'id': 'tuesday', 'day_name': 'Tuesday', 'order': 2, 'isOpen': true},
          {'id': 'wednesday', 'day_name': 'Wednesday', 'order': 3, 'isOpen': true},
          {'id': 'thursday', 'day_name': 'Thursday', 'order': 4, 'isOpen': true},
          {'id': 'friday', 'day_name': 'Friday', 'order': 5, 'isOpen': true},
          {'id': 'saturday', 'day_name': 'Saturday', 'order': 6, 'isOpen': true},
          {'id': 'sunday', 'day_name': 'Sunday', 'order': 7, 'isOpen': true},
        ];
        
        // Define 7 slots per day with open status
        final defaultSlots = [
          {'start': '08:00', 'end': '09:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '09:00', 'end': '10:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '10:00', 'end': '11:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '11:00', 'end': '12:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '14:00', 'end': '15:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '15:00', 'end': '16:00', 'max': 5, 'current': 0, 'isOpen': true},
          {'start': '16:00', 'end': '17:00', 'max': 5, 'current': 0, 'isOpen': true},
        ];
        
        // Create days and slots
        for (final day in days) {
          // Create day document
          final dayRef = _deliverySlotsCollection.doc(day['id'] as String);
          batch.set(dayRef, {
            'day_name': day['day_name'],
            'order': day['order'],
            'isOpen': day['isOpen'],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Create slots subcollection
          for (int i = 0; i < defaultSlots.length; i++) {
            final slotData = defaultSlots[i];
            final slotRef = dayRef.collection('slots').doc('slot_${i+1}');
            batch.set(slotRef, {
              ...slotData,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        
        await batch.commit();
        print('Default delivery time slots created');
      }
    } catch (e) {
      print('Error creating default delivery time slots: $e');
    }
  }

  // Methods for backward compatibility
  Stream<QuerySnapshot> getCollectionTimeSlotsStream() {
    return getCollectionDaysStream();
  }

  Stream<QuerySnapshot> getDeliveryTimeSlotsStream() {
    return getDeliveryDaysStream();
  }

  Stream<QuerySnapshot> getCollectionTimeSlotsForDayStream(String day) {
    final dayId = day.toLowerCase();
    return getCollectionSlotsForDayStream(dayId);
  }

  Stream<QuerySnapshot> getDeliveryTimeSlotsForDayStream(String day) {
    final dayId = day.toLowerCase();
    return getDeliverySlotsForDayStream(dayId);
  }

  Future<void> updateCollectionTimeSlotBookingCount(String dayId, String slotId, int increment) async {
    try {
      await _collectionSlotsCollection
          .doc(dayId)
          .collection('slots')
          .doc(slotId)
          .update({
        'current': FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Updated collection slot booking count: $dayId/$slotId by $increment');
    } catch (e) {
      print('Error updating collection time slot booking count: $e');
    }
  }

  Future<void> updateDeliveryTimeSlotBookingCount(String dayId, String slotId, int increment) async {
    try {
      await _deliverySlotsCollection
          .doc(dayId)
          .collection('slots')
          .doc(slotId)
          .update({
        'current': FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Updated delivery slot booking count: $dayId/$slotId by $increment');
    } catch (e) {
      print('Error updating delivery time slot booking count: $e');
    }
  }

  // ==================== SERVICES ====================

  /// Get all services as stream
  Stream<QuerySnapshot> getServicesStream() {
    print('=== DEBUG: Getting services stream (all docs) ===');
    // REMOVED orderBy('order') because it excludes docs missing the field!
    // We will sort in-memory in the ServiceProvider.
    return _servicesCollection.snapshots();
  }

  /// Get all services as list (for debugging)
  Future<List<DocumentSnapshot>> getAllServices() async {
    print('=== DEBUG: Getting all services from Firestore ===');
    try {
      final snapshot = await _servicesCollection.get();
      print('Found ${snapshot.docs.length} services in Firestore');
      
      for (final doc in snapshot.docs) {
        print('Service ID: ${doc.id}, Name: ${doc.get('name')}, Items: ${doc.get('items')}');
      }
      
      return snapshot.docs;
    } catch (e) {
      print('Error getting services: $e');
      return [];
    }
  }

  /// Add new service
  Future<String?> addService({
    required String name,
    required String icon,
    required String description,
    required int order,
    bool isActive = true,
  }) async {
    try {
      final docRef = await _servicesCollection.add({
        'name': name,
        'icon': icon,
        'description': description,
        'order': order,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error adding service: $e');
      return null;
    }
  }

  /// Update service
  Future<void> updateService({
    required String serviceId,
    String? name,
    String? icon,
    String? description,
    int? order,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (icon != null) updateData['icon'] = icon;
      if (description != null) updateData['description'] = description;
      if (order != null) updateData['order'] = order;
      if (isActive != null) updateData['isActive'] = isActive;
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _servicesCollection.doc(serviceId).update(updateData);
    } catch (e) {
      print('Error updating service: $e');
    }
  }

  /// Delete service
  Future<void> deleteService(String serviceId) async {
    try {
      await _servicesCollection.doc(serviceId).delete();
    } catch (e) {
      print('Error deleting service: $e');
    }
  }

  /// Toggle service status
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      await _servicesCollection.doc(serviceId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling service status: $e');
    }
  }

  // ==================== USER DATA ====================

  /// Get user data as stream for real-time updates
  Stream<DocumentSnapshot> getUserDataStream() {
    if (_userId == null) {
      return _usersCollection.doc('dummy').snapshots();
    }
    return _usersCollection.doc(_userId).snapshots();
  }

  /// Get user data
  Future<DocumentSnapshot?> getUserData() async {
    try {
      if (_userId == null) return null;
      
      final doc = await _usersCollection.doc(_userId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_userId == null) return;
      
      await _usersCollection.doc(_userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  /// Update user contact information
  Future<void> updateUserContactInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      if (_userId == null) return;
      
      await _usersCollection.doc(_userId).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'contactUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('User contact info updated');
    } catch (e) {
      print('Error updating user contact info: $e');
    }
  }

  // ==================== ORDERS ====================

  /// Get user orders as stream
  Stream<QuerySnapshot> getOrdersStream() {
    if (_userId == null) {
      return _ordersCollection.where('userId', isEqualTo: 'dummy').snapshots();
    }
    
    // Remove orderBy to avoid index requirement for now
    return _ordersCollection
        .where('userId', isEqualTo: _userId)
        .snapshots();
  }

  /// Get last order number
  Future<String?> getLastOrderNumber() async {
    try {
      final snapshot = await _ordersCollection
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final lastDoc = snapshot.docs.first;
        final data = lastDoc.data() as Map<String, dynamic>;
        if (data.containsKey('orderId')) {
          return data['orderId'] as String?;
        } else {
          print('Warning: orderId field not found in last order document');
        }
      }
    } catch (e) {
      print('Error getting last order number: $e');
    }
    return null;
  }

  /// Create order
  Future<String?> createOrder(Map<String, dynamic> orderData) async {
    try {
      if (_userId == null) {
        print('Error: User ID is null');
        return null;
      }
      
      print('Creating order with data: $orderData');
      print('User ID: $_userId');
      
      // Extract discount code for easier querying if it exists in bookingData
      String? discountCode;
      if (orderData['bookingData'] != null && orderData['bookingData']['discountCode'] != null) {
        discountCode = orderData['bookingData']['discountCode'];
      }

      final docRef = await _ordersCollection.add({
        ...orderData,
        'userId': _userId,
        'discountCode': discountCode, // Root level for easy one-time use checking
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Order created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // If status is delivered or completed, set the deliveredAt timestamp
      final normalizedStatus = status.toLowerCase();
      if (normalizedStatus == 'delivered' || normalizedStatus == 'completed') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }
      
      await _ordersCollection.doc(orderId).update(updateData);
    } catch (e) {
      print('Error updating order status: $orderId to $status: $e');
    }
  }

  // ==================== TIME SLOT SELECTION ====================

  /// Save time slot selection
  Future<void> saveTimeSlotSelection({
    required String collectionDate,
    required String collectionTime,
    required String deliveryDate,
    required String deliveryTime,
    required String collectionMethod,
    required String deliveryMethod,
    required String instructions,
  }) async {
    try {
      if (_userId == null) return;
      
      await _usersCollection.doc(_userId).set({
        'timeSlotSelection': {
          'collectionDate': collectionDate,
          'collectionTime': collectionTime,
          'deliveryDate': deliveryDate,
          'deliveryTime': deliveryTime,
          'collectionMethod': collectionMethod,
          'deliveryMethod': deliveryMethod,
          'instructions': instructions,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving time slot selection: $e');
    }
  }

  /// Get last time slot selection
  Future<Map<String, dynamic>?> getLastTimeSlotSelection() async {
    try {
      if (_userId == null) return null;
      
      final userDoc = await _usersCollection.doc(_userId).get();
      if (userDoc.exists) {
        return userDoc.get('timeSlotSelection') as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting last time slot selection: $e');
    }
    return null;
  }

  // ==================== PREPAID PACKS ====================

  /// Get all prepaid packs
  Future<QuerySnapshot> getPrepaidPacks() async {
    return await _prepaidPacksCollection
        .where('isActive', isEqualTo: true)
        .get();
  }

  // ==================== ADDRESSES ====================

  /// Get user addresses as stream for real-time updates
  Stream<QuerySnapshot> getAddressesStream() {
    if (_userId == null) {
      return _usersCollection.doc('dummy').collection('addresses').snapshots();
    }
    return _usersCollection
        .doc(_userId)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Add a new address
  Future<String?> addAddress(Map<String, dynamic> addressData) async {
    try {
      if (_userId == null) return null;
      
      // If this is set as default, unset other default addresses
      if (addressData['isDefault'] == true) {
        final batch = _firestore.batch();
        final existingAddresses = await _usersCollection
            .doc(_userId)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get();
        
        for (final doc in existingAddresses.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        await batch.commit();
      }
      
      final docRef = await _usersCollection
          .doc(_userId)
          .collection('addresses')
          .add({
            ...addressData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('Address added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding address: $e');
      return null;
    }
  }

  /// Update an existing address
  Future<void> updateAddress(Map<String, dynamic> addressData) async {
    try {
      if (_userId == null) return;
      
      // If this is set as default, unset other default addresses
      if (addressData['isDefault'] == true) {
        final batch = _firestore.batch();
        final existingAddresses = await _usersCollection
            .doc(_userId)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get();
        
        for (final doc in existingAddresses.docs) {
          if (doc.id != addressData['id']) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }
        await batch.commit();
      }
      
      await _usersCollection
          .doc(_userId)
          .collection('addresses')
          .doc(addressData['id'])
          .update({
            ...addressData,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('Address updated: ${addressData['id']}');
    } catch (e) {
      print('Error updating address: $e');
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) async {
    try {
      if (_userId == null) return;
      
      await _usersCollection
          .doc(_userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
      
      print('Address deleted: $addressId');
    } catch (e) {
      print('Error deleting address: $e');
    }
  }

  /// Set default address
  Future<void> setDefaultAddress(String addressId) async {
    try {
      if (_userId == null) return;
      
      final batch = _firestore.batch();
      
      // Unset all defaults
      final existingAddresses = await _usersCollection
          .doc(_userId)
          .collection('addresses')
          .where('isDefault', isEqualTo: true)
          .get();
      
      for (final doc in existingAddresses.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      
      // Set new default
      batch.update(
        _usersCollection.doc(_userId).collection('addresses').doc(addressId),
        {'isDefault': true, 'updatedAt': FieldValue.serverTimestamp()},
      );
      
      await batch.commit();
      print('Default address set: $addressId');
    } catch (e) {
      print('Error setting default address: $e');
    }
  }
}
