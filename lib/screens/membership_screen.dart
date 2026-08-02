import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'terms_conditions_screen.dart';
import '../widgets/app_logo.dart';
import '../config/theme.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  // 0 = Monthly, 1 = Annual
  int _selectedPlan = 1;

  Future<void> _callToSubscribe() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+447424866802');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: Text(
          'Membership',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: AppColors.primaryBlueDark,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.white, size: 15),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.gold.withOpacity(0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────
            _buildHero(),

            // ── Body ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Benefits
                  _SectionLabel(label: 'Premium Benefits'),
                  const SizedBox(height: 12),
                  _buildBenefit(Icons.payments_outlined, 'Zero Service Fees',
                      'Skip the service fee on every single order you place.'),
                  _buildBenefit(Icons.bolt_rounded, 'Priority Processing',
                      'Your garments get priority at our cleaning facilities.'),
                  _buildBenefit(Icons.stars_rounded, 'Exclusive Offers',
                      'Early access to seasonal discounts and new services.'),
                  _buildBenefit(Icons.support_agent_rounded, 'VIP Support',
                      'Direct access to our senior support team for any queries.'),

                  const SizedBox(height: 24),

                  // Plans
                  _SectionLabel(label: 'Choose Your Plan'),
                  const SizedBox(height: 12),
                  _buildPlanSelector(),

                  const SizedBox(height: 10),

                  // Cancel note
                  Center(
                    child: Text(
                      'Cancel anytime  ·  No commitment  ·  Instant activation',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── CTA Button ───────────────────────────────────
                  _buildCTAButton(),

                  const SizedBox(height: 12),

                  // Phone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_in_talk_outlined,
                          size: 13,
                          color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        '+44 7424 866802',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Terms
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
                        );
                      },
                      child: Text(
                        'Terms & Conditions apply',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white,
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

  // ── Hero Section ───────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
      color: AppColors.primaryBlueDark,
      child: Column(
        children: [
          // Gold star icon
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.1),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.gold,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          AppLogo(
            fontSize: 28,
            mainColor: const Color(0xFF042407), // Dark Green
            secondaryColor: Colors.red,
          ),
          const SizedBox(height: 6),
          Text(
            'ELEVATE YOUR LAUNDRY EXPERIENCE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Benefit Row ────────────────────────────────────────────────────────────
  Widget _buildBenefit(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Plan Selector ──────────────────────────────────────────────────────────
  Widget _buildPlanSelector() {
    return Row(
      children: [
        // Monthly
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = 0),
            child: _PlanCard(
              period: 'MONTHLY',
              price: '£3.99',
              perUnit: '/mo',
              note: 'Billed monthly',
              noteColor: AppColors.white,
              isSelected: _selectedPlan == 0,
              badge: null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Annual
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = 1),
            child: _PlanCard(
              period: 'ANNUAL',
              price: '£2.99',
              perUnit: '/mo',
              note: 'Save 25% · £35.88/yr',
              noteColor: AppColors.gold,
              isSelected: _selectedPlan == 1,
              badge: 'BEST VALUE',
            ),
          ),
        ),
      ],
    );
  }

  // ── CTA Button ─────────────────────────────────────────────────────────────
  Widget _buildCTAButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _callToSubscribe,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.primaryBlueDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_rounded, size: 18),
            const SizedBox(width: 10),
            Text(
              'CALL TO SUBSCRIBE',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlueDark,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label Widget ───────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Plan Card Widget ───────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String period;
  final String price;
  final String perUnit;
  final String note;
  final Color noteColor;
  final bool isSelected;
  final String? badge;

  const _PlanCard({
    required this.period,
    required this.price,
    required this.perUnit,
    required this.note,
    required this.noteColor,
    required this.isSelected,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.gold.withOpacity(0.07)
            : AppColors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.gold
              : AppColors.white.withOpacity(0.1),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period label
              Text(
                period,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white.withOpacity(0.45),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    perUnit,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Note
              Text(
                note,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: noteColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          // Badge
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlueDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}