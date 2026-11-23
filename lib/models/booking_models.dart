import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String line1;
  final String? line2;
  final String city;
  final String postalCode;
  final bool isDefault;
  final String? buildingName;
  final double? latitude;
  final double? longitude;

  const Address({
    required this.id,
    required this.line1,
    this.line2,
    required this.city,
    required this.postalCode,
    this.isDefault = false,
    this.buildingName,
    this.latitude,
    this.longitude,
  });

  Address copyWith({
    String? id,
    String? line1,
    String? line2,
    String? city,
    String? postalCode,
    bool? isDefault,
    String? buildingName,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      buildingName: buildingName ?? this.buildingName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'line1': line1,
      'line2': line2,
      'city': city,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'buildingName': buildingName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    String? opt(Object? v) => v == null || '$v'.isEmpty ? null : '$v';
    double? parseCoord(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }
    return Address(
      id: '${json['id'] ?? ''}',
      line1: '${json['line1'] ?? ''}',
      line2: opt(json['line2']),
      city: '${json['city'] ?? ''}',
      postalCode: '${json['postalCode'] ?? json['postcode'] ?? ''}',
      isDefault: json['isDefault'] == true,
      buildingName: opt(json['buildingName']),
      latitude: parseCoord(json['latitude'] ?? json['lat']),
      longitude: parseCoord(json['longitude'] ?? json['lon'] ?? json['lng']),
    );
  }

  String get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$line1, $city $postalCode')}';
  }

  String get fullAddress {
    final parts = [line1];
    if (line2 != null && line2!.isNotEmpty) parts.add(line2!);
    parts.add('$city, $postalCode');
    return parts.join(', ');
  }
}

class ServiceItem {
  final String category;
  final String itemType;
  final String price;
  final String description;

  const ServiceItem({
    required this.category,
    required this.itemType,
    required this.price,
    this.description = '',
  });

  String get uniqueKey => '${category}_$itemType';

  double get numericPrice {
    return double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'itemType': itemType,
      'price': price,
      'description': description,
    };
  }
}

class TimeSlot {
  final String time;
  final bool isAvailable;
  final String type; // 'collection' or 'delivery'

  TimeSlot({
    required this.time,
    this.isAvailable = true,
    required this.type,
  });
}

class BookingData {
  List<Address> addresses;
  Address? selectedAddress;
  Address? deliveryAddress;
  String? collectionDate;
  String? collectionTime;
  String? deliveryDate;
  String? deliveryTime;
  Map<String, ServiceItem> selectedItems;
  String firstName;
  String lastName;
  String email;
  String phone;
  String specialInstructions;
  bool acceptedTerms;
  String? bookingReference;
  String? status;
  String? createdAt;
  String? customerType; // 'individual' or 'company'
  String? companyName;
  String? paymentMethod; // 'sumup' | 'cod'
  String? paymentStatus; // 'paid_unverified' | 'pay_on_delivery'
  double totalPrice;
  String? collectionMethod;
  String? deliveryMethod;
  String? instructions;
  String? prepaidPackName;
  String? discountCode;
  double discountAmount;
  /// Services ticked on "Select a service" (bag orders, counted at the facility).
  List<String> selectedServices;
  /// Special cleaning request per service name.
  Map<String, String> serviceRequests;
  double tipAmount;
  bool repeatOrder;

  BookingData({
    this.addresses = const [],
    this.selectedAddress,
    this.deliveryAddress,
    this.collectionDate,
    this.collectionTime,
    this.deliveryDate,
    this.deliveryTime,
    this.selectedItems = const {},
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.specialInstructions = '',
    this.acceptedTerms = false,
    this.bookingReference,
    this.status,
    this.createdAt,
    this.customerType,
    this.companyName,
    this.paymentMethod,
    this.paymentStatus,
    this.totalPrice = 0.0,
    this.collectionMethod,
    this.deliveryMethod,
    this.instructions,
    this.prepaidPackName,
    this.discountCode,
    this.discountAmount = 0.0,
    this.selectedServices = const [],
    this.serviceRequests = const {},
    this.tipAmount = 0.0,
    this.repeatOrder = false,
  });

  BookingData copyWith({
    List<Address>? addresses,
    Address? selectedAddress,
    Address? deliveryAddress,
    String? collectionDate,
    String? collectionTime,
    String? deliveryDate,
    String? deliveryTime,
    Map<String, ServiceItem>? selectedItems,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? specialInstructions,
    bool? acceptedTerms,
    String? bookingReference,
    String? status,
    String? createdAt,
    String? customerType,
    String? companyName,
    String? paymentMethod,
    String? paymentStatus,
    double? totalPrice,
    String? collectionMethod,
    String? deliveryMethod,
    String? instructions,
    String? prepaidPackName,
    String? discountCode,
    double? discountAmount,
    List<String>? selectedServices,
    Map<String, String>? serviceRequests,
    double? tipAmount,
    bool? repeatOrder,
  }) {
    return BookingData(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      collectionDate: collectionDate ?? this.collectionDate,
      collectionTime: collectionTime ?? this.collectionTime,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      selectedItems: selectedItems ?? this.selectedItems,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      bookingReference: bookingReference ?? this.bookingReference,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customerType: customerType ?? this.customerType,
      companyName: companyName ?? this.companyName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalPrice: totalPrice ?? this.totalPrice,
      collectionMethod: collectionMethod ?? this.collectionMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      instructions: instructions ?? this.instructions,
      prepaidPackName: prepaidPackName ?? this.prepaidPackName,
      discountCode: discountCode ?? this.discountCode,
      discountAmount: discountAmount ?? this.discountAmount,
      selectedServices: selectedServices ?? this.selectedServices,
      serviceRequests: serviceRequests ?? this.serviceRequests,
      tipAmount: tipAmount ?? this.tipAmount,
      repeatOrder: repeatOrder ?? this.repeatOrder,
    );
  }

  Map<String, dynamic> toJson() {
    // Pricing: items - discount + service fee + delivery fee (no tax).
    final basePrice = subtotal;
    final discSubtotal = discountedSubtotal;
    final totalAmount = this.totalAmount;

    return {
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'selectedAddress': selectedAddress?.toJson(),
      'deliveryAddress': deliveryAddress?.toJson(),
      'collectionDate': collectionDate,
      'collectionTime': collectionTime,
      'deliveryDate': deliveryDate,
      'deliveryTime': deliveryTime,
      'selectedItems': selectedItems.map((key, value) => MapEntry(key, {
        'category': value.category,
        'itemType': value.itemType,
        'price': value.price,
        'description': value.description,
      })),
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'specialInstructions': specialInstructions,
      'acceptedTerms': acceptedTerms,
      'bookingReference': bookingReference,
      'status': status,
      'createdAt': createdAt,
      'customerType': customerType,
      'companyName': companyName,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'totalPrice': basePrice, // Store the actual base price (subtotal)
      'discountAmount': discountAmount,
      'discountedSubtotal': discSubtotal,
      'transactionAmount': totalAmount, // total payable (no tax)
      'collectionMethod': collectionMethod,
      'deliveryMethod': deliveryMethod,
      'instructions': instructions,
      'prepaidPackName': prepaidPackName,
      'discountCode': discountCode,
      'selectedServices': selectedServices,
      'serviceRequests': serviceRequests,
      'tipAmount': tipAmount,
      'repeatOrder': repeatOrder ? 'weekly' : '', // same values as the website ('' = no repeat)
      // no items picked → the facility counts the bag and the customer approves the price
      'priceMode': selectedItems.isEmpty ? 'estimate' : 'fixed',
    };
  }

  factory BookingData.fromJson(Map<String, dynamic> json) {
    // Orders come from the app AND the website (numbers vs text) — read everything defensively.
    String str(Object? v) => v == null ? '' : '$v';
    String? opt(Object? v) => v == null ? null : '$v';
    double numv(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    Map<String, dynamic> map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    Address? addr(Object? v) => v is Map ? Address.fromJson(map(v)) : null;
    String price(Object? v) => v is num ? '£${v.toStringAsFixed(2)}' : str(v);

    return BookingData(
      addresses: ((json['addresses'] as List?) ?? const []).whereType<Map>().map((a) => Address.fromJson(map(a))).toList(),
      selectedAddress: addr(json['selectedAddress']),
      deliveryAddress: addr(json['deliveryAddress']),
      collectionDate: opt(json['collectionDate']),
      collectionTime: opt(json['collectionTime']),
      deliveryDate: opt(json['deliveryDate']),
      deliveryTime: opt(json['deliveryTime']),
      selectedItems: () {
        final raw = json['selectedItems'] ?? json['items'] ?? json['lines'];
        final Map<String, ServiceItem> res = {};
        if (raw is Map) {
          raw.forEach((key, value) {
            final v = map(value);
            final cat = str(v['category'] ?? 'General');
            final name = str(v['itemType'] ?? v['name'] ?? 'Garment');
            final qty = (v['quantity'] as num?)?.toInt() ?? (v['qty'] as num?)?.toInt() ?? 1;
            final p = price(v['unitPrice'] ?? v['price']);
            final desc = qty > 1 ? '$qty × $p' : str(v['description']);
            res['$key'] = ServiceItem(
              category: cat,
              itemType: qty > 1 ? '$qty× $name' : name,
              price: p,
              description: desc,
            );
          });
        } else if (raw is List) {
          for (int i = 0; i < raw.length; i++) {
            final v = map(raw[i]);
            final cat = str(v['category'] ?? 'General');
            final name = str(v['itemType'] ?? v['name'] ?? 'Garment');
            final qty = (v['quantity'] as num?)?.toInt() ?? (v['qty'] as num?)?.toInt() ?? 1;
            final p = price(v['unitPrice'] ?? v['price']);
            final desc = qty > 1 ? '$qty × $p' : str(v['description']);
            res['item_$i'] = ServiceItem(
              category: cat,
              itemType: qty > 1 ? '$qty× $name' : name,
              price: p,
              description: desc,
            );
          }
        }
        return res;
      }(),
      firstName: str(json['firstName']),
      lastName: str(json['lastName']),
      email: str(json['email']),
      phone: str(json['phone']),
      specialInstructions: str(json['specialInstructions']),
      acceptedTerms: json['acceptedTerms'] == true,
      bookingReference: opt(json['bookingReference']),
      status: opt(json['status']),
      createdAt: opt(json['createdAt']),
      customerType: opt(json['customerType']),
      companyName: opt(json['companyName']),
      paymentMethod: opt(json['paymentMethod']),
      paymentStatus: opt(json['paymentStatus']),
      totalPrice: numv(json['totalPrice']),
      collectionMethod: opt(json['collectionMethod'] ?? json['collectionHandoff']),
      deliveryMethod: opt(json['deliveryMethod'] ?? json['deliveryHandoff']),
      instructions: opt(json['instructions']),
      prepaidPackName: opt(json['prepaidPackName']),
      discountCode: opt(json['discountCode']),
      discountAmount: numv(json['discountAmount']),
      selectedServices: ((json['selectedServices'] as List?) ?? const []).map((e) => '$e').toList(),
      serviceRequests: map(json['serviceRequests']).map((k, v) => MapEntry(k, '$v')),
      tipAmount: numv(json['tipAmount']),
      repeatOrder: _isRepeat(json['repeatOrder']),
    );
  }

  int get selectedItemsCount => selectedItems.length;

  double get subtotal {
    return selectedItems.values
        .fold(0.0, (sum, item) => sum + item.numericPrice);
  }

  double get discountedSubtotal {
    return (subtotal - discountAmount).clamp(0.0, double.infinity);
  }

  bool get hasSelectedAddress => selectedAddress != null;
  bool get hasCollectionDateTime => collectionDate != null && collectionTime != null;
  bool get hasDeliveryDateTime => deliveryDate != null && deliveryTime != null;
  bool get hasContactInfo => firstName.isNotEmpty && phone.isNotEmpty;
  bool get isReadyForPayment => hasSelectedAddress && hasCollectionDateTime && hasDeliveryDateTime && hasContactInfo && acceptedTerms;

  /// Fixed fees. Tax has been removed from the order total.
  static const double serviceFee = 2.99;
  static const double deliveryFee = 0.0;

  /// Total payable = items - discount + service fee + delivery fee.
  double get totalAmount => discountedSubtotal + serviceFee + deliveryFee + tipAmount;

  /// Kept for older call sites.
  double get calculatedTotalPrice => totalAmount;
}

class Order {
  final String id;
  final String orderId;
  final BookingData bookingData;
  final String type; // 'regular' or 'prepaid_pack'
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final double? transactionAmount;
  final String? transactionId;
  final String? paymentMethod;

  Order({
    required this.id,
    required this.orderId,
    required this.bookingData,
    this.type = 'regular',
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.transactionAmount,
    this.transactionId,
    this.paymentMethod,
  });

  Order copyWith({
    String? id,
    String? orderId,
    BookingData? bookingData,
    String? type,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    double? transactionAmount,
    String? transactionId,
    String? paymentMethod,
  }) {
    return Order(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      bookingData: bookingData ?? this.bookingData,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    final addr = bookingData.selectedAddress ?? bookingData.deliveryAddress;
    final lat = addr?.latitude;
    final lng = addr?.longitude;
    return {
      'id': id,
      'orderId': orderId,
      'bookingData': bookingData.toJson(),
      'type': type,
      'status': status,
      if (addr != null) 'address': addr.toJson(),
      if (lat != null && lng != null) 'geo': {'lat': lat, 'lng': lng},
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'transactionAmount': transactionAmount,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final bMap = json['bookingData'] is Map ? Map<String, dynamic>.from(json['bookingData']) : <String, dynamic>{};
    if (!bMap.containsKey('selectedItems') && json.containsKey('selectedItems')) {
      bMap['selectedItems'] = json['selectedItems'];
    }
    if (!bMap.containsKey('items') && json.containsKey('items')) {
      bMap['items'] = json['items'];
    }
    if (!bMap.containsKey('totalPrice') && json.containsKey('subtotal')) {
      bMap['totalPrice'] = json['subtotal'];
    }
    if (!bMap.containsKey('transactionAmount') && (json.containsKey('totalAmount') || json.containsKey('transactionAmount'))) {
      bMap['transactionAmount'] = json['totalAmount'] ?? json['transactionAmount'];
    }

    final rawAmount = json['transactionAmount'] ?? json['totalAmount'] ?? bMap['transactionAmount'];

    return Order(
      id: '${json['id'] ?? ''}',
      orderId: '${json['orderId'] ?? ''}',
      bookingData: BookingData.fromJson(bMap),
      type: '${json['type'] ?? 'regular'}',
      status: '${json['status'] ?? 'pending'}',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? _parseDate(json['deliveredAt']) : null,
      transactionAmount: rawAmount is num ? rawAmount.toDouble() : double.tryParse('${rawAmount ?? ''}'),
      transactionId: json['transactionId']?.toString(),
      paymentMethod: json['paymentMethod']?.toString() ?? bMap['paymentMethod']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      final parsed = DateTime.tryParse(dateValue);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.now();
  }
}

/// Website saves the repeat as text (`weekly`, `fortnightly`…, `` = none); older app builds saved true/false.
bool _isRepeat(Object? v) {
  if (v is bool) return v;
  final s = (v ?? '').toString().trim().toLowerCase();
  return s.isNotEmpty && !const {'false', 'no', 'none', 'never', '0'}.contains(s);
}
