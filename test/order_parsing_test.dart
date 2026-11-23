import 'package:drycleanplus_app/models/booking_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: one website order (numeric prices) used to make the whole order list empty.
void main() {
  // Same shape as orders created by the website booking flow.
  final websiteOrder = <String, dynamic>{
    'id': 'web1',
    'orderId': 'DC26000050',
    'status': 'pending',
    'type': 'regular',
    'source': 'website',
    'userId': 'u1',
    'transactionAmount': 22.4,
    'paymentMethod': 'cod',
    'bookingData': {
      'acceptedTerms': true,
      'addresses': [
        {'line1': '74st James streets', 'city': 'London', 'postalCode': 'NG1 6FJ', 'isDefault': true, 'buildingName': ''},
      ],
      'selectedAddress': {'line1': '74st James streets', 'line2': '', 'city': 'London', 'postalCode': 'NG1 6FJ', 'isDefault': true, 'buildingName': ''},
      'deliveryAddress': {'line1': '74st James streets', 'city': 'London', 'postalCode': 'NG1 6FJ', 'isDefault': true},
      'collectionDate': 'Mon, 16 Nov',
      'collectionTime': '18:00 - 21:00',
      'deliveryDate': 'Wed, 18 Nov',
      'deliveryTime': '18:00 - 21:00',
      'collectionHandoff': 'Collect from me in person',
      'selectedItems': {
        'item_1': {'category': 'Dry Clean', 'description': '', 'itemType': 'Shirt', 'price': 3.4, 'quantity': 2},
      },
      'discountAmount': 0,
      'totalPrice': 22.4,
      'tipAmount': 0,
      'firstName': 'Test',
      'lastName': 'Customer',
      'phone': '07700900000',
      'email': 'test@example.com',
    },
  };

  // Shape written by the new Laundryheap-style app flow.
  final bagOrder = <String, dynamic>{
    'id': 'app1',
    'orderId': 'DC26000051',
    'status': 'pending',
    'type': 'quick_bag',
    'createdAt': null, // server timestamp not resolved yet (local snapshot)
    'bookingData': BookingData(
      selectedServices: const ['Dry Clean', 'Wash'],
      serviceRequests: const {'Dry Clean': 'No starch'},
      tipAmount: 3,
      repeatOrder: true,
      collectionDate: 'Today',
      collectionTime: '18:00 - 21:00',
      firstName: 'Test',
      phone: '07700900000',
    ).toJson(),
  };

  test('website order with numeric prices is readable', () {
    final o = Order.fromJson(websiteOrder);
    expect(o.orderId, 'DC26000050');
    expect(o.bookingData.selectedItems['item_1']!.price, '£3.40');
    expect(o.bookingData.selectedItems['item_1']!.numericPrice, 3.4);
    expect(o.bookingData.selectedAddress!.postalCode, 'NG1 6FJ');
    expect(o.bookingData.collectionMethod, 'Collect from me in person');
  });

  test('new bag order round-trips', () {
    final o = Order.fromJson(bagOrder);
    expect(o.type, 'quick_bag');
    expect(o.bookingData.selectedServices, ['Dry Clean', 'Wash']);
    expect(o.bookingData.serviceRequests['Dry Clean'], 'No starch');
    expect(o.bookingData.tipAmount, 3);
    expect(o.bookingData.repeatOrder, isTrue);
    expect(o.bookingData.selectedItems, isEmpty);
    expect(bagOrder['bookingData']['priceMode'], 'estimate');
    // service fee + tip, no items
    expect(o.bookingData.totalAmount, closeTo(BookingData.serviceFee + 3, 0.001));
  });

  test('odd values never throw', () {
    final weird = <String, dynamic>{
      'id': 'x',
      'orderId': 123,
      'transactionAmount': '19.99',
      'bookingData': {
        'selectedItems': {'a': {'price': '£2.00', 'itemType': 7}},
        'phone': 7700900000,
        'acceptedTerms': 'yes',
        'addresses': ['not a map'],
        'selectedAddress': 'not a map',
      },
    };
    final o = Order.fromJson(weird);
    expect(o.orderId, '123');
    expect(o.transactionAmount, 19.99);
    expect(o.bookingData.phone, '7700900000');
    expect(o.bookingData.addresses, isEmpty);
  });
}
