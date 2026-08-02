import 'package:flutter/material.dart';

class ServicesData {
  static final List<Map<String, dynamic>> services = [
    {
      'title': 'Dry Clean',
      'description': 'Expert dry cleaning for delicate fabrics and formal wear.',
      'tags': ['DRY CLEANING', 'IRONING', 'ON HANGERS'],
      'priceLabel': 'Price per item',
      'price': '2.95',
      'color': const Color(0xFF4FD1C5),
      'iconPath': 'assets/icons/dry cleaning.png',
    },
    {
      'title': 'Duvets & Bedding',
      'description': 'Specialized cleaning for duvets, pillows, and bedding items.',
      'tags': ['DUVETS', 'PILLOWS', 'BEDDING'],
      'priceLabel': 'Price per item',
      'price': '11.95',
      'color': const Color(0xFFDBEAFE),
      'iconPath': 'assets/icons/Duvets & Bedding.png',
    },
    {
      'title': 'Household Items',
      'description': 'Professional cleaning for curtains, rugs, and household textiles.',
      'tags': ['CURTAINS', 'RUGS', 'HOUSEHOLD'],
      'priceLabel': 'Price per item',
      'price': '8.95',
      'color': const Color(0xFFF9A8D4),
      'iconPath': 'assets/icons/Household Items.png',
    },
    {
      'title': 'Laundry & Ironing',
      'description': 'For everyday laundry, bedsheets and towels with professional ironing.',
      'tags': ['WASH', 'TUMBLE-DRY', 'IRONING'],
      'priceLabel': 'Price per weight',
      'price': '18.85',
      'unit': '6kg',
      'color': const Color(0xFF1DA1F2),
      'iconPath': 'assets/icons/Laundry & Ironing.png',
    },
  ];
}
