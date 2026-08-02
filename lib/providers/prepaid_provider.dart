import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrepaidPack {
  final String id;
  final String name;
  final String description;
  final int itemCount;
  final int usedCount;
  final double price;
  final String itemType;
  final DateTime purchasedDate;
  final DateTime? expiryDate;
  final List<Map<String, dynamic>>? discounts;

  PrepaidPack({
    required this.id,
    required this.name,
    required this.description,
    required this.itemCount,
    this.usedCount = 0,
    required this.price,
    required this.itemType,
    required this.purchasedDate,
    this.expiryDate,
    this.discounts,
  });

  int get remainingCount => itemCount - usedCount;
  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isActive => remainingCount > 0 && !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'itemCount': itemCount,
      'usedCount': usedCount,
      'price': price,
      'itemType': itemType,
      'purchasedDate': purchasedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'discounts': discounts,
    };
  }

  factory PrepaidPack.fromJson(Map<String, dynamic> json) {
    return PrepaidPack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      itemCount: json['itemCount'],
      usedCount: json['usedCount'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      itemType: json['itemType'],
      purchasedDate: DateTime.parse(json['purchasedDate']),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      discounts: json['discounts'] != null ? List<Map<String, dynamic>>.from(json['discounts']) : null,
    );
  }

  PrepaidPack copyWith({
    String? id,
    String? name,
    String? description,
    int? itemCount,
    int? usedCount,
    double? price,
    String? itemType,
    DateTime? purchasedDate,
    DateTime? expiryDate,
  }) {
    return PrepaidPack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemCount: itemCount ?? this.itemCount,
      usedCount: usedCount ?? this.usedCount,
      price: price ?? this.price,
      itemType: itemType ?? this.itemType,
      purchasedDate: purchasedDate ?? this.purchasedDate,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

class PrepaidProvider extends ChangeNotifier {
  List<PrepaidPack> _packs = [];
  bool _isLoading = true;

  List<PrepaidPack> get packs => _packs;
  List<PrepaidPack> get activePacks => _packs.where((p) => p.isActive).toList();
  bool get isLoading => _isLoading;
  int get activePacksCount => activePacks.length;

  // Initialize from SharedPreferences
  Future<void> loadPacks() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final packsJson = prefs.getString('prepaid_packs');
    
    if (packsJson != null) {
      final List<dynamic> decoded = jsonDecode(packsJson);
      _packs = decoded.map((json) => PrepaidPack.fromJson(json)).toList();
    } else {
      // Load sample data if no saved packs
      _packs = _getSamplePacks();
      await _savePacks();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  List<PrepaidPack> _getSamplePacks() {
    return [
      PrepaidPack(
        id: '1',
        name: 'Trousers prepaid pack',
        description: 'For dry cleaning or wash & iron',
        itemCount: 5,
        usedCount: 2,
        price: 42.00,
        itemType: 'Trousers',
        purchasedDate: DateTime.now().subtract(const Duration(days: 15)),
        expiryDate: DateTime.now().add(const Duration(days: 75)),
        discounts: [
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
      ),
      PrepaidPack(
        id: '2',
        name: '2-Piece suits prepaid pack',
        description: 'For dry cleaning',
        itemCount: 5,
        usedCount: 0,
        price: 71.00,
        itemType: 'Suit',
        purchasedDate: DateTime.now().subtract(const Duration(days: 5)),
        expiryDate: DateTime.now().add(const Duration(days: 85)),
        discounts: [
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
      ),
    ];
  }

  Future<void> _savePacks() async {
    final prefs = await SharedPreferences.getInstance();
    final packsJson = jsonEncode(_packs.map((p) => p.toJson()).toList());
    await prefs.setString('prepaid_packs', packsJson);
  }

  Future<void> addPack(PrepaidPack pack) async {
    _packs.add(pack);
    await _savePacks();
    notifyListeners();
  }

  Future<void> updatePack(PrepaidPack pack) async {
    final index = _packs.indexWhere((p) => p.id == pack.id);
    if (index != -1) {
      _packs[index] = pack;
      await _savePacks();
      notifyListeners();
    }
  }

  Future<void> usePackItem(String packId) async {
    final index = _packs.indexWhere((p) => p.id == packId);
    if (index != -1) {
      final pack = _packs[index];
      if (pack.remainingCount > 0) {
        _packs[index] = pack.copyWith(usedCount: pack.usedCount + 1);
        await _savePacks();
        notifyListeners();
      }
    }
  }

  Future<void> removePack(String packId) async {
    _packs.removeWhere((p) => p.id == packId);
    await _savePacks();
    notifyListeners();
  }
}
