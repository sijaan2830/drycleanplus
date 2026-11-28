import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_ui.dart';
import '../widgets/live_order_banner.dart';
import '../widgets/loyalty_mini_card.dart';
import '../widgets/sparkling_overlay.dart';
import '../widgets/dryclean_washing_machine.dart';
import 'service_overview_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool? showBottomNav;

  const HomeScreen({super.key, this.showBottomNav});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('user_displayName');
    if (!mounted) return;
    setState(() {
      _userName = (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim().split(' ').first
          : 'Guest';
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.42, 1.0],
              colors: [
                Color(0xFF2E7EF7),
                Color(0xFF1C61E4),
                Color(0xFF1245B5),
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Ambient Soft Light Circles from Home.html ──
              Positioned(
                right: -130,
                top: -120,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -150,
                top: 440,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // ── Main Scrollable Content ──
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),

                            // ── Top Header Section (.top in Home.html) ──
                            _buildHeader(context),

                            const SizedBox(height: 20),

                            // ── Live order: driver on the way / approval needed ──
                            const LiveOrderBanner(),

                            // ── Live Digital Loyalty Card progress ──
                            const LoyaltyMiniCard(),

                            // ── Doorstep Delivery Hero Banner with Branded Model ──
                            _buildShopBanner(context),

                            const SizedBox(height: 14),

                            // ── Card 1: Getting Started? (.c1) ──
                            _buildCard1GettingStarted(context),

                            const SizedBox(height: 14),

                            // ── Card 2: Premium Care, Preferred Rates (.c2) ──
                            _buildCard2PremiumCare(context),

                            const SizedBox(height: 14),

                            // ── Card 3: DrycleanPlus+ Membership with New Animated Washing Machine ──
                            _buildCard3Membership(context),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: Greeting, User Name, Help Pill & Glass Bell ─────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Greeting, Name, Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 29,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Schedule your first order.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE6EFFF),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Right Actions: Help Gold Pill + Circular Bell Button
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Help Yellow Pill Button (.help)
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/faq'),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC20E),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Help',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1F5B),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 9),

            // Notification Bell Glass Circle (.bell) with live unread dot
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                smoothRoute(const NotificationScreen(), name: '/notifications'),
              ),
              child: Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: Builder(
                  builder: (context) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) {
                      return const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 21);
                    }
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('notifications')
                          .where('read', isEqualTo: false)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snap) {
                        final hasUnread = (snap.data?.docs.isNotEmpty ?? false);
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                            if (hasUnread)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFC20E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Doorstep Delivery Visual Hero Banner ────────────────────────────────────
  Widget _buildShopBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          smoothRoute(
            const ServiceOverviewScreen(serviceType: 'Dry Clean'),
            name: '/service_overview',
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF09235E),
              Color(0xFF0E3894),
              Color(0xFF154DB8),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF02104C).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle ambient glow circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD25E).withOpacity(0.06),
                  ),
                ),
              ),

              // Content: Left text & CTA and Right official model
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Text & Badges & CTA
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Gold Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF08A).withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFFD25E).withOpacity(0.85),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFFFD25E)),
                                    const SizedBox(width: 3),
                                    Text(
                                      '24H EXPRESS SERVICE',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFFD25E),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                    letterSpacing: -0.4,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Fresh Clothes,\n',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    TextSpan(
                                      text: 'To Your Door.',
                                      style: TextStyle(color: Color(0xFFFFD25E)),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                'Free collection & delivery in London & Midlands',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFBAE6FD),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),

                          // CTA Book Now pill button
                          Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC20E),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Book now',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0B1F5B),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: Color(0xFF0B1F5B),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right Graphic: The official smiling DrycleanPlus model
                    SizedBox(
                      width: 128,
                      height: double.infinity,
                      child: Image.asset(
                        'assets/images/hero_brand.webp',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/Drycleanplus.png',
                          fit: BoxFit.contain,
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
    );
  }

  // ── Card 1: Getting Started? (.c1) ──────────────────────────────────────────
  Widget _buildCard1GettingStarted(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            smoothRoute(
              const ServiceOverviewScreen(serviceType: 'Dry Clean'),
              name: '/service_overview',
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 19),
          decoration: BoxDecoration(
            color: const Color(0xFF1245B5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF5B82E), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Getting started?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'See how Drycleanplus works and learn more about our services.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFE8F0FF),
                        height: 1.36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // White Button (.btn)
                    Container(
                      height: 39,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Start now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1553D6),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right Graphic: White Shape (DCOrganicBorder) from Old Card Code
              Container(
                width: 56,
                height: 56,
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: DCOrganicBorder(),
                  shadows: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF1245B5),
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ── Card 2: Premium Care, Preferred Rates (.c2) ─────────────────────────────
  Widget _buildCard2PremiumCare(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/prepaid'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4527B8), Color(0xFF6B46F2)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF5B82E), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Premium Care,\nPreferred Rates',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save on every order with our professional prepaid credit plans.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE8F0FF),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Save Now Yellow Pill Button
                  Container(
                    height: 39,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC20E),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Save now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right Graphic: 48-Point Sunburst Medallion (.badge)
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(110, 110),
                    painter: _SunburstMedallionPainter(),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'up to',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1F5B),
                          height: 1.05,
                        ),
                      ),
                      Text(
                        '20%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1553D6),
                          letterSpacing: -1.0,
                          height: 1.05,
                        ),
                      ),
                      Text(
                        'off',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1F5B),
                          height: 1.05,
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

  // ── Card 3: DrycleanPlus+ Membership Card with New Washing Machine ──────────
  Widget _buildCard3Membership(BuildContext context) {
    return SparklingOverlay(
      borderRadius: 24,
      sparkleCount: 12,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/membership'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1245B5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content (Previous Structure preserved as requested)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(
                      fontSize: 25,
                      mainColor: Color(0xFF042407),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Skip the service fee for just\n£3.99 / month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Join now White Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 9.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Join now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F5BC4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right Graphic: NEW Washing Machine from Home.html!
              const DrycleanWashingMachineGraphic(
                width: 120,
                height: 136,
              ),
            ],
          ),
        ),
      ),
    );
  }
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

// ── Sunburst Medallion Painter (.badge in Home.html) ──────────────────────────
class _SunburstMedallionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const points = 48; // 48-pointed sunburst from Home.html
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * (46.0 / 55.0);

    final path = Path();
    for (int i = 0; i < points; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi) / (points / 2) - (math.pi / 2);
      final pt = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    // Drop shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.28), 6, false);

    // Sunburst gold polygon fill (#F5B82E)
    final goldPaint = Paint()
      ..color = const Color(0xFFF5B82E)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, goldPaint);

    // Middle circle: r=43, fill #FAC82C, stroke #E2A117 1.5px
    final midRadius = outerRadius * (43.0 / 56.0);
    final midPaint = Paint()
      ..color = const Color(0xFFFAC82C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, midRadius, midPaint);

    final midStroke = Paint()
      ..color = const Color(0xFFE2A117)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, midRadius, midStroke);

    // Inner circle: r=39, fill #FFFFFF
    final innerCircleRadius = outerRadius * (39.0 / 56.0);
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerCircleRadius, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
