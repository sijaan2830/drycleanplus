import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/booking_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/skeleton_loading.dart';
import 'service_overview_screen.dart';
import '../models/services_data.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/dryclean_loader.dart';

class PricesScreen extends StatefulWidget {
  final bool? showBottomNav;

  const PricesScreen({super.key, this.showBottomNav});

  bool get _showBottomNav => showBottomNav ?? true;

  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceProvider>(context, listen: false)
          .initializeServicesListener();
    });
  }

  List<Map<String, dynamic>> get _pricingData {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    return serviceProvider.servicesAsMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue, // ← Consistent Blue background
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue, // ← Consistent Blue appbar
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light, // ← light icons on blue
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Prices',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white, // ← White title
                ),
              ),
            ),

            // Divider
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0x33FFFFFF), // ← white 20% opacity
            ),

            // Grid Content
            Expanded(
              child: Consumer<ServiceProvider>(
                builder: (context, serviceProvider, child) {
                  if (serviceProvider.isLoading) {
                    return const SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: SkeletonGrid(
                        itemCount: 6,
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Column(
                          children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _pricingData.length,
                          itemBuilder: (context, index) {
                            return _buildPricingCard(_pricingData[index]);
                          },
                        ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget._showBottomNav
          ? BottomNavigation(
              selectedIndex: 1,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.of(context).pushReplacementNamed('/home');
                    break;
                  case 1:
                    break;
                  case 2:
                    Navigator.of(context)
                        .pushReplacementNamed('/prepaid_packs');
                    break;
                  case 3:
                    Navigator.of(context).pushReplacementNamed('/more');
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> item) {
    final tags = (item['tags'] as List<String>?) ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            settings: const RouteSettings(name: '/service_overview'),
            pageBuilder: (context, animation, secondaryAnimation) =>
                ServiceOverviewScreen(serviceType: item['title']),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBlueDark, // ← Consistent Blue card background
          borderRadius: BorderRadius.zero,  // ← Square shape kept
          border: Border.all(
            color: const Color(0xFFFFD600), // ← Yellow border
            width: 2.0,                     // ← Bold yellow border
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Body ──────────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildServiceIcon(item),

                      const SizedBox(height: 6),

                      // Title — white
                      Text(
                        item['title'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white, // ← White
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // Description — white 72% opacity
                      if (item['description'] != null &&
                          item['description'].toString().isNotEmpty)
                        Text(
                          item['description'],
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: Colors.white.withOpacity(0.72), // ← White
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 6),

                      // Tags — yellow
                      if (tags.isNotEmpty)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 3,
                          runSpacing: 3,
                          children: tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD600).withOpacity(0.10), // ← yellow tint bg
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFFFFD600).withOpacity(0.7), // ← yellow border
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFD600), // ← Yellow text
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Price footer ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25), // ← dark footer for contrast
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['priceLabel'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.55), // ← White muted
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (item['unit'] == null || item['unit'] == 'item')
                        Text(
                          'from ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.60), // ← White muted
                          ),
                        ),
                      Text(
                        '£${item['price']}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFD600), // ← Yellow price
                        ),
                      ),
                      if (item['unit'] != null && item['unit'] != 'item')
                        Text(
                          ' / ${item['unit']}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.50), // ← White muted
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(Map<String, dynamic> item) {
    final imageUrl = item['imageUrl'] ?? '';
    final iconPath = item['iconPath'];
    final color = item['color'] as Color?;

    if (imageUrl.isNotEmpty && imageUrl.startsWith('data:image/')) {
      try {
        return ClipOval(
          child: Image.memory(
            _base64ToImage(imageUrl),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackCircle(color),
          ),
        );
      } catch (_) {
        return _fallbackCircle(color);
      }
    }

    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackCircle(color),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _fallbackCircle(color, loading: true),
        ),
      );
    }

    if (iconPath != null) {
      return ClipOval(
        child: Image.asset(
          iconPath,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackCircle(color),
        ),
      );
    }

    return _fallbackCircle(color);
  }

  Widget _fallbackCircle(Color? color, {bool loading = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.18), // ← semi-transparent white circle
        border: Border.all(
          color: const Color(0xFFFFD600).withOpacity(0.5), // ← yellow ring
          width: 1.5,
        ),
      ),
      child: loading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          : const Icon(Icons.local_laundry_service,
              color: Colors.white, size: 26),
    );
  }

  Uint8List _base64ToImage(String base64String) {
    final base64Data = base64String.split(',')[1];
    return base64Decode(base64Data);
  }

  List<String> _getFirstItems(List<dynamic> items, int count) {
    return items
        .take(count)
        .map((item) => item['name']?.toString() ?? '')
        .toList();
  }
}