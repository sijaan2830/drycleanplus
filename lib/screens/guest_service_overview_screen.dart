import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/service_provider.dart';
import '../widgets/dryclean_loader.dart';
import 'onboarding_screen.dart';

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

class GuestServiceOverviewScreen extends StatefulWidget {
  final String serviceType;
  
  const GuestServiceOverviewScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<GuestServiceOverviewScreen> createState() => _GuestServiceOverviewScreenState();
}

class _GuestServiceOverviewScreenState extends State<GuestServiceOverviewScreen> {
  String _selectedService = '';
  String _selectedCategory = '';
  
  @override
  void initState() {
    super.initState();
    _selectedService = widget.serviceType;
  }
  
  // Use real-time services from ServiceProvider
  List<Map<String, dynamic>> get _services {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    return serviceProvider.servicesAsMap;
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for selected service
    if (_selectedService.isEmpty && _services.isNotEmpty) {
      _selectedService = _services[0]['name'];
    }
    
    // Safety check for categories
    final cats = _categoriesForService(_selectedService);
    if (_selectedCategory.isEmpty && cats.isNotEmpty) {
      _selectedCategory = cats[0];
    } else if (cats.isEmpty) {
      _selectedCategory = 'All items';
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: Text(
          'Service overview',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/guest_prices');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.white, size: 24),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/guest_prices',
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            // Main Content Area
            Expanded(
              child: _services.isEmpty 
               ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
               : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildServiceIcons(),
                    _buildServiceBanner(),
                    _buildPricelistContent(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action Section (Dark Blue Footer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: const Border(top: BorderSide(color: AppColors.gold, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ready to continue?',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Show loader
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const DrycleanLoader(),
                        );
                        
                        await Future.delayed(const Duration(seconds: 1));
                        
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => OnboardingScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.primaryBlue,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.white, width: 1.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create an account',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: AppColors.primaryBlue,
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
      ),
    );
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
    return [];
  }

  List<String> _categoriesForService(String serviceTitle) {
    final items = _getServiceItems(serviceTitle);
    final categoriesFromItems = items
        .where((item) => item['category'] != null && item['category'].toString().isNotEmpty)
        .map((item) => item['category'].toString())
        .toSet()
        .toList();

    if (categoriesFromItems.isNotEmpty) {
      categoriesFromItems.sort();
      return ['All items', ...categoriesFromItems];
    }
    return [];
  }

  List<Map<String, dynamic>> get _filteredItems {
    final all = _getServiceItems(_selectedService);
    if (_selectedCategory.isEmpty || _selectedCategory == 'All items') {
      return all;
    }
    return all
        .where((item) => item['category'] == _selectedCategory)
        .toList();
  }

  Widget _buildPricelistContent() {
    final svc = _services.firstWhere((service) => service['name'] == _selectedService || service['title'] == _selectedService, orElse: () => _services[0]);
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
        ...items.map((item) {
          return _buildItemRow(item['name'] ?? '', item['price'] ?? '', Icons.local_laundry_service);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

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

  Widget _buildItemRow(String name, String price, IconData icon) {
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
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
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

  Widget _buildServiceIcons() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final svc = _services[i];
          final name = svc['title'] ?? svc['name'] ?? '';
          final isSelected = _selectedService == name;
          
          final Color resolvedColor = svc['color'] is Color 
              ? (svc['color'] as Color) 
              : AppColors.gold;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedService = name;
              });
            },
            child: ServiceRing(
              key: ValueKey('ring_$name'),
              circleColor: isSelected ? resolvedColor : AppColors.white.withOpacity(0.1),
              showOuterRing: isSelected,
              icon: _buildServiceIcon(svc, isSelected),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceIcon(Map<String, dynamic> service, bool isSelected) {
    final imageUrl = service['imageUrl'] ?? '';
    final iconPath = service['iconPath'];
    const double size = 26;
    
    // Check if we have a base64 image from Firestore
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('data:image/')) {
        try {
            return Image.memory(
                _base64ToImage(imageUrl),
                width: size,
                height: size,
                fit: BoxFit.cover,
            );
        } catch (e) {
            return const Icon(Icons.local_laundry_service, color: Colors.white, size: size * 0.7);
        }
    }

    if (iconPath != null) {
      return Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.local_laundry_service,
            color: Colors.white,
            size: size * 0.7,
          );
        },
      );
    }
    
    return const Icon(
      Icons.local_laundry_service,
      color: Colors.white,
      size: size * 0.7,
    );
  }

  Widget _buildServiceBanner() {
    final svc = _services.firstWhere((service) => service['name'] == _selectedService || service['title'] == _selectedService, orElse: () => _services[0]);
    final name = svc['title'] ?? svc['name'] ?? '';
    final description = svc['description'] ?? '';

    return Container(
      width: double.infinity,
      height: (MediaQuery.sizeOf(context).height * 0.22).clamp(150.0, 210.0),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
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
              child: _buildBannerIcon(svc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerIcon(Map<String, dynamic> service) {
    final imageUrl = service['imageUrl'] ?? '';
    final iconPath = service['iconPath'];
    const double size = 120;
    
    // Check if we have a base64 image from Firestore
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('data:image/')) {
        try {
            return Image.memory(
                _base64ToImage(imageUrl),
                width: size,
                height: size,
                fit: BoxFit.cover,
            );
        } catch (e) {
            return const Icon(Icons.local_laundry_service, color: Colors.white, size: size * 0.7);
        }
    }

    if (iconPath != null) {
      return Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.local_laundry_service,
            color: Colors.white,
            size: size * 0.7,
          );
        },
      );
    }
    
    return const Icon(
      Icons.local_laundry_service,
      color: Colors.white,
      size: size * 0.7,
    );
  }

  Uint8List _base64ToImage(String base64String) {
    final base64Data = base64String.split(',')[1];
    return base64Decode(base64Data);
  }
}
