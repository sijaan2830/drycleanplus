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
        'name': 'Laundry & Ironing',
        'title': 'Laundry & Ironing',
        'description': 'For everyday laundry, bedsheets and towels with professional ironing.',
        'icon': 'assets/icons/Laundry & Ironing.png',
        'isActive': true,
        'order': 2,
        'items': [
          {'name': 'Shirt', 'price': '£2.45', 'category': 'Ironing'},
          {'name': 'T-Shirt', 'price': '£1.95', 'category': 'Ironing'},
          {'name': 'Trousers', 'price': '£3.45', 'category': 'Ironing'},
          {'name': 'Jeans', 'price': '£3.95', 'category': 'Ironing'},
          {'name': 'Bed Sheets', 'price': '£4.95', 'category': 'Bedding'},
          {'name': 'Pillowcase', 'price': '£1.95', 'category': 'Bedding'},
          {'name': 'Towel', 'price': '£2.45', 'category': 'Household'},
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
