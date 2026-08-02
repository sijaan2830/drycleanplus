import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../widgets/bottom_navigation.dart';
import '../providers/service_provider.dart';
import 'service_overview_screen.dart';
import '../utils/responsive_helper.dart';
import '../widgets/app_logo.dart';
import '../widgets/sparkling_overlay.dart';

class HomeScreen extends StatefulWidget {
  final bool? showBottomNav;

  const HomeScreen({super.key, this.showBottomNav});

  bool get _showBottomNav => showBottomNav ?? true;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? fullName = prefs.getString('user_displayName');

    if (fullName != null && fullName.isNotEmpty) {
      List<String> nameParts = fullName.trim().split(' ');
      setState(() {
        _userName = nameParts.first;
      });
    } else {
      setState(() {
        _userName = 'Guest';
      });
    }
  }

  // ── _buildInfoItem ──────────────────────────────────────────────────────
  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
              // ── Top Header Section ──
              Padding(
                padding: const EdgeInsets.only(
                    left: 24, right: 16, top: 12, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi,',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          _userName,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Schedule your first order.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed('/faq');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Help',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Driver Image Section with Info Card ──
              LayoutBuilder(
                builder: (context, constraints) {
                  // Scale down only on very small screens, otherwise use original values
                  final screenH = R.screenHeight(context);
                  final isSmall = screenH < 700;
                  final sectionH = isSmall ? 280.0 : 340.0;
                  final imageW = isSmall ? 270.0 : 310.0;
                  final imageH = isSmall ? 255.0 : 295.0;
                  final cardTop = isSmall ? 155.0 : 185.0;
                  final cardW = isSmall ? 165.0 : 190.0;

                  return Container(
                    height: sectionH,
                    margin: const EdgeInsets.only(left: 0, right: 24),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -30,
                          top: 0,
                          child: SizedBox(
                            width: imageW,
                            height: imageH,
                            child: Image.asset(
                              'assets/images/Drycleanplus.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF0066FF),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.local_laundry_service,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Image not found',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          right: 5,
                          top: cardTop,
                          child: Container(
                            width: cardW,
                            padding: EdgeInsets.all(isSmall ? 11 : 14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.gold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildInfoItem(Icons.flash_on,
                                    'Fast & Express Service', AppColors.white),
                                _buildInfoItem(Icons.eco, 'Eco-Friendly Cleaning',
                                    AppColors.white),
                                _buildInfoItem(Icons.verified,
                                    'Quality Guaranteed', AppColors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Getting Started Card ──
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/faq'),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Getting started?',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'See how Drycleanplus works and learn more about our services.',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.white.withOpacity(0.85),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // ── "Start now" — white button with highlight ──
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Start now',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlueDark,
                                  // No underline
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const ShapeDecoration(
                          color: AppColors.white,
                          shape: DCOrganicBorder(),
                          shadows: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.primaryBlueDark,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Prepaid Discount Card ──
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/prepaid'),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(18, 28, 14, 28),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Premium Care, Preferred Rates',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Save on every order with our professional prepaid credit plans.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/prepaid'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 11),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gold.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Save now',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    // ── White text, no underline ──
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 108,
                        height: 108,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(108, 108),
                              painter: PremiumBadgePainter(
                                color: AppColors.gold,
                              ),
                            ),
                            Container(
                              width: 94,
                              height: 94,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 78,
                              height: 78,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'up to',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBlueDark,
                                    ),
                                  ),
                                  Text(
                                    '20%',
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryBlueDark,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'off',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBlueDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── DrycleanPlus+ Joining Card ──
              SparklingOverlay(
                borderRadius: 16,
                sparkleCount: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/membership'),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppLogo(
                                fontSize: 25,
                                mainColor: Color(0xFF042407), // Extra Dark Green
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Skip the service fee for just\n£3.99 / month',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: AppColors.white.withOpacity(0.85),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // ── "Join now" — white, no underline ──
                              Text(
                                'Join now',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                  // No decoration
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.gold.withOpacity(0.4),
                                      AppColors.gold.withOpacity(0.0),
                                    ],
                                    stops: const [0.3, 1.0],
                                  ),
                                ),
                              ),
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.gold,
                                      Color(0xFFB8860B),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(3, 5),
                                    ),
                                    const BoxShadow(
                                      color: Colors.white30,
                                      blurRadius: 3,
                                      offset: Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_laundry_service_rounded,
                                  color: AppColors.primaryBlueDark,
                                  size: 34,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white54,
                                      blurRadius: 2,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlueDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.gold, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add,
                                        color: AppColors.white, size: 18),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                left: 2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                      colors: [
                                        AppColors.gold,
                                        Color(0xFFB8860B),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.primaryBlueDark,
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(1, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add,
                                        color: AppColors.primaryBlueDark,
                                        size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: R.adaptive(context, small: 16, normal: 28)),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

// ── PremiumBadgePainter ────────────────────────────────────────────────────
class PremiumBadgePainter extends CustomPainter {
  final Color color;

  PremiumBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.88;
    const points = 32;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── DCOrganicBorder ────────────────────────────────────────────────────────
class DCOrganicBorder extends ShapeBorder {
  const DCOrganicBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.elliptical(rect.width * 0.3, rect.height * 0.3),
        topRight: Radius.elliptical(rect.width * 0.7, rect.height * 0.3),
        bottomRight: Radius.elliptical(rect.width * 0.7, rect.height * 0.7),
        bottomLeft: Radius.elliptical(rect.width * 0.3, rect.height * 0.7),
      ));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => const DCOrganicBorder();
}