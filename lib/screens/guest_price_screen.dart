import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/service_provider.dart';
import '../widgets/dryclean_loader.dart';
import '../widgets/skeleton_loading.dart';
import 'onboarding_screen.dart';
import 'guest_service_overview_screen.dart';

class GuestPriceScreen extends StatefulWidget {
  const GuestPriceScreen({super.key});

  @override
  State<GuestPriceScreen> createState() => _GuestPriceScreenState();
}

class _GuestPriceScreenState extends State<GuestPriceScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize services listener for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceProvider>(context, listen: false).initializeServicesListener();
    });
  }

  // Get real-time services from ServiceProvider
  List<Map<String, dynamic>> get _pricingData {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    return serviceProvider.servicesAsMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: Text(
          'Prices',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/onboarding',
              (Route<dynamic> route) => false,
            );
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            // Grid Content Area
            Expanded(
              child: Consumer<ServiceProvider>(
                builder: (context, serviceProvider, child) {
                  if (serviceProvider.isLoading) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SkeletonGrid(itemCount: 6, crossAxisCount: 2, childAspectRatio: 0.75),
                        ],
                      ),
                    );
                  }
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Column(
                          children: [
                        // Grid for Cards
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
                        
                        const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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

  Widget _buildPricingCard(Map<String, dynamic> item) {
    final tags = (item['tags'] as List<String>?) ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            settings: const RouteSettings(name: '/guest_service_overview'),
            pageBuilder: (context, animation, secondaryAnimation) =>
                GuestServiceOverviewScreen(serviceType: item['title']),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBlueDark,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: const Color(0xFFFFD600),
            width: 2.0,
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
            // Body
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
                      Text(
                        item['title'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (item['description'] != null &&
                          item['description'].toString().isNotEmpty)
                        Text(
                          item['description'],
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: Colors.white.withOpacity(0.72),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
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
                                color: const Color(0xFFFFD600).withOpacity(0.10),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFFFFD600).withOpacity(0.7),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFD600),
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
            // Price footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['priceLabel'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.55),
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
                            color: Colors.white.withOpacity(0.60),
                          ),
                        ),
                      Text(
                        '£${item['price']}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFD600),
                        ),
                      ),
                      if (item['unit'] != null && item['unit'] != 'item')
                        Text(
                          ' / ${item['unit']}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.50),
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
    print('=== DEBUG Guest Price Service Icon: ${item['title']} ===');
    final imageUrl = item['imageUrl'] ?? '';
    final iconPath = item['iconPath'];
    
    // Check if we have a base64 image from Firestore
    if (imageUrl.isNotEmpty && imageUrl.startsWith('data:image/')) {
        try {
            return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                    _base64ToImage(imageUrl),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                ),
            );
        } catch (e) {
            return _buildFallbackIcon();
        }
    }

    if (iconPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          iconPath,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
        ),
      );
    }
    
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
      ),
      child: const Icon(
        Icons.local_laundry_service,
        color: AppColors.gold,
        size: 22,
      ),
    );
  }

  Uint8List _base64ToImage(String base64String) {
    final base64Data = base64String.split(',')[1];
    return base64Decode(base64Data);
  }
}
