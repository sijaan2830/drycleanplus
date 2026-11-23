import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/service_provider.dart';
import '../widgets/app_ui.dart';
import '../widgets/dryclean_loader.dart';
import '../widgets/service_price_card.dart';
import '../widgets/skeleton_loading.dart';
import 'guest_service_overview_screen.dart';
import 'onboarding_screen.dart';

class GuestPriceScreen extends StatefulWidget {
  const GuestPriceScreen({super.key});

  @override
  State<GuestPriceScreen> createState() => _GuestPriceScreenState();
}

class _GuestPriceScreenState extends State<GuestPriceScreen> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ServiceProvider>(context, listen: false).initializeServicesListener();
    });
  }

  Future<void> _createAccount() async {
    if (_navigating) return;
    _navigating = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DrycleanLoader(autoDismiss: false),
    );
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(smoothRoute(const OnboardingScreen()));
    _navigating = false;
  }

  void _openGuestService(Map<String, dynamic> item) {
    Navigator.of(context).push(
      smoothRoute(
        GuestServiceOverviewScreen(serviceType: item['title']),
        name: '/guest_service_overview',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryBlueDark,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: Stack(
            children: [
              Positioned(
                top: -140,
                right: -150,
                width: 360,
                height: 360,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                top: 640,
                left: -230,
                width: 420,
                height: 420,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Consumer<ServiceProvider>(
                  builder: (context, serviceProvider, _) {
                    final services = serviceProvider.servicesAsMap;

                    if (serviceProvider.isLoading) {
                      return _buildSkeleton();
                    }

                    Map<String, dynamic>? featured;
                    final List<Map<String, dynamic>> otherServices = [];

                    for (final s in services) {
                      final t = (s['title'] ?? '').toString().toLowerCase();
                      if (featured == null && t.contains('dry clean')) {
                        featured = s;
                      } else {
                        otherServices.add(s);
                      }
                    }

                    featured ??= {
                      'title': 'Dry Clean',
                      'description': 'Expert dry cleaning for delicate fabrics and formal wear.',
                      'tags': ['Dry cleaning', 'Ironing'],
                      'price': '1.45',
                      'priceLabel': 'From · per item',
                    };

                    final List<Map<String, dynamic>> col1 = [];
                    final List<Map<String, dynamic>> col2 = [];

                    for (int i = 0; i < otherServices.length; i++) {
                      final s = otherServices[i];
                      final t = (s['title'] ?? '').toString().toLowerCase();
                      if (t.contains('duvet') || t.contains('bedding') || t.contains('laundry')) {
                        col1.add(s);
                      } else if (t.contains('household') || t.contains('wash')) {
                        col2.add(s);
                      } else {
                        if (col1.length <= col2.length) {
                          col1.add(s);
                        } else {
                          col2.add(s);
                        }
                      }
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),

                          // Guest sign-in banner
                          _buildGuestPromptBanner(),
                          const SizedBox(height: 8),

                          FeaturedPriceCard(
                            item: featured,
                            onTap: () => _openGuestService(featured!),
                          ),
                          const SizedBox(height: 32),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    for (int i = 0; i < col1.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 38),
                                      StaggeredPriceCard(
                                        item: col1[i],
                                        onTap: () => _openGuestService(col1[i]),
                                        index: i * 2,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 34),
                                    for (int i = 0; i < col2.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 38),
                                      StaggeredPriceCard(
                                        item: col2[i],
                                        onTap: () => _openGuestService(col2[i]),
                                        index: i * 2 + 1,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestPromptBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFFFFD25E), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browsing as Guest',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Sign in anytime to place orders & track delivery.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _createAccount,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC20E),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0B1F5B),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              'Prices',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.4,
                height: 1.0,
              ),
            ),
            Positioned(
              left: 0,
              bottom: -11,
              width: 130,
              height: 12,
              child: const CustomPaint(
                painter: SquigglyUnderlinePainter(
                  color: Color(0xFFFFD25E),
                  strokeWidth: 4.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            'Clear prices for every service. Browse our rates as a guest.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE8F0FF),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          const SkeletonLoading(
            height: 230,
            borderRadius: 32,
          ),
          const SizedBox(height: 32),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    SkeletonLoading(height: 220, borderRadius: 28),
                    SizedBox(height: 38),
                    SkeletonLoading(height: 220, borderRadius: 28),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 34),
                    SkeletonLoading(height: 220, borderRadius: 28),
                    SizedBox(height: 38),
                    SkeletonLoading(height: 220, borderRadius: 28),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
