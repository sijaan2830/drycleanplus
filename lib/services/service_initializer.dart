import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceInitializer {
  static Future<void> initializeServices() async {
    final firestore = FirebaseFirestore.instance;
    
    final services = [
      {
        'name': 'Dry Clean',
        'title': 'Dry Clean',
        'description': 'Expert dry cleaning for delicate fabrics and formal wear.',
        'icon': 'assets/icons/dry cleaning.png',
        'isActive': true,
        'order': 1,
        'items': [
          {'name': 'Shirt', 'price': '£3.45', 'category': 'Shirts'},
          {'name': 'Blouse', 'price': '£3.95', 'category': 'Tops'},
          {'name': 'Trousers', 'price': '£4.45', 'category': 'Bottoms'},
          {'name': 'Skirt', 'price': '£3.95', 'category': 'Bottoms'},
          {'name': 'Suit', 'price': '£8.95', 'category': 'Suits'},
          {'name': 'Jacket', 'price': '£5.95', 'category': 'Suits'},
          {'name': 'Dress', 'price': '£5.95', 'category': 'Dresses'},
          {'name': 'Coat', 'price': '£7.95', 'category': 'Outerwear'},
          {'name': 'Scarf', 'price': '£1.45', 'category': 'Accessories'},
          {'name': 'Tie', 'price': '£1.95', 'category': 'Accessories'},
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Wash & Fold',
        'title': 'Wash & Fold',
        'description': 'Everyday casuals, towels and bedsheets washed and folded. Weighed at your doorstep.',
        'icon': 'assets/icons/Laundry & Ironing.png',
        'isActive': true,
        'order': 2,
        'hint': 'Weighed right at your doorstep for fair, exact pricing',
        'items': [
          {'name': 'Standard Bag (up to 6kg)', 'price': '£16.50', 'category': 'By Bag'},
          {'name': 'Additional Weight (per extra kg)', 'price': '£3.00', 'category': 'By Weight'},
          {'name': 'Towels Pack (5 pcs)', 'price': '£14.00', 'category': 'Household'},
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Mix Ironing',
        'title': 'Mix Ironing',
        'description': 'Crisp steam ironing by weight. Weighed right at your doorstep.',
        'icon': 'assets/icons/Laundry & Ironing.png',
        'isActive': true,
        'order': 3,
        'hint': 'Weighed right at your doorstep for fair, exact pricing',
        'items': [
          {'name': 'Mix Ironing (per kg)', 'price': '£8.00', 'category': 'By Weight'},
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Wash & Iron',
        'title': 'Wash & Iron',
        'description': 'Full wash, tumble dry and crisp professional steam ironing by weight.',
        'icon': 'assets/icons/Laundry & Ironing.png',
        'isActive': true,
        'order': 4,
        'hint': 'Weighed right at your doorstep for fair, exact pricing',
        'items': [
          {'name': 'Wash & Iron (per kg)', 'price': '£10.00', 'category': 'By Weight'},
          {'name': 'Dress Shirt (on hanger)', 'price': '£3.50', 'category': 'Shirts'},
          {'name': 'Trousers / Chinos (pressed)', 'price': '£6.50', 'category': 'Trousers'},
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Duvets & Bedding',
        'title': 'Duvets & Bedding',
        'description': 'Specialized cleaning for duvets, pillows, and bedding items.',
        'icon': 'assets/icons/Duvets & Bedding.png',
        'isActive': true,
        'order': 3,
        'items': [
          {'name': 'Single Duvet', 'price': '£11.95', 'category': 'Synthetic'},
          {'name': 'Double Duvet', 'price': '£15.95', 'category': 'Synthetic'},
          {'name': 'King Duvet', 'price': '£19.95', 'category': 'Synthetic'},
          {'name': 'Super King Duvet', 'price': '£24.95', 'category': 'Synthetic'},
          {'name': 'Pillows', 'price': '£6.95', 'category': 'Accessories'},
          {'name': 'Bedspread', 'price': '£12.95', 'category': 'Bedding'},
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Household Items',
        'title': 'Household Items',
        'description': 'Professional cleaning for curtains, rugs, and household textiles.',
        'icon': 'assets/icons/Household Items.png',
        'isActive': true,
        'order': 4,
        'items': [
          {'name': 'Curtains', 'price': '£15.95', 'category': 'Curtains'},
          {'name': 'Tablecloth', 'price': '£8.95', 'category': 'Linens'},
          {'name': 'Napkins', 'price': '£2.95', 'category': 'Linens'},
          {'name': 'Small Rug', 'price': '£15.95', 'category': 'Rugs'},
          {'name': 'Large Rug', 'price': '£25.95', 'category': 'Rugs'},
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];

    final servicesCollection = firestore.collection('services');
    
    for (final service in services) {
      // Check if service already exists
      final existingSnapshot = await servicesCollection
          .where('name', isEqualTo: service['name'])
          .get();
      
      if (existingSnapshot.docs.isEmpty) {
        // Add new service
        await servicesCollection.add(service);
        print('Added service: ${service['name']}');
      } else {
        // Update existing service
        final docRef = existingSnapshot.docs.first.reference;
        await docRef.update(service);
        print('Updated service: ${service['name']}');
      }
    }
    
    print('Services initialization completed!');
  }
}
