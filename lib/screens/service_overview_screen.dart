import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../providers/service_provider.dart';
import '../providers/user_provider.dart';
import '../providers/prepaid_provider.dart';
import '../services/firestore_service.dart';
import '../models/booking_models.dart';
import '../models/services_data.dart';

// ─── Service Ring Widget ────────────────────────────────────────────────────
class ServiceRing extends StatelessWidget {
  final Widget icon;
  final Color circleColor;
  final bool showOuterRing;

  const ServiceRing({
    super.key,
    required this.icon,
    this.circleColor = const Color(0xFF0084FF),
    this.showOuterRing = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showOuterRing) {
      return Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2.0),
        ),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          child: Center(child: icon),
        ),
      );
    } else {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
        child: Center(child: icon),
      );
    }
  }
}

// ─── Main Screen ────────────────────────────────────────────────────────────
class ServiceOverviewScreen extends StatefulWidget {
  final String serviceType;
  final bool isEditMode;

  const ServiceOverviewScreen({
    super.key,
    required this.serviceType,
    this.isEditMode = false,
  });

  @override
  State<ServiceOverviewScreen> createState() => _ServiceOverviewScreenState();
}

class _ServiceOverviewScreenState extends State<ServiceOverviewScreen> {
  String _selectedService = '';
  String _selectedCategory = '';
  Map<String, int> _itemQuantities = {};
  bool _isPriceCardExpanded = false;
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _availablePrepaidPacks = [];
  bool _isLoadingPacks = true;
  final Map<String, Uint8List> _imageCache = {};

  Color _bannerColorFor(String name) => AppColors.primaryBlue;

  @override
  void initState() {
    super.initState();
    // 1. Load initial data
    _loadItemsFromProvider();
    _loadPrepaidPacksFromFirestore();

    // 2. Initialize service selection synchronously to avoid first-frame flicker
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    if (widget.serviceType.isNotEmpty) {
      _selectedService = widget.serviceType;
    } else if (bookingProvider.selectedService != null) {
      _selectedService = bookingProvider.selectedService!;
    } else {
      final services = serviceProvider.servicesAsMap;
      if (services.isNotEmpty) {
        _selectedService =
            services[0]['title'] ?? services[0]['name'] ?? '';
      }
    }

    if (_selectedService.isNotEmpty) {
      // Use microtask to avoid "setState() or markNeedsBuild() called during build" errors
      Future.microtask(() => bookingProvider.setSelectedService(_selectedService));
      
      // Initialize category synchronously as well
      final cats = _categoriesForService(_selectedService);
      if (cats.isNotEmpty) {
        _selectedCategory = cats[0];
      }
    }
  }

  Future<void> _loadPrepaidPacksFromFirestore() async {
    try {
      final snapshot = await _firestoreService.getPrepaidPacks();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _availablePrepaidPacks =
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'name': data['name'] ?? '',
                  'description': data['description'] ?? '',
                  'discounts': data['discounts'] ?? [],
                  'isActive': data['isActive'] ?? true,
                  'order': data['order'] ?? 0,
                };
              }).toList()
                ..sort(
                  (a, b) => (a['order'] as int).compareTo(b['order'] as int),
                );
          _isLoadingPacks = false;
        });
      } else {
        setState(() => _isLoadingPacks = false);
      }
    } catch (e) {
      debugPrint('Error loading prepaid packs: $e');
      setState(() => _isLoadingPacks = false);
    }
  }

  void _resetCategory() {
    final cats = _categoriesForService(_selectedService);
    setState(() => _selectedCategory = cats.isNotEmpty ? cats[0] : '');
  }

  void _loadItemsFromProvider() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final existing = provider.bookingData.selectedItems;
    setState(() {
      _itemQuantities = {};
      for (var entry in existing.entries) {
        final item = entry.value;
        final key = '${item.category}_${item.itemType}';
        _itemQuantities[key] = (_itemQuantities[key] ?? 0) + 1;
      }
    });
  }

  List<Map<String, dynamic>> get _services {
    final sp = Provider.of<ServiceProvider>(context, listen: false);
    return sp.servicesAsMap;
  }

  Map<String, dynamic>? get _currentService {
    if (_selectedService.isEmpty || _services.isEmpty) return null;
    try {
      return _services.firstWhere(
        (s) => s['title'] == _selectedService || s['name'] == _selectedService,
        orElse: () => _services[0],
      );
    } catch (_) {
      return _services.isNotEmpty ? _services[0] : null;
    }
  }

  List<String> _categoriesForService(String serviceTitle) {
    final items = _getServiceItems(serviceTitle);

    final categoriesFromItems = items
        .where(
          (item) =>
              item['category'] != null &&
              item['category'].toString().isNotEmpty,
        )
        .map((item) => item['category'].toString())
        .toSet()
        .toList();

    if (categoriesFromItems.isNotEmpty) {
      categoriesFromItems.sort();
      return categoriesFromItems;
    }

    final svc = _services.isEmpty
        ? null
        : _services.firstWhere(
            (s) => s['title'] == serviceTitle || s['name'] == serviceTitle,
            orElse: () => <String, dynamic>{},
          );

    if (svc != null && svc.isNotEmpty && svc['categories'] != null) {
      return List<String>.from(svc['categories'] as List);
    }

    return [];
  }

  List<Map<String, dynamic>> _getServiceItems(String serviceTitle) {
    try {
      final svc = _services.firstWhere(
        (s) => s['name'] == serviceTitle || s['title'] == serviceTitle,
        orElse: () => <String, dynamic>{},
      );
      if (svc.isNotEmpty && svc['items'] != null) {
        return List<Map<String, dynamic>>.from(svc['items'] as List);
      }
    } catch (_) {}

    switch (serviceTitle) {
      case 'Dry Clean':
      case 'Dry Cleaning':
        return [
          {'name': 'Shirt on Hanger', 'price': '£2.95', 'category': 'Shirts'},
          {'name': 'T-Shirt', 'price': '£2.50', 'category': 'Tops'},
          {'name': 'Blouse', 'price': '£3.95', 'category': 'Tops'},
          {'name': 'Trousers', 'price': '£4.45', 'category': 'Bottoms'},
          {'name': 'Skirt', 'price': '£3.95', 'category': 'Bottoms'},
          {'name': 'Suit (2pc)', 'price': '£8.95', 'category': 'Suits'},
          {'name': 'Suit Jacket', 'price': '£5.95', 'category': 'Suits'},
          {'name': 'Dress', 'price': '£5.95', 'category': 'Dresses'},
          {'name': 'Evening Gown', 'price': '£9.95', 'category': 'Dresses'},
          {'name': 'Coat', 'price': '£7.95', 'category': 'Outerwear'},
          {'name': 'Jacket', 'price': '£5.95', 'category': 'Outerwear'},
        ];
      case 'Wash & Iron':
        return [
          {'name': 'Shirt on Hanger', 'price': '£2.95', 'category': 'Shirts'},
          {'name': 'T-Shirt', 'price': '£1.95', 'category': 'Tops'},
          {'name': 'Blouse', 'price': '£2.95', 'category': 'Tops'},
          {'name': 'Trousers', 'price': '£3.45', 'category': 'Bottoms'},
          {'name': 'Jeans', 'price': '£3.95', 'category': 'Bottoms'},
          {'name': 'Dress', 'price': '£5.95', 'category': 'Dresses'},
          {'name': 'Jacket', 'price': '£4.95', 'category': 'Outerwear'},
        ];
      case 'Ironing only':
        return [
          {'name': 'Shirt on Hanger', 'price': '£2.80', 'category': 'Shirts'},
          {'name': 'T-Shirt', 'price': '£1.45', 'category': 'Tops'},
          {'name': 'Blouse', 'price': '£2.50', 'category': 'Tops'},
          {'name': 'Trousers', 'price': '£2.95', 'category': 'Bottoms'},
          {'name': 'Dress', 'price': '£4.95', 'category': 'Dresses'},
          {'name': 'Jacket', 'price': '£3.95', 'category': 'Outerwear'},
        ];
      case 'Duvets & Bulky Items':
        return [
          {
            'name': 'Feather Duvet - Single',
            'price': '£20.95',
            'category': 'Feather duvets',
          },
          {
            'name': 'Feather Duvet - Double',
            'price': '£26.95',
            'category': 'Feather duvets',
          },
          {
            'name': 'Feather Duvet - King',
            'price': '£30.95',
            'category': 'Feather duvets',
          },
          {
            'name': 'Feather Duvet - Super King',
            'price': '£30.95',
            'category': 'Feather duvets',
          },
          {
            'name': 'Synthetic Duvet - Single',
            'price': '£18.95',
            'category': 'Synthetic duvets',
          },
          {
            'name': 'Synthetic Duvet - Double',
            'price': '£22.95',
            'category': 'Synthetic duvets',
          },
          {
            'name': 'Blanket - Single',
            'price': '£14.95',
            'category': 'Blankets',
          },
          {
            'name': 'Blanket - King',
            'price': '£18.95',
            'category': 'Blankets',
          },
        ];
      default:
        return [
          {'name': 'Standard Item', 'price': '£1.95', 'category': 'All items'},
        ];
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    final all = _getServiceItems(_selectedService);
    if (_selectedCategory.isEmpty || _selectedCategory == 'All items') {
      return all;
    }
    return all.where((item) => item['category'] == _selectedCategory).toList();
  }

  double get _totalPrice {
    double total = 0.0;
    _itemQuantities.forEach((key, qty) {
      final parts = key.split('_');
      if (parts.length >= 2) {
        final serviceName = parts[0];
        final itemName = parts.sublist(1).join('_');
        final items = _getServiceItems(serviceName);
        final item = items.firstWhere(
          (i) => i['name'] == itemName,
          orElse: () => {'price': '£0.00'},
        );
        final price =
            double.tryParse(
              (item['price'] as String).replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        total += price * qty;
      }
    });
    return total;
  }

  int get _totalItems => _itemQuantities.values.fold(0, (sum, q) => sum + q);

  void _updateItemQuantity(String itemName, String price, int change) {
    final key = '${_selectedService}_$itemName';
    final current = _itemQuantities[key] ?? 0;
    final next = current + change;
    if (next < 0) return;
    setState(() {
      if (next == 0) {
        _itemQuantities.remove(key);
      } else {
        _itemQuantities[key] = next;
      }
    });
    _updateProvider();
  }

  void _updateItemQuantityFromExpanded(
    String svc,
    String itemName,
    String price,
    int change,
  ) {
    final key = '${svc}_$itemName';
    final current = _itemQuantities[key] ?? 0;
    final next = current + change;
    if (next < 0) return;
    setState(() {
      if (next == 0) {
        _itemQuantities.remove(key);
      } else {
        _itemQuantities[key] = next;
      }
    });
    _updateProvider();
  }

  void _updateProvider() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final Map<String, ServiceItem> selectedItems = {};
    _itemQuantities.forEach((key, qty) {
      final parts = key.split('_');
      if (parts.length >= 2) {
        final serviceName = parts[0];
        final itemName = parts.sublist(1).join('_');
        final items = _getServiceItems(serviceName);
        final item = items.firstWhere(
          (i) => i['name'] == itemName,
          orElse: () => {'name': itemName, 'price': '£0.00'},
        );
        for (int i = 0; i < qty; i++) {
          selectedItems['${key}_$i'] = ServiceItem(
            category: serviceName,
            itemType: itemName,
            price: item['price'],
          );
        }
      }
    });
    final updated = provider.bookingData.copyWith(
      selectedItems: selectedItems,
      totalPrice: _totalPrice,
    );
    provider.updateBookingData(updated);
    provider.setSelectedService(_selectedService);
  }

  Uint8List _base64ToImage(String base64String) {
    if (_imageCache.containsKey(base64String)) {
      return _imageCache[base64String]!;
    }
    try {
      final parts = base64String.split(',');
      final data = parts.length > 1 ? parts[1] : parts[0];
      final decoded = base64Decode(data);
      _imageCache[base64String] = decoded;
      return decoded;
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return Uint8List(0);
    }
  }

  Widget _buildIconImage(
    Map<String, dynamic> service, {
    double size = 28,
    Color fallbackColor = Colors.white,
  }) {
    final imageUrl = service['imageUrl'] ?? '';
    final iconPath = service['iconPath'] ?? service['icon'] ?? '';

    if (imageUrl.isNotEmpty && imageUrl.startsWith('data:image/')) {
      try {
        return ClipOval(
          child: Image.memory(
            _base64ToImage(imageUrl),
            key: ValueKey('icon_$imageUrl'),
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      } catch (_) {}
    }
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        key: ValueKey('icon_$imageUrl'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Icon(
          Icons.local_laundry_service,
          color: fallbackColor,
          size: size * 0.7,
        ),
      );
    }
    if (iconPath.isNotEmpty) {
      return Image.asset(
        iconPath,
        key: ValueKey('icon_$iconPath'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Icon(
          Icons.local_laundry_service,
          color: fallbackColor,
          size: size * 0.7,
        ),
      );
    }
    return Icon(
      Icons.local_laundry_service,
      color: fallbackColor,
      size: size * 0.7,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          'Service overview',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceIconRow(),
                  _buildServiceBanner(),
                  _buildPricelistSection(),
                  const SizedBox(height: 180),
                ],
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  // ── Service icon row ───────────────────────────────────────────────────────
  Widget _buildServiceIconRow() {
    return Consumer<ServiceProvider>(
      builder: (context, sp, _) {
        final services = sp.servicesAsMap;
        return SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final svc = services[i];
              final name = svc['title'] ?? svc['name'] ?? '';
              final isSelected = _selectedService == name;
              final bgColor = _bannerColorFor(name);
              final circleColor = Color.lerp(bgColor, Colors.black, 0.15)!;

              final Color resolvedColor =
                  svc['color'] is Color
                      ? (svc['color'] as Color)
                      : circleColor;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedService = name;
                    _resetCategory();
                  });
                  Provider.of<BookingProvider>(
                    context,
                    listen: false,
                  ).setSelectedService(name);
                },
                child: ServiceRing(
                  key: ValueKey('ring_$name'),
                  circleColor: resolvedColor,
                  showOuterRing: isSelected,
                  icon: _buildIconImage(
                    svc,
                    size: 26,
                    fallbackColor: Colors.white,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Service banner ─────────────────────────────────────────────────────────
  Widget _buildServiceBanner() {
    final svc = _currentService;
    if (svc == null) return const SizedBox.shrink();

    final name = svc['title'] ?? svc['name'] ?? '';
    final description = svc['description'] ?? '';
    final bannerColor = _bannerColorFor(name);

    return Container(
      width: double.infinity,
      height: (MediaQuery.sizeOf(context).height * 0.22).clamp(150.0, 210.0),
      decoration: BoxDecoration(
        color: bannerColor,
        border: Border.all(color: AppColors.gold, width: 2.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: ClipOval(
              child: _buildIconImage(
                svc,
                size: 120,
                fallbackColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pricelist section ──────────────────────────────────────────────────────
  Widget _buildPricelistSection() {
    final svc = _currentService;
    if (svc == null) return const SizedBox.shrink();

    final cats = _categoriesForService(_selectedService);
    final items = _filteredItems;
    final priceLabel = svc['priceLabel'] ?? 'Price per item';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Text(
                'Pricelist',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                priceLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        _buildCategoryChips(cats),
        const SizedBox(height: 8),
        // Item rows — "Can't find your item" card is removed entirely
        ...items.map((item) {
          final key = '${_selectedService}_${item['name']}';
          final qty = _itemQuantities[key] ?? 0;
          return _buildItemRow(item['name'], item['price'], qty);
        }),
        _buildPrepaidSection(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildItemRow(String name, String price, int qty) {
    return _ItemRow(
      key: ValueKey('item_$name'),
      name: name,
      price: price,
      qty: qty,
      onAdd: () => _updateItemQuantity(name, price, 1),
      onRemove: () => _updateItemQuantity(name, price, -1),
    );
  }

  // ── Prepaid pack horizontal scroll ────────────────────────────────────────
  Widget _buildPrepaidSection() {
    if (_isLoadingPacks) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_availablePrepaidPacks.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.primaryBlueDark.withOpacity(0.5),
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Save up to 20% with our prepaid packs!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availablePrepaidPacks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              padding: const EdgeInsets.only(right: 16),
              itemBuilder: (context, i) {
                final pack = _availablePrepaidPacks[i];
                return _buildPrepaidPackCard(pack);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepaidPackCard(Map<String, dynamic> pack) {
    final discounts =
        (pack['discounts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    if (discounts.isEmpty) return const SizedBox.shrink();
    final item = discounts[0];

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/prepaid'),
      child: SizedBox(
        width: 150,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 18),
                  // Shirt Icon
                  const Icon(
                    Icons.dry_cleaning,
                    color: AppColors.gold,
                    size: 26,
                  ),
                  const SizedBox(height: 10),
                  // Label Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "${item['count']} ${item['label']}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Discounted Original Price
                  Text(
                    "was £${item['old']}",
                    style: GoogleFonts.inter(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Footer Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(9),
                      ),
                    ),
                    child: Text(
                      "View Offer",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Discount sticker ─────────────────────────────────────────────
            Positioned(
              top: -10,
              right: -5,
              child: SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: SunburstPainter(color: const Color(0xFFD32F2F)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${item['off']}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'OFF',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBlueDark,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: const Border(
              top: BorderSide(color: AppColors.gold, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedCrossFade(
                  firstChild:
                      const SizedBox(width: double.infinity, height: 0),
                  secondChild: _buildExpandedItemsList(),
                  crossFadeState: _isPriceCardExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 260),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      // ── Estimated price row — NO gold circle/ball ────────
                      GestureDetector(
                        onTap: () => setState(
                          () => _isPriceCardExpanded = !_isPriceCardExpanded,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated price',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '£${_totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Plain icon only — gold ball removed
                            Icon(
                              _isPriceCardExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: Colors.white70,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _totalItems > 0
                              ? () {
                                  _updateProvider();
                                  if (widget.isEditMode) {
                                    Navigator.of(context).pop();
                                  } else {
                                    final userProvider =
                                        Provider.of<UserProvider>(
                                      context,
                                      listen: false,
                                    );
                                    final bookingProvider =
                                        Provider.of<BookingProvider>(
                                      context,
                                      listen: false,
                                    );
                                    if (userProvider.hasAddress &&
                                        userProvider.hasUserData &&
                                        userProvider.phone.isNotEmpty) {
                                      if (bookingProvider
                                              .bookingData.selectedAddress ==
                                          null) {
                                        bookingProvider.selectAddress(
                                          Address(
                                            id: userProvider.savedAddressId ??
                                                'saved',
                                            line1: userProvider
                                                    .savedAddressLine1 ??
                                                '',
                                            line2:
                                                userProvider.savedAddressLine2,
                                            city:
                                                userProvider.savedCity ?? '',
                                            postalCode:
                                                userProvider.savedPostcode ??
                                                '',
                                            isDefault: true,
                                          ),
                                        );
                                      }
                                      bookingProvider.updateContactInfo(
                                        firstName: userProvider.firstName,
                                        lastName: userProvider.lastName,
                                        phone: userProvider.phone,
                                        customerType:
                                            userProvider.customerType,
                                        companyName: userProvider.companyName,
                                      );
                                      Navigator.of(context)
                                          .pushNamed('/time_slots');
                                    } else {
                                      Navigator.of(context).pushNamed(
                                        '/address_selection',
                                        arguments: {
                                          'isFromBookingFlow': true,
                                        },
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _totalItems > 0
                                ? AppColors.gold
                                : Colors.blueGrey.withOpacity(0.3),
                            foregroundColor: _totalItems > 0
                                ? AppColors.primaryBlueDark
                                : Colors.white38,
                            disabledBackgroundColor:
                                Colors.blueGrey.withOpacity(0.3),
                            disabledForegroundColor: Colors.white38,
                            elevation: _totalItems > 0 ? 8 : 0,
                            shadowColor:
                                AppColors.gold.withValues(alpha: 0.3),
                            padding:
                                const EdgeInsets.symmetric(vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _totalItems > 0
                                    ? Colors.white
                                    : Colors.white10,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'SCHEDULE A COLLECTION',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: _totalItems > 0
                                          ? AppColors.primaryBlueDark
                                          : Colors.white38,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _totalItems > 0
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: _totalItems > 0
                                      ? AppColors.primaryBlueDark
                                      : Colors.white38,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Expanded items list ────────────────────────────────────────────────────
  Widget _buildExpandedItemsList() {
    final selected = <Map<String, dynamic>>[];
    _itemQuantities.forEach((key, qty) {
      final parts = key.split('_');
      if (parts.length >= 2) {
        final serviceName = parts[0];
        final itemName = parts.sublist(1).join('_');
        final items = _getServiceItems(serviceName);
        final item = items.firstWhere(
          (i) => i['name'] == itemName,
          orElse: () => {'name': itemName, 'price': '£0.00'},
        );
        selected.add({
          'serviceName': serviceName,
          'name': itemName,
          'price': item['price'],
          'quantity': qty,
        });
      }
    });

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected items',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            if (selected.isEmpty)
              Text(
                'No items selected yet.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              )
            else
              ...selected.map((item) {
                final priceVal =
                    double.tryParse(
                      (item['price'] as String).replaceAll(
                        RegExp(r'[^0-9.]'),
                        '',
                      ),
                    ) ??
                    0.0;
                final total = priceVal * (item['quantity'] as int);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              item['serviceName'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 1),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _updateItemQuantityFromExpanded(
                                item['serviceName'],
                                item['name'],
                                item['price'],
                                -1,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Text(
                              '${item['quantity']}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.gold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _updateItemQuantityFromExpanded(
                                item['serviceName'],
                                item['name'],
                                item['price'],
                                1,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '£${total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: Text(
                '* The estimate is for your information only. The final price will be calculated once we clean your items.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────
  Widget _buildCategoryChips(List<String> cats) {
    if (cats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = cats[i];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.gold : Colors.white30,
                  width: 1.2,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primaryBlueDark : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Item Row — price in WHITE ──────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final String name;
  final String price;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ItemRow({
    super.key,
    required this.name,
    required this.price,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
              // Price → WHITE
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              if (qty > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'x',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlueDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30, width: 1.2),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white10,
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: Colors.white10,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}

class SunburstPainter extends CustomPainter {
  final Color color;
  final int points;

  SunburstPainter({required this.color, this.points = 18});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.82;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withRed((color.red - 20).clamp(0, 255)),
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: outerRadius))
      ..style = PaintingStyle.fill;

    final path = Path();
    final angleStep = (math.pi * 2) / (points * 2);

    for (int i = 0; i <= points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(i * angleStep - math.pi / 2);
      final y = centerY + radius * math.sin(i * angleStep - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.4), 3, false);
    canvas.drawPath(path, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}