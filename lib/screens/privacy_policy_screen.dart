import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Privacy Policy Screen matching Privacy_Policy.html mockup.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = [];
  double _scrollProgress = 0.0;

  static const List<_LegalSectionData> _sections = [
    _LegalSectionData(
      title: 'Introduction',
      colorA: Color(0xFF1553D6),
      colorB: Color(0xFF4F95FF),
      tint: Color(0xFFE1ECFF),
      paragraphs: [
        'DrycleanPlus (“we”, “our”, or “us”) is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
        'Please read this privacy policy carefully. By using our services, you consent to the practices described in this policy.',
      ],
      bulletGroups: [],
    ),
    _LegalSectionData(
      title: 'Information We Collect',
      colorA: Color(0xFF4338CA),
      colorB: Color(0xFF8B5CF6),
      tint: Color(0xFFE9E2FF),
      paragraphs: [
        'We collect information that you provide directly to us and information that is collected automatically when you use our services.',
      ],
      bulletGroups: [
        _BulletGroup(
          label: 'Personal Information:',
          items: [
            'Name and contact details (email, phone number)',
            'Delivery and collection addresses',
            'Payment information (processed securely via third-party providers)',
            'Account credentials',
            'Communication preferences',
          ],
        ),
        _BulletGroup(
          label: 'Automatically Collected Information:',
          items: [
            'Device information (type, operating system, unique identifiers)',
            'Location data (for collection and delivery services)',
            'Usage data (app interactions, features used)',
            'Log data (access times, pages viewed, referring URL)',
          ],
        ),
      ],
    ),
    _LegalSectionData(
      title: 'How We Use Your Information',
      colorA: Color(0xFF0B8F7A),
      colorB: Color(0xFF34D9AE),
      tint: Color(0xFFD9F6EC),
      paragraphs: [],
      bulletGroups: [
        _BulletGroup(
          label: 'We use the information we collect for various purposes, including:',
          items: [
            'To provide and maintain our services',
            'To process your orders and payments',
            'To arrange collection and delivery of your items',
            'To send promotional materials (with your consent)',
            'To improve our services and develop new features',
            'To detect and prevent fraud',
            'To comply with legal obligations',
            'To resolve disputes and enforce our agreements',
          ],
        ),
      ],
    ),
    _LegalSectionData(
      title: 'Legal Basis for Processing',
      colorA: Color(0xFFF26B00),
      colorB: Color(0xFFFFC53D),
      tint: Color(0xFFFFEBB8),
      paragraphs: [],
      bulletGroups: [
        _BulletGroup(
          label: 'We process your personal data under the following legal bases:',
          items: [
            'Contract: To fulfill our service agreement with you',
            'Consent: For marketing communications and certain data uses',
            'Legitimate Interest: To improve our services and prevent fraud',
            'Legal Obligation: To comply with applicable laws and regulations',
            'Vital Interests: To protect the safety of individuals',
          ],
        ),
      ],
    ),
    _LegalSectionData(
      title: 'Contact Us & Company Address',
      colorA: Color(0xFF1553D6),
      colorB: Color(0xFF4F95FF),
      tint: Color(0xFFE1ECFF),
      paragraphs: [
        'If you have any questions about this Privacy Policy or how we handle your data, please contact us:',
      ],
      bulletGroups: [
        _BulletGroup(
          label: 'DryClean Plus Ltd',
          items: [
            'Address: 2c Bar Gate, Newark NG24 1ES, United Kingdom',
            'Email: dilee@drycleanplus.co.uk',
            'Phone: +44 7424 866802',
          ],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _sections.length; i++) {
      _sectionKeys.add(GlobalKey());
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (max > 0) {
      setState(() {
        _scrollProgress = (current / max).clamp(0.0, 1.0);
      });
    }
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1245B5),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3282F8),
              Color(0xFF1C61E4),
              Color(0xFF1245B5),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow circles
            Positioned(
              right: -140,
              top: -120,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -200,
              top: 500,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Sticky Header with Progress Bar
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'Privacy Policy',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 38),
                          ],
                        ),
                      ),
                      // Top Gold Reading Progress Bar
                      Positioned(
                        left: 0,
                        bottom: 0,
                        height: 3,
                        width: MediaQuery.of(context).size.width * _scrollProgress,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD25E),
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Horizontal Section Jump Chips
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _sections.length,
                        itemBuilder: (ctx, i) {
                          final sec = _sections[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _scrollToSection(i),
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.26),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0B1F5B),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sec.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Main Scrollable Legal Content Cards
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: List.generate(_sections.length, (i) {
                              final sec = _sections[i];
                              return Padding(
                                key: _sectionKeys[i],
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSectionCard(sec, i + 1),
                              );
                            }),
                          ),
                        ),
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

  Widget _buildSectionCard(_LegalSectionData sec, int number) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background soft pastel circle
          Positioned(
            right: -46,
            top: -56,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sec.tint,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [sec.colorA, sec.colorB],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: sec.colorA.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sec.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1F5B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1.5, color: Color(0xFFE8EEFC)),
                const SizedBox(height: 10),

                // Paragraphs
                for (final p in sec.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      p,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF34457D),
                        height: 1.6,
                      ),
                    ),
                  ),

                // Bullet groups
                for (final bg in sec.bulletGroups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(
                      bg.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                      ),
                    ),
                  ),
                  for (final item in bg.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6, right: 10, left: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [sec.colorA, sec.colorB],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildRichBulletText(item),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichBulletText(String text) {
    if (text.contains(':')) {
      final parts = text.split(':');
      final prefix = parts[0];
      final rest = parts.sublist(1).join(':');

      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$prefix:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0B1F5B),
              ),
            ),
            TextSpan(
              text: rest,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF34457D),
                height: 1.55,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF34457D),
        height: 1.55,
      ),
    );
  }
}

class _LegalSectionData {
  final String title;
  final Color colorA;
  final Color colorB;
  final Color tint;
  final List<String> paragraphs;
  final List<_BulletGroup> bulletGroups;

  const _LegalSectionData({
    required this.title,
    required this.colorA,
    required this.colorB,
    required this.tint,
    required this.paragraphs,
    required this.bulletGroups,
  });
}

class _BulletGroup {
  final String label;
  final List<String> items;

  const _BulletGroup({required this.label, required this.items});
}
