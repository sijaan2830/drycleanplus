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
import '../services/firestore_service.dart';
import '../models/booking_models.dart';
import '../widgets/prepaid_pack_card.dart';
import '../widgets/service_price_card.dart';
import '../widgets/app_ui.dart';
import '../widgets/dryclean_loader.dart';
import 'onboarding_screen.dart';

class ServiceOverviewScreen extends StatefulWidget {
  final String serviceType;
  final bool isEditMode;
  final bool isGuest;
  /// Opened from "Prices & more" on Select a service — the button just adds this service and goes back.
  final bool fromBooking;

  const ServiceOverviewScreen({
    super.key,
    required this.serviceType,
    this.isEditMode = false,
    this.isGuest = false,
    this.fromBooking = false,
  });

  @override
  State<ServiceOverviewScreen> createState() => _ServiceOverviewScreenState();
}

class _CategoryTheme {
  final List<Color> gradientColors;
  final String assetImage;
  final String description;
  final String defaultFrom;
  final double rotationDeg;

  const _CategoryTheme({
    required this.gradientColors,
    required this.assetImage,
    required this.description,
    required this.defaultFrom,
    this.rotationDeg = 6.0,
  });
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _pillsScrollController = ScrollController();
  String _searchQuery = '';
  bool _navigatingToOnboarding = false;

  Future<void> _createAccount() async {
    if (_navigatingToOnboarding) return;
    _navigatingToOnboarding = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DrycleanLoader(),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => OnboardingScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pillsScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedPill() {
    if (!mounted || !_pillsScrollController.hasClients) return;
    final services = _services;
    final sel = _selectedService.trim().toLowerCase();
    final idx = services.indexWhere((s) {
      final name = (s['title'] ?? s['name'] ?? '').toString().trim().toLowerCase();
      final id = (s['id'] ?? '').toString().toLowerCase();
      return name == sel || id == sel;
    });
    if (idx >= 0) {
      final offset = (idx * 133.0 - 24.0).clamp(0.0, _pillsScrollController.position.maxScrollExtent);
      _pillsScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItemsFromProvider();
    _loadPrepaidPacksFromFirestore();

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final services = serviceProvider.servicesAsMap;

    String target = widget.serviceType;
    if (target.isEmpty && bookingProvider.selectedService != null) {
      target = bookingProvider.selectedService!;
    }

    if (target.isNotEmpty && services.isNotEmpty) {
      final match = services.firstWhere(
        (s) {
          final t = (s['title'] ?? s['name'] ?? '').toString().trim().toLowerCase();
          final id = (s['id'] ?? '').toString().toLowerCase();
          return t == target.trim().toLowerCase() || id == target.trim().toLowerCase();
        },
        orElse: () => services[0],
      );
      _selectedService = (match['title'] ?? match['name'] ?? target).toString();
    } else if (services.isNotEmpty) {
      _selectedService = (services[0]['title'] ?? services[0]['name'] ?? '').toString();
    } else {
      _selectedService = target;
    }

    if (_selectedService.isNotEmpty) {
      Future.microtask(() => bookingProvider.setSelectedService(_selectedService));
      final cats = _categoriesForService(_selectedService);
      if (cats.isNotEmpty) {
        _selectedCategory = cats[0];
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedPill();
    });
  }

  Future<void> _loadPrepaidPacksFromFirestore() async {
    try {
      final snapshot = await _firestoreService.getPrepaidPacks();
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _availablePrepaidPacks = snapshot.docs.map((doc) {
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
      if (!mounted) return;
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
    final sel = _selectedService.trim().toLowerCase();
    try {
      return _services.firstWhere(
        (s) {
          final t = (s['title'] ?? s['name'] ?? '').toString().trim().toLowerCase();
          final id = (s['id'] ?? '').toString().toLowerCase();
          return t == sel || id == sel;
        },
        orElse: () => _services[0],
      );
    } catch (_) {
      return _services.isNotEmpty ? _services[0] : null;
    }
  }

  /// Resolve the best matching icon asset for a service
  /// Resolve the best matching icon asset for a service
  String _resolveAssetForService(Map<String, dynamic> svc, String serviceTitle) {
    final key = (svc['iconKey'] ?? '').toString().toLowerCase().trim();
    if (key == 'ironing') return 'assets/images/ironing.png';
    if (key == 'special-items' || key == 'special') return 'assets/images/special-items.png';
    if (key == 'dry-cleaning' || key == 'dryclean') return 'assets/images/dry-cleaning.png';
    if (key == 'duvets-bedding' || key == 'duvet') return 'assets/images/duvets-bedding.png';
    if (key == 'household') return 'assets/images/household.png';
    if (key == 'shirts') return 'assets/images/shirts.png';
    if (key == 'suits') return 'assets/images/suits.png';
    if (key == 'shoes') return 'assets/images/shoes.png';
    if (key == 'curtains') return 'assets/images/curtains.png';
    if (key == 'rugs') return 'assets/images/rugs.png';
    if (key == 'alterations') return 'assets/images/alterations.png';
    if (key == 'wedding-dress') return 'assets/images/wedding-dress.png';
    if (key == 'laundry' || key == 'wash') return 'assets/images/laundry.png';

    final hosted = (svc['imageUrl'] ?? '').toString().toLowerCase();
    if (hosted.contains('ironing')) return 'assets/images/ironing.png';
    if (hosted.contains('special-items') || hosted.contains('special')) return 'assets/images/special-items.png';
    if (hosted.contains('dry-cleaning') || hosted.contains('dryclean')) return 'assets/images/dry-cleaning.png';
    if (hosted.contains('duvets-bedding') || hosted.contains('duvet')) return 'assets/images/duvets-bedding.png';
    if (hosted.contains('household')) return 'assets/images/household.png';
    if (hosted.contains('shirts')) return 'assets/images/shirts.png';
    if (hosted.contains('suits')) return 'assets/images/suits.png';
    if (hosted.contains('shoes')) return 'assets/images/shoes.png';
    if (hosted.contains('curtains')) return 'assets/images/curtains.png';
    if (hosted.contains('rugs')) return 'assets/images/rugs.png';
    if (hosted.contains('alterations')) return 'assets/images/alterations.png';
    if (hosted.contains('wedding-dress')) return 'assets/images/wedding-dress.png';
    if (hosted.contains('laundry') || hosted.contains('wash')) return 'assets/images/laundry.png';

    return _baseThemeForService(serviceTitle).assetImage;
  }

  /// Look of a service: artwork from its name, colours from the admin (else the shared rule).
  _CategoryTheme _themeForService(String serviceTitle) {
    final base = _baseThemeForService(serviceTitle);
    final target = serviceTitle.trim().toLowerCase();
    final svc = _services.where((s) {
      final t = (s['title'] ?? s['name'] ?? '').toString().trim().toLowerCase();
      final id = (s['id'] ?? '').toString().toLowerCase();
      return t == target || id == target;
    }).firstOrNull ?? {'title': serviceTitle};

    final desc = (svc['description'] != null && '${svc['description']}'.trim().isNotEmpty)
        ? '${svc['description']}'.trim()
        : base.description;
    final asset = _resolveAssetForService(svc, serviceTitle);

    return _CategoryTheme(
      gradientColors: serviceCardColors(svc),
      assetImage: asset,
      description: desc,
      defaultFrom: base.defaultFrom,
      rotationDeg: base.rotationDeg,
    );
  }

  _CategoryTheme _baseThemeForService(String serviceTitle) {
    final lower = serviceTitle.toLowerCase().trim();
    if (lower.contains('dry clean')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFFFFA3A8), Color(0xFFFF7B86)],
        assetImage: 'assets/images/dry-cleaning.png',
        description: 'Suits, coats, dresses & delicate garments expertly cleaned.',
        defaultFrom: '£2.50',
        rotationDeg: 7.0,
      );
    } else if (lower.contains('ironing') || lower == 'iron') {
      return const _CategoryTheme(
        gradientColors: [Color(0xFFDCD0FF), Color(0xFFB9A8FF)],
        assetImage: 'assets/images/ironing.png',
        description: 'Everyday ironing for shirts, trousers, linens & garments.',
        defaultFrom: '£1.00',
        rotationDeg: 0.0,
      );
    } else if (lower.contains('special') || lower.contains('leather') || lower.contains('suede')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFFFFD9A8), Color(0xFFF5B66B)],
        assetImage: 'assets/images/special-items.png',
        description: 'Leather, suede, wedding dresses, shoes, designer bags & UGG boots.',
        defaultFrom: '£18.95',
        rotationDeg: -6.0,
      );
    } else if (lower.contains('duvet') || lower.contains('bedding')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFFA9E3FF), Color(0xFF7BCBFB)],
        assetImage: 'assets/images/duvets-bedding.png',
        description: 'Feather & synthetic duvets, pillows, bedspreads & throws.',
        defaultFrom: '£14.95',
        rotationDeg: -8.0,
      );
    } else if (lower.contains('wash & fold') || lower.contains('service wash') || lower == 'wash') {
      return const _CategoryTheme(
        gradientColors: [Color(0xFFFFE58C), Color(0xFFFFCB4F)],
        assetImage: 'assets/images/laundry.png',
        description: 'Everyday wash, dry & fold service by weight.',
        defaultFrom: '£4.00',
        rotationDeg: -5.0,
      );
    } else if (lower.contains('wash & iron') || lower.contains('wash and iron')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFFC9F78E), Color(0xFFA6EB60)],
        assetImage: 'assets/images/shirts.png',
        description: 'Washed, tumble-dried and crisply pressed shirts & trousers.',
        defaultFrom: '£1.95',
        rotationDeg: 6.0,
      );
    } else {
      return const _CategoryTheme(
        gradientColors: [Color(0xFFA8F0D5), Color(0xFF5EDBB0)],
        assetImage: 'assets/images/household.png',
        description: 'Tablecloths, curtains, bed sheets & household fabrics.',
        defaultFrom: '£1.45',
        rotationDeg: 6.0,
      );
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
    if (_searchQuery.isNotEmpty) {
      return all
          .where((item) => item['name'].toString().toLowerCase().contains(_searchQuery))
          .toList();
    }
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
    HapticFeedback.selectionClick();
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
    HapticFeedback.selectionClick();
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
    double size = 36,
    Color fallbackColor = Colors.white,
  }) {
    final serviceName = (service['title'] ?? service['name'] ?? '').toString();
    final theme = _themeForService(serviceName);
    final hosted = (service['imageUrl'] ?? '').toString();

    // Prefer high-res bundled 3D/clean asset
    return Image.asset(
      theme.assetImage,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        if (hosted.startsWith('http')) {
          return hostedServiceIcon(hosted, size: size, fallback: '');
        }
        final imageUrl = service['imageUrl'] ?? '';
        if (imageUrl.isNotEmpty && imageUrl.startsWith('data:image/')) {
          try {
            return ClipOval(
              child: Image.memory(
                _base64ToImage(imageUrl),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            );
          } catch (_) {}
        }
        return Icon(
          Icons.local_laundry_service_rounded,
          color: fallbackColor,
          size: size * 0.7,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1245B5),
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.bgGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Soft background ambient circles from HTML (.wrap::before, .wrap::after)
                Positioned(
                  right: -150,
                  top: -140,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  left: -230,
                  top: 700,
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildServicePills(),
                              _buildHeroCard(),
                              _buildPricelistSection(),
                              SizedBox(height: keyboardOpen ? 24 : (widget.isGuest ? 120 : 190)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!keyboardOpen)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: widget.isGuest
                        ? _buildGuestBottomBar()
                        : _buildBookBar(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header (Circular Glass Back Button + Title) ─────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed(
                    widget.isGuest ? '/guest_prices' : '/home',
                  );
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              widget.isGuest
                  ? 'Service overview'
                  : (widget.isEditMode ? 'Edit your items' : 'Choose your items'),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── Category Pills Row (.cats / .cat) ──────────────────────────────────────
  Widget _buildServicePills() {
    return Consumer<ServiceProvider>(
      builder: (context, sp, _) {
        final services = sp.servicesAsMap;
        String nameOf(Map<String, dynamic> s) => (s['title'] ?? s['name'] ?? '').toString();

        return Container(
          height: 52,
          margin: const EdgeInsets.only(top: 14),
          child: ListView.separated(
            controller: _pillsScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final svc = services[i];
              final name = nameOf(svc);
              final isSelected = name.trim().toLowerCase() == _selectedService.trim().toLowerCase() ||
                  (svc['id'] != null && svc['id'].toString().toLowerCase() == _selectedService.trim().toLowerCase());
              final theme = _themeForService(name);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedService = name;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  _resetCategory();
                  Provider.of<BookingProvider>(context, listen: false).setSelectedService(name);
                  _scrollToSelectedPill();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 52,
                  padding: const EdgeInsets.fromLTRB(8, 0, 17, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: isSelected
                        ? LinearGradient(
                            begin: const Alignment(-0.8, -0.6),
                            end: const Alignment(0.8, 0.6),
                            colors: theme.gradientColors,
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.16),
                    border: Border.all(
                      color: isSelected ? Colors.white.withOpacity(0.55) : Colors.white.withOpacity(0.22),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: _buildIconImage(svc, size: 30),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFF0B1F5B) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Hero Card (.hero with pastel gradient, 3D disc, sparkle stars & chips) ──
  Widget _buildHeroCard() {
    final svc = _currentService;
    if (svc == null) return const SizedBox.shrink();

    final name = (svc['title'] ?? svc['name'] ?? _selectedService).toString();
    final theme = _themeForService(name);
    final items = _getServiceItems(name);

    // Compute lowest price dynamically
    double minPrice = double.infinity;
    for (final itm in items) {
      final p = double.tryParse((itm['price'] as String? ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
      if (p != null && p > 0 && p < minPrice) {
        minPrice = p;
      }
    }
    final fromPrice = minPrice != double.infinity ? '£${minPrice.toStringAsFixed(2)}' : theme.defaultFrom;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: const Alignment(-0.8, -0.6),
                end: const Alignment(0.8, 0.6),
                colors: theme.gradientColors,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF02104C).withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top-right background disc
                Positioned(
                  right: -70,
                  top: -70,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.34),
                    ),
                  ),
                ),
                // Bottom-left background ring
                Positioned(
                  left: -46,
                  bottom: -46,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.24), width: 15),
                    ),
                  ),
                ),

                // Card Content Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (constrained so it doesn't overlap floating disc)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 210),
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1F5B),
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 215),
                      child: Text(
                        theme.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F3274),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Chips Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Filled pill: From £X.XX
                        Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1F5B),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 7),
                              Text(
                                'From $fromPrice',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Outlined pill: Price per item
                        Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF0B1F5B).withOpacity(0.42),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.straighten_rounded,
                                size: 15,
                                color: const Color(0xFF0B1F5B).withOpacity(0.85),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Price per item',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0B1F5B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sparkle stars
          const Positioned(
            right: 140,
            top: -8,
            child: SparkleStarWidget(size: 15, color: Colors.white),
          ),
          const Positioned(
            right: 10,
            top: 96,
            child: SparkleStarWidget(size: 11, color: Colors.white),
          ),

          // 3D Floating Bobbing Icon Disc (.ic)
          Positioned(
            top: -26,
            right: 16,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.55),
                    spreadRadius: 6,
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: ClipOval(
                child: Transform.rotate(
                  angle: theme.rotationDeg * 3.14159 / 180,
                  child: Image.asset(
                    theme.assetImage,
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      final hosted = (svc['imageUrl'] ?? '').toString();
                      if (hosted.startsWith('http')) {
                        return Image.network(hosted, fit: BoxFit.contain);
                      }
                      return const Icon(Icons.dry_cleaning_rounded, size: 48, color: Color(0xFF0B1F5B));
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pricelist Section Header, Search, Subcategories & Items ────────────────
  Widget _buildPricelistSection() {
    final svc = _currentService;
    if (svc == null) return const SizedBox.shrink();

    final cats = _categoriesForService(_selectedService);
    final items = _filteredItems;
    final searching = _searchQuery.isNotEmpty;
    final theme = _themeForService(_selectedService);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (.ph)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: Row(
            children: [
              Text(
                'Pricelist',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} item${items.length == 1 ? '' : 's'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search Input (.search)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF02104C).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF5B6F99), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    cursorColor: const Color(0xFF0B1F5B),
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF0B1F5B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Search items (e.g. shirt, duvet)',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF5B6F99),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.close_rounded, color: Color(0xFF5B6F99), size: 20),
                  ),
              ],
            ),
          ),
        ),

        // Subcategory Pills (.subs)
        if (!searching && cats.length > 1) ...[
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final catName = cats[i];
                final isSelected = catName == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = catName);
                  },
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF02104C).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      catName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? const Color(0xFF0B1F5B) : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Item List (.list)
        const SizedBox(height: 14),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'No items found matching "$_searchQuery"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8F0FF),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final name = item['name'].toString();
            final key = '${_selectedService}_$name';
            final qty = _itemQuantities[key] ?? 0;
            return _ItemRow(
              key: ValueKey('item_${_selectedService}_$name'),
              name: name,
              price: '${item['price']}',
              qty: qty,
              categoryTheme: theme,
              onAdd: () => _updateItemQuantity(name, '${item['price']}', 1),
              onRemove: () => _updateItemQuantity(name, '${item['price']}', -1),
            );
          }),

        _buildPrepaidSection(),
      ],
    );
  }

  // ── Prepaid Packs Section ──────────────────────────────────────────────────
  Widget _buildPrepaidSection() {
    if (_isLoadingPacks) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_availablePrepaidPacks.isEmpty) return const SizedBox.shrink();

    final allPackOptions = <Map<String, dynamic>>[];
    for (final pack in _availablePrepaidPacks) {
      final discounts = (pack['discounts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      for (final item in discounts) {
        allPackOptions.add({
          'pack': pack,
          'item': item,
        });
      }
    }

    if (allPackOptions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2C7A).withOpacity(0.65),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.14)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFD25E), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save up to 20% with our prepaid packs!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/prepaid'),
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFD25E),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFFFFD25E)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 232,
            child: ListView.builder(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: allPackOptions.length,
              itemBuilder: (context, i) {
                final option = allPackOptions[i];
                final pack = option['pack'] as Map<String, dynamic>;
                final item = option['item'] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: PrepaidPackCard(
                    packName: pack['name'] ?? '',
                    item: item,
                    width: 165,
                    isBestValue: i % 2 == 1,
                    onTap: () => _purchasePrepaidPack(pack, item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _purchasePrepaidPack(Map<String, dynamic> pack, Map<String, dynamic> item) {
    if (widget.isGuest) {
      _createAccount();
      return;
    }
    final title = pack['name'] ?? 'Prepaid Pack';
    final count = int.tryParse(item['count']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 5;
    final price = double.tryParse(item['new']?.toString() ?? '0') ?? 0.0;
    final label = item['label'] ?? '';

    final provider = Provider.of<BookingProvider>(context, listen: false);
    final packItem = ServiceItem(
      category: 'Prepaid Pack',
      itemType: '$title - $count $label',
      price: '£${price.toStringAsFixed(2)}',
    );
    provider.clearBookingData();
    provider.addServiceItem(packItem);
    provider.setSelectedService('Prepaid Pack');
    provider.setPrepaidPackName(title);
    Navigator.of(context).pushNamed('/time_slots');
  }

  // ── Continue to Booking Checkout ──────────────────────────────────────────
  void _onContinue() {
    _updateProvider();
    if (widget.isEditMode) {
      Navigator.of(context).pop();
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (userProvider.hasAddress && userProvider.hasUserData && userProvider.phone.isNotEmpty) {
      if (bookingProvider.bookingData.selectedAddress == null) {
        bookingProvider.selectAddress(
          Address(
            id: userProvider.savedAddressId ?? 'saved',
            line1: userProvider.savedAddressLine1 ?? '',
            line2: userProvider.savedAddressLine2,
            city: userProvider.savedCity ?? '',
            postalCode: userProvider.savedPostcode ?? '',
            isDefault: true,
          ),
        );
      }
      bookingProvider.updateContactInfo(
        firstName: userProvider.firstName,
        lastName: userProvider.lastName,
        phone: userProvider.phone,
        customerType: userProvider.customerType,
        companyName: userProvider.companyName,
      );
      Navigator.of(context).pushNamed('/time_slots');
    } else {
      Navigator.of(context).pushNamed(
        '/address_selection',
        arguments: {'isFromBookingFlow': true},
      );
    }
  }

  // ── Guest Bottom Bar (Create an account card) ─────────────────────────────
  Widget _buildGuestBottomBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1245B5).withOpacity(0.0),
            const Color(0xFF092368).withOpacity(0.92),
            const Color(0xFF061748),
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad > 0 ? bottomPad + 6 : 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(width: 6),
              Text(
                'Ready to continue? Create an account to book.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'CREATE AN ACCOUNT',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: _createAccount,
          ),
        ],
      ),
    );
  }

  // ── Book now (Laundryheap-style: choose the service, the facility counts the bag) ──
  Widget _buildBookBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final service = _selectedService;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 10 ? bottomInset : 14),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton(
          onPressed: () {
            final bp = Provider.of<BookingProvider>(context, listen: false);
            if (!bp.bookingData.selectedServices.contains(service)) bp.toggleBagService(service);
            if (widget.fromBooking) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushNamed('/select_services');
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFDE047),
            foregroundColor: const Color(0xFF0B1F5B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 6,
            shadowColor: const Color(0x66020C3C),
          ),
          child: Text(
            widget.fromBooking ? 'SELECT THIS SERVICE' : 'BOOK NOW',
            style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: .6),
          ),
        ),
      ),
    );
  }

  // ── Floating Cart Bar (.cart) — no longer shown ──────────────────────────────
  Widget _buildFloatingCartBar() {
    final hasItems = _totalItems > 0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottomInset > 10 ? bottomInset : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2C7A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF020C3C).withOpacity(0.65),
            blurRadius: 40,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expandable drawer for selected items
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isPriceCardExpanded ? _buildExpandedItemsList() : const SizedBox(width: double.infinity),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Cart summary row (.ci)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasItems ? () => setState(() => _isPriceCardExpanded = !_isPriceCardExpanded) : null,
                  child: Row(
                    children: [
                      // Cart bag circle (.bag)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.14),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          if (hasItems)
                            Positioned(
                              top: -5,
                              right: -5,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD25E),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$_totalItems',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0B1F5B),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasItems ? '$_totalItems items in bag' : 'Add items to continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFCFE0FF),
                              ),
                            ),
                            Text(
                              '£${_totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.8,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasItems)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.14),
                          ),
                          child: AnimatedRotation(
                            turns: _isPriceCardExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 260),
                            child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // CTA Button (.cta)
                GestureDetector(
                  onTap: hasItems ? _onContinue : null,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.fromLTRB(22, 0, 8, 0),
                    decoration: BoxDecoration(
                      color: hasItems ? const Color(0xFFFFD25E) : Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isEditMode ? 'SAVE CHANGES' : 'SCHEDULE A COLLECTION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: hasItems ? const Color(0xFF0B1F5B) : Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasItems ? const Color(0xFF0B1F5B) : Colors.white.withOpacity(0.14),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: hasItems ? Colors.white : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Expanded selected-items list ───────────────────────────────────────────
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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.38),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected items',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (selected.isEmpty)
              Text(
                'No items selected yet.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white54),
              )
            else
              ...selected.map((item) {
                final priceVal =
                    double.tryParse(item['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                final qty = item['quantity'] as int;
                final total = priceVal * qty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'].toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              item['serviceName'].toString(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 16),
                              onPressed: () => _updateItemQuantityFromExpanded(
                                item['serviceName'],
                                item['name'],
                                item['price'].toString(),
                                -1,
                              ),
                            ),
                            Text(
                              '$qty',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                              onPressed: () => _updateItemQuantityFromExpanded(
                                item['serviceName'],
                                item['name'],
                                item['price'].toString(),
                                1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '£${total.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '* The estimate is for your information only. The final price will be calculated once we clean your items.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white60, height: 1.4),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item row with active pastel gradient, marker price & 46px stepper buttons
// ─────────────────────────────────────────────────────────────────────────────
/// Laundryheap-style: prices are for reference — no counting items before booking.
const bool kPriceListOnly = true;

class _ItemRow extends StatelessWidget {
  final String name;
  final String price;
  final int qty;
  final _CategoryTheme categoryTheme;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ItemRow({
    super.key,
    required this.name,
    required this.price,
    required this.qty,
    required this.categoryTheme,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = qty > 0;
    final priceVal = double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final totalPrice = priceVal * qty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: inCart
              ? LinearGradient(
                  begin: const Alignment(-0.8, -0.6),
                  end: const Alignment(0.8, 0.6),
                  colors: categoryTheme.gradientColors,
                )
              : null,
          color: inCart ? null : Colors.white,
          border: inCart
              ? Border.all(color: Colors.white.withOpacity(0.55), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF02104C).withOpacity(inCart ? 0.45 : 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1F5B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Price with marker highlight (.pm)
                        Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 2,
                              height: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: inCart
                                      ? Colors.white.withOpacity(0.7)
                                      : categoryTheme.gradientColors[0].withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                price,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0B1F5B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          ' / item',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F3274),
                          ),
                        ),
                        if (inCart) ...[
                          Text(
                            ' · Total £${totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1F5B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Button: 46x46 circular plus OR 46px pill stepper (.add / .step)
            if (!kPriceListOnly && !inCart)
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0B1F5B),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF02104C).withOpacity(0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
            else if (!kPriceListOnly)
              Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF0B1F5B),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF02104C).withOpacity(0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onRemove,
                      child: const SizedBox(
                        width: 42,
                        height: 46,
                        child: Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$qty',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onAdd,
                      child: const SizedBox(
                        width: 42,
                        height: 46,
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
