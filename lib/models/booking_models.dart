import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String line1;
  final String? line2;
  final String city;
  final String postalCode;
  final bool isDefault;
  final String? buildingName;

  const Address({
    required this.id,
    required this.line1,
    this.line2,
    required this.city,
    required this.postalCode,
    this.isDefault = false,
    this.buildingName,
  });

  Address copyWith({
    String? id,
    String? line1,
    String? line2,
    String? city,
    String? postalCode,
    bool? isDefault,
    String? buildingName,
  }) {
    return Address(
      id: id ?? this.id,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      buildingName: buildingName ?? this.buildingName,
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
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      line1: json['line1'] ?? '',
      line2: json['line2'],
      city: json['city'] ?? '',
      postalCode: json['postalCode'] ?? '',
      isDefault: json['isDefault'] ?? false,
      buildingName: json['buildingName'],
    );
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
  String? paymentMethod;
  double totalPrice;
  String? collectionMethod;
  String? deliveryMethod;
  String? instructions;
  String? prepaidPackName;
  String? discountCode;
  double discountAmount;

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
    this.totalPrice = 0.0,
    this.collectionMethod,
    this.deliveryMethod,
    this.instructions,
    this.prepaidPackName,
    this.discountCode,
    this.discountAmount = 0.0,
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
    double? totalPrice,
    String? collectionMethod,
    String? deliveryMethod,
    String? instructions,
    String? prepaidPackName,
    String? discountCode,
    double? discountAmount,
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
      totalPrice: totalPrice ?? this.totalPrice,
      collectionMethod: collectionMethod ?? this.collectionMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      instructions: instructions ?? this.instructions,
      prepaidPackName: prepaidPackName ?? this.prepaidPackName,
      discountCode: discountCode ?? this.discountCode,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  Map<String, dynamic> toJson() {
    // Calculate total amount with tax and fees for storage
    // Use calculatedTotalPrice as the base price (not totalPrice which might be 0)
    final basePrice = subtotal;
    final discSubtotal = discountedSubtotal;
    final serviceFee = 2.99;
    final deliveryFee = 0.0;
    final taxRate = 0.20; // 20% tax
    final tax = (discSubtotal + serviceFee + deliveryFee) * taxRate;
    final totalAmount = discSubtotal + serviceFee + deliveryFee + tax;
    
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
      'totalPrice': basePrice, // Store the actual base price (subtotal)
      'discountAmount': discountAmount,
      'discountedSubtotal': discSubtotal,
      'transactionAmount': totalAmount, // Store total amount with tax and fees
      'collectionMethod': collectionMethod,
      'deliveryMethod': deliveryMethod,
      'instructions': instructions,
      'prepaidPackName': prepaidPackName,
      'discountCode': discountCode,
      'discountAmount': discountAmount,
    };
  }

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((a) => Address.fromJson(a))
          .toList() ?? [],
      selectedAddress: json['selectedAddress'] != null
          ? Address.fromJson(json['selectedAddress'])
          : null,
      deliveryAddress: json['deliveryAddress'] != null
          ? Address.fromJson(json['deliveryAddress'])
          : null,
      collectionDate: json['collectionDate'],
      collectionTime: json['collectionTime'],
      deliveryDate: json['deliveryDate'],
      deliveryTime: json['deliveryTime'],
      selectedItems: (json['selectedItems'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, ServiceItem(
          category: value['category'] ?? '',
          itemType: value['itemType'] ?? '',
          price: value['price'] ?? '',
          description: value['description'] ?? '',
        )),
      ) ?? {},
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      specialInstructions: json['specialInstructions'] ?? '',
      acceptedTerms: json['acceptedTerms'] ?? false,
      bookingReference: json['bookingReference'],
      status: json['status'],
      createdAt: json['createdAt'],
      customerType: json['customerType'],
      companyName: json['companyName'],
      paymentMethod: json['paymentMethod'],
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      collectionMethod: json['collectionMethod'],
      deliveryMethod: json['deliveryMethod'],
      instructions: json['instructions'],
      prepaidPackName: json['prepaidPackName'],
      discountCode: json['discountCode'],
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
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

  double get calculatedTotalPrice {
    // Calculate total amount with tax and fees
    const serviceFee = 2.99;
    const deliveryFee = 0.0;
    const taxRate = 0.20; // 20% tax
    final discSubtotal = discountedSubtotal;
    final tax = (discSubtotal + serviceFee + deliveryFee) * taxRate;
    return discSubtotal + serviceFee + deliveryFee + tax;
  }
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
    return {
      'id': id,
      'orderId': orderId,
      'bookingData': bookingData.toJson(),
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'transactionAmount': transactionAmount,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      bookingData: BookingData.fromJson(json['bookingData'] ?? {}),
      type: json['type'] ?? 'regular',
      status: json['status'] ?? 'pending',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? _parseDate(json['deliveredAt']) : null,
      transactionAmount: (json['transactionAmount'] as num?)?.toDouble(),
      transactionId: json['transactionId'],
      paymentMethod: json['paymentMethod'],
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
