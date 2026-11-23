import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/service_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/app_ui.dart';
import '../widgets/service_price_card.dart';
import '../widgets/skeleton_loading.dart';
import 'service_overview_screen.dart';

class PricesScreen extends StatefulWidget {
  final bool? showBottomNav;

  const PricesScreen({super.key, this.showBottomNav});

  bool get _showBottomNav => showBottomNav ?? true;

  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ServiceProvider>(context, listen: false).initializeServicesListener();
    });
  }

  void _openService(Map<String, dynamic> item) {
    final title = (item['title'] ?? item['name'] ?? '').toString();
    try {
      Provider.of<BookingProvider>(context, listen: false).setSelectedService(title);
    } catch (_) {}
    Navigator.of(context).push(
      smoothRoute(
        ServiceOverviewScreen(serviceType: title),
        name: '/service_overview',
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
              // Ambient soft background discs (HTML .wrap::before, .wrap::after)
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

                    // Identify Featured Service (Dry Clean) and partition the rest
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

                    // Fallback featured if not found
                    featured ??= {
                      'title': 'Dry Clean',
                      'description': 'Expert dry cleaning for delicate fabrics and formal wear.',
                      'tags': ['Dry cleaning', 'Ironing'],
                      'price': '1.45',
                      'priceLabel': 'From · per item',
                    };

                    // Partition remaining services into 2 columns
                    final List<Map<String, dynamic>> col1 = [];
                    final List<Map<String, dynamic>> col2 = [];

                    for (int i = 0; i < otherServices.length; i++) {
                      final s = otherServices[i];
                      final t = (s['title'] ?? '').toString().toLowerCase();
                      // Duvets and Laundry in Col 1; Household and Wash in Col 2 (per HTML layout)
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
                      padding: EdgeInsets.fromLTRB(16, 12, 16, widget._showBottomNav ? 110 : 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),

                          // Featured Card (Dry Clean)
                          FeaturedPriceCard(
                            item: featured,
                            onTap: () => _openService(featured!),
                          ),
                          const SizedBox(height: 32),

                          // Staggered 2-Column Grid (HTML .cols, .col, .col.off)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Column 1
                              Expanded(
                                child: Column(
                                  children: [
                                    for (int i = 0; i < col1.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 38),
                                      StaggeredPriceCard(
                                        item: col1[i],
                                        onTap: () => _openService(col1[i]),
                                        index: i * 2,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Column 2 (HTML .col.off { margin-top: 34px; })
                              Expanded(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 34),
                                    for (int i = 0; i < col2.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 38),
                                      StaggeredPriceCard(
                                        item: col2[i],
                                        onTap: () => _openService(col2[i]),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                'Prices',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.6,
                  height: 1.0,
                ),
              ),
              Positioned(
                left: 0,
                bottom: -11,
                width: 136,
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
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              'Clear prices for every service. Tap one to see what it costs.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE8F0FF),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
