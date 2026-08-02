import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/service_model.dart';

class ServiceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Service> _services = [];
  List<Service> _activeServices = [];
  bool _isLoading = false;
  
  // Getters
  List<Service> get services => _services;
  List<Service> get activeServices => _activeServices;
  bool get isLoading => _isLoading;

  /// Initialize services listener
  void initializeServicesListener() {
    // Set loading state initially to show skeleton
    _isLoading = true;
    notifyListeners();
    
    // Add small delay to make skeleton visible
    Future.delayed(const Duration(milliseconds: 500), () {
      _firestoreService.getServicesStream().listen(
        (snapshot) {
          _services = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Service.fromJson(data, doc.id);
          }).toList();
          
          // Filter only active services and sort by order
          _activeServices = _services
              .where((service) => service.isActive)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));
          
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          notifyListeners();
        },
      );
    });
  }

  /// Get service by ID
  Service? getServiceById(String id) {
    try {
      return _services.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get service by name
  Service? getServiceByName(String name) {
    try {
      return _services.firstWhere((service) => service.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Add new service
  Future<bool> addService({
    required String name,
    required String icon,
    required String description,
    required int order,
    bool isActive = true,
  }) async {
    try {
      await _firestoreService.addService(
        name: name,
        icon: icon,
        description: description,
        order: order,
        isActive: isActive,
      );
      return true;
    } catch (e) {
      print('Error adding service: $e');
      return false;
    }
  }

  /// Update service
  Future<bool> updateService({
    required String serviceId,
    String? name,
    String? icon,
    String? description,
    int? order,
    bool? isActive,
  }) async {
    try {
      await _firestoreService.updateService(
        serviceId: serviceId,
        name: name,
        icon: icon,
        description: description,
        order: order,
        isActive: isActive,
      );
      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  /// Delete service
  Future<bool> deleteService(String serviceId) async {
    try {
      await _firestoreService.deleteService(serviceId);
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  /// Toggle service status
  Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      await _firestoreService.toggleServiceStatus(serviceId, isActive);
      return true;
    } catch (e) {
      print('Error toggling service status: $e');
      return false;
    }
  }

  /// Get services as map for compatibility with existing UI
  List<Map<String, dynamic>> get servicesAsMap {
    // If Firestore services are empty, provide fallback data immediately
    if (_services.isEmpty) {
      return _getFallbackServices();
    }
    
    return _activeServices.map((service) {
      // Calculate lowest price from actual items
      String lowestPrice = _getLowestPriceFromItems(service.items ?? []);
      
      final serviceMap = {
        'title': service.name,
        'name': service.name, 
        'description': service.description,
        'iconPath': service.icon,
        'color': _getServiceColor(service.name),
        'priceLabel': _getPriceLabel(service.name),
        'price': lowestPrice, 
        'unit': _getUnit(service.name),
        'items': service.items ?? [],
        'tags': _generateAutomaticTags(service), // Auto-generate tags
        'imageUrl': service.imageUrl, 
        'id': service.id, 
      };
      
      return serviceMap;
    }).toList();
  }

  /// Automatically generate tags based on service details
  List<String> _generateAutomaticTags(Service service) {
    final List<String> autoTags = [];
    final String name = service.name.toLowerCase();

    // 1. "NEW" Tag for services added in the last 7 days
    final now = DateTime.now();
    final difference = now.difference(service.createdAt).inDays;
    if (difference <= 7) {
      autoTags.add('NEW');
    }

    // 2. Keyword-based logic
    if (name.contains('dry clean') || name.contains('dryclean')) {
      autoTags.addAll(['DRY CLEANING', 'IRONING']);
    } else if (name.contains('laundry') || name.contains('wash')) {
      autoTags.addAll(['WASH', 'IRONING']);
    } else if (name.contains('duvet') || name.contains('bedding')) {
      autoTags.addAll(['BEDDING', 'HYGIENIC']);
    } else if (name.contains('iron')) {
      autoTags.add('IRONING');
    } else if (name.contains('household') || name.contains('curtain')) {
      autoTags.addAll(['HOUSEHOLD', 'HOME CARE']);
    }

    // 3. Fallback: If no keyword tags, use parts of the name
    if (autoTags.isEmpty || (autoTags.length == 1 && autoTags[0] == 'NEW')) {
      final words = service.name.toUpperCase().split(' ');
      for (final word in words) {
        if (word.length > 3 && !autoTags.contains(word)) {
          autoTags.add(word);
        }
      }
    }

    // 4. "POPULAR" logic (e.g., for first 2 services)
    if (service.order <= 1 && !autoTags.contains('POPULAR') && !autoTags.contains('NEW')) {
      autoTags.add('POPULAR');
    }

    // Return unique tags, limited to 3 for UI consistency
    return autoTags.toSet().toList().take(3).toList();
  }

  /// Calculate lowest price from service items
  String _getLowestPriceFromItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return '0.00';
    }
    
    double lowestPrice = double.infinity;
    
    for (var item in items) {
      String priceStr = item['price']?.toString() ?? '0.00';
      
      // Remove £ sign and convert to double
      if (priceStr.startsWith('£')) {
        priceStr = priceStr.substring(1);
      }
      
      try {
        double price = double.parse(priceStr);
        if (price < lowestPrice) {
          lowestPrice = price;
        }
      } catch (e) {
        // Skip invalid prices
      }
    }
    
    if (lowestPrice == double.infinity) {
      return '0.00';
    }
    
    return lowestPrice.toStringAsFixed(2);
  }

  /// Fallback services data when Firestore is empty
  List<Map<String, dynamic>> _getFallbackServices() {
    return [
      {
        'title': 'Dry Clean',
        'description': 'Expert dry cleaning for delicate fabrics and formal wear.',
        'tags': ['DRY CLEANING', 'IRONING', 'ON HANGERS'],
        'priceLabel': 'Price per item',
        'price': '8.95',
        'color': const Color(0xFF0066FF), // Use consistent blue
        'iconPath': 'assets/icons/dry cleaning.png',
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
        'title': 'Duvets & Bedding',
        'description': 'Specialized cleaning for duvets, pillows, and bedding items.',
        'tags': ['DUVETS', 'PILLOWS', 'BEDDING'],
        'priceLabel': 'Price per item',
        'price': '11.95',
        'color': const Color(0xFF0066FF), // Use consistent blue
        'iconPath': 'assets/icons/Duvets & Bedding.png',
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
        'title': 'Household Items',
        'description': 'Professional cleaning for curtains, rugs, and household textiles.',
        'tags': ['CURTAINS', 'RUGS', 'HOUSEHOLD'],
        'priceLabel': 'Price per item',
        'price': '8.95',
        'color': const Color(0xFF0066FF), // Use consistent blue
        'iconPath': 'assets/icons/Household Items.png',
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
        'title': 'Laundry & Ironing',
        'description': 'For everyday laundry, bedsheets and towels with professional ironing.',
        'tags': ['WASH', 'TUMBLE-DRY', 'IRONING'],
        'priceLabel': 'Price per weight',
        'price': '18.85',
        'unit': '6kg',
        'color': const Color(0xFF0066FF), // Use consistent blue
        'iconPath': 'assets/icons/Laundry & Ironing.png',
        'items': [
          {'name': 'T-Shirt', 'price': '£1.95'},
          {'name': 'Shirt', 'price': '£2.45'},
          {'name': 'Trousers', 'price': '£3.45'},
          {'name': 'Jeans', 'price': '£3.95'},
          {'name': 'Dress', 'price': '£5.95'},
          {'name': 'Jacket', 'price': '£4.95'},
          {'name': 'Shorts', 'price': '£2.45'},
          {'name': 'Skirt', 'price': '2.95'},
          {'name': 'Blouse', 'price': '£2.95'},
          {'name': 'Bed Sheets', 'price': '£4.95'},
          {'name': 'Pillowcase', 'price': '£1.95'},
          {'name': 'Towel', 'price': '£2.45'},
        ],
      },
    ];
  }

  // Helper methods for backward compatibility
  Color _getServiceColor(String serviceName) {
    switch (serviceName) {
      case 'Dry Clean':
        return const Color(0xFF4FD1C5);
      case 'Duvets & Bedding':
        return const Color(0xFFDBEAFE);
      case 'Household Items':
        return const Color(0xFFF9A8D4);
      case 'Laundry & Ironing':
        return const Color(0xFF1DA1F2);
      default:
        return const Color(0xFF0084FF);
    }
  }

  String _getPriceLabel(String serviceName) {
    switch (serviceName) {
      case 'Laundry & Ironing':
        return 'Price per weight';
      default:
        return 'Price per item';
    }
  }

  String _getPrice(String serviceName) {
    switch (serviceName) {
      case 'Dry Clean':
        return '8.95';
      case 'Duvets & Bedding':
        return '11.95';
      case 'Household Items':
        return '15.95';
      case 'Laundry & Ironing':
        return '18.85';
      default:
        return '0.00';
    }
  }

  String _getUnit(String serviceName) {
    return serviceName == 'Laundry & Ironing' ? '6kg' : '';
  }



  @override
  void dispose() {
    super.dispose();
  }
}
