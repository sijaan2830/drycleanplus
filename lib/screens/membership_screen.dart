import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_ui.dart';

/// Premium interactive DrycleanPlus+ VIP Membership Screen
class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> with SingleTickerProviderStateMixin {
  // Plan: 'a' for Annual, 'm' for Monthly
  String _selectedPlan = 'a';
  double _ordersPerMonth = 3.0;

  // Track expanded FAQs
  final Set<int> _expandedFaqs = {0};

  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _callToSubscribe() async {
    HapticFeedback.lightImpact();
    final Uri phoneUri = Uri(scheme: 'tel', path: '+447424866802');
    try {
      if (!await launchUrl(phoneUri) && mounted) {
        showAppSnack(context, 'Could not open phone. Call +44 7424 866802', error: true);
      }
    } catch (_) {
      if (mounted) showAppSnack(context, 'Could not open phone. Call +44 7424 866802', error: true);
    }
  }

  Future<void> _openWhatsApp() async {
    HapticFeedback.lightImpact();
    final Uri waUri = Uri.parse('https://wa.me/447424866802?text=Hello%20DrycleanPlus!%20I%20would%20like%20to%20subscribe%20to%20the%20${_selectedPlan == "a" ? "Annual" : "Monthly"}%20DrycleanPlus%2B%20Membership.');
    try {
      if (!await launchUrl(waUri, mode: LaunchMode.externalApplication) && mounted) {
        showAppSnack(context, 'Could not open WhatsApp. Call +44 7424 866802', error: true);
      }
    } catch (_) {
      if (mounted) showAppSnack(context, 'Could not open WhatsApp. Call +44 7424 866802', error: true);
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/more');
    }
  }

  double get _planCost => _selectedPlan == 'a' ? 35.88 : 47.88;
  double get _feesSaved => _ordersPerMonth * 12 * 2.99;
  double get _netSavings => (_feesSaved - _planCost).clamp(0.0, 9999.0);

  @override
  Widget build(BuildContext context) {
    final isAnnual = _selectedPlan == 'a';
    final captionText = isAnnual
        ? 'Annual Plan · £2.99/mo (£35.88 billed yearly)'
        : 'Monthly Plan · £3.99/mo (cancel anytime)';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF103EB0),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF266FE6),
                Color(0xFF1652CF),
                Color(0xFF0D3AA7),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Subtle ambient glow circles
              Positioned(
                right: -140,
                top: -120,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -180,
                bottom: 120,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFC73A).withValues(alpha: 0.05),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Navigation Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _goBack,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD25E), size: 22),
                              const SizedBox(width: 6),
                              Text(
                                'DrycleanPlus+ VIP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 42),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Hero VIP Card
                                _buildHeroCard(),
                                const SizedBox(height: 16),

                                // Plan Selector (Interactive Monthly vs Annual)
                                _buildPlanSelector(),
                                const SizedBox(height: 16),

                                // Interactive Savings Calculator
                                _buildInteractiveCalculator(),
                                const SizedBox(height: 16),

                                // VIP Privileges (What You Get)
                                _buildPrivilegesSection(),
                                const SizedBox(height: 16),

                                // Side-by-Side Comparison (Member vs Standard)
                                _buildComparisonCard(),
                                const SizedBox(height: 16),

                                // Interactive FAQ Accordion
                                _buildFaqSection(),
                                const SizedBox(height: 24),

                                // In-Page Call to Subscribe CTA Card (scrolls with page, doesn't overlap footer)
                                _buildInPageCtaSection(captionText),
                                const SizedBox(height: 24),
                              ],
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. HERO VIP CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF091E5B),
            Color(0xFF13368E),
            Color(0xFF1B4ABF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFFD25E).withValues(alpha: 0.85),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Brand & VIP Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  children: const [
                    TextSpan(text: 'Dryclean'),
                    TextSpan(
                      text: 'Plus+',
                      style: TextStyle(color: Color(0xFFFFD25E)),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD25E),
                          const Color(0xFFFFAE19),
                          const Color(0xFFFFD25E),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        transform: GradientRotation(_shimmer.value * 6.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB400).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFF07194A)),
                        const SizedBox(width: 4),
                        Text(
                          'VIP PASS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF07194A),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Headline
          Text(
            'Skip the service fee.\nSave on every order.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Unlimited collections, priority booking slots, and 10% bonus credit on all prepaid packages.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFD2E1FF),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Highlighting stat chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFFFFF0B8), Color(0xFFFFC73A), Color(0xFFD69400)],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: Color(0xFF091E5B),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: 'Save '),
                        TextSpan(
                          text: '£2.99 fee',
                          style: TextStyle(
                            color: Color(0xFFFFD25E),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: ' automatically every single time!'),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. INTERACTIVE PLAN SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlanSelector() {
    return Row(
      children: [
        // Monthly Plan
        Expanded(
          child: _buildPlanOption(
            planKey: 'm',
            title: 'Monthly Plan',
            price: '£3.99',
            per: '/ month',
            billingText: 'Billed monthly · Cancel anytime',
            badge: null,
            isPopular: false,
          ),
        ),
        const SizedBox(width: 12),

        // Annual Plan
        Expanded(
          child: _buildPlanOption(
            planKey: 'a',
            title: 'Annual Plan',
            price: '£2.99',
            per: '/ month',
            billingText: '£35.88 billed annually',
            badge: 'SAVE £12/YR',
            isPopular: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required String planKey,
    required String title,
    required String price,
    required String per,
    required String billingText,
    String? badge,
    bool isPopular = false,
  }) {
    final isSelected = _selectedPlan == planKey;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPlan = planKey);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
              border: isSelected
                  ? Border.all(color: const Color(0xFFFFD25E), width: 3)
                  : Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? const Color(0xFF091E5B) : Colors.white,
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? const Color(0xFF1350D1) : Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? const Color(0xFF1350D1) : Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      per,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF5B6B9A) : const Color(0xFFD2E1FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  billingText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF6C7C99) : const Color(0xFFB4C8FA),
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              right: 12,
              top: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD25E), Color(0xFFFFAC1C)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF07194A),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. INTERACTIVE SAVINGS CALCULATOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInteractiveCalculator() {
    final int orders = _ordersPerMonth.round();
    final double net = _netSavings;
    final bool hasSaving = net > 0.05;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate_rounded, color: Color(0xFF1350D1), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Savings Calculator',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF091E5B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Drag the slider to see your yearly return',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5B6B9A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slider Controls Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orders per month:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C2B54),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1350D1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$orders ${orders > 1 ? "orders" : "order"} / mo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: const Color(0xFF1350D1),
              inactiveTrackColor: const Color(0xFFE2EBFB),
              thumbColor: const Color(0xFF1350D1),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 13,
                elevation: 3,
              ),
              overlayColor: const Color(0xFF1350D1).withValues(alpha: 0.16),
            ),
            child: Slider(
              value: _ordersPerMonth,
              min: 1.0,
              max: 8.0,
              divisions: 7,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _ordersPerMonth = val);
              },
            ),
          ),

          // Result Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasSaving
                    ? [const Color(0xFFE6F9F2), const Color(0xFFD4F4E7)]
                    : [const Color(0xFFF3F6FD), const Color(0xFFE8EEFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasSaving
                    ? const Color(0xFF12A38A).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasSaving ? 'Estimated Net Yearly Savings:' : 'At this order volume:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hasSaving ? const Color(0xFF086846) : const Color(0xFF2C4378),
                      ),
                    ),
                    if (hasSaving)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF086846),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'ROI POSITIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '£${net.toStringAsFixed(2)} / year',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: hasSaving ? const Color(0xFF086846) : const Color(0xFF091E5B),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasSaving
                      ? 'You avoid £${_feesSaved.toStringAsFixed(2)} in booking fees and pay only £${_planCost.toStringAsFixed(2)} for membership.'
                      : 'At 1 order/month you already break even and unlock all VIP priority benefits for free!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: hasSaving ? const Color(0xFF1E6C52) : const Color(0xFF5B6B9A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. VIP PRIVILEGES (WHAT YOU GET)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPrivilegesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DrycleanPlus+ VIP Privileges',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF091E5B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Included automatically across all services and items',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5B6B9A),
            ),
          ),
          const SizedBox(height: 16),

          _buildPrivilegeTile(
            icon: Icons.local_offer_rounded,
            title: '£0 Service Fees Always',
            subtitle: 'Save £2.99 on every booking with no order limit or caps.',
            colors: const [Color(0xFF0B6E64), Color(0xFF14B89A)],
          ),
          const SizedBox(height: 12),

          _buildPrivilegeTile(
            icon: Icons.electric_bolt_rounded,
            title: 'Express Priority Slots',
            subtitle: 'First-choice access to morning & evening collection times.',
            colors: const [Color(0xFF4338CA), Color(0xFF6366F1)],
          ),
          const SizedBox(height: 12),

          _buildPrivilegeTile(
            icon: Icons.card_giftcard_rounded,
            title: '10% Bonus on Prepaid Credit',
            subtitle: 'Exclusive extra credit added on top of all prepaid top-up packages.',
            colors: const [Color(0xFFE26A00), Color(0xFFFFB400)],
          ),
          const SizedBox(height: 12),

          _buildPrivilegeTile(
            icon: Icons.support_agent_rounded,
            title: 'Direct VIP Concierge Line',
            subtitle: 'Instant WhatsApp & phone support with a dedicated rep.',
            colors: const [Color(0xFF1350D1), Color(0xFF3B82F6)],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF091E5B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5B6B9A),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. SIDE-BY-SIDE COMPARISON TABLE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Standard vs VIP Member',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF091E5B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Perk / Feature',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8A99B8),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Standard',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8A99B8),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'VIP Member',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1350D1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          _buildComparisonRow('Service Fee', '£2.99 / order', 'FREE (£0)', highlight: true),
          const Divider(height: 18),
          _buildComparisonRow('Collection Slot', 'Standard', 'First Priority', highlight: false),
          const Divider(height: 18),
          _buildComparisonRow('Prepaid Bonus', 'None', '+10% Bonus', highlight: true),
          const Divider(height: 18),
          _buildComparisonRow('Support Channel', 'Queue', 'VIP Direct Line', highlight: false),
          const Divider(height: 18),
          _buildComparisonRow('Cancellation', 'N/A', 'Anytime (No Fee)', highlight: false),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, String standard, String member, {required bool highlight}) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            feature,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C2B54),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            standard,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8090AE),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            member,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: highlight ? const Color(0xFF086846) : const Color(0xFF1350D1),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. INTERACTIVE FAQ ACCORDION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFaqSection() {
    final faqs = [
      {
        'q': 'How does the free service fee work?',
        'a': 'As soon as your membership is activated on your phone number, the £2.99 service fee is automatically waived on every collection and delivery you book.'
      },
      {
        'q': 'Can I cancel anytime?',
        'a': 'Yes! You can cancel at any time with no lock-in contracts or penalty fees. Simply call or WhatsApp us and your cancellation takes effect at the end of the current billing cycle.'
      },
      {
        'q': 'Is there a minimum spend per order?',
        'a': 'No minimum spend is required to enjoy your £0 service fee benefit. It applies whether you send a single shirt or multiple laundry bags.'
      },
      {
        'q': 'How do I activate my membership?',
        'a': 'Tap the "Call to Subscribe" button below or reach out on WhatsApp (+44 7424 866802). Our team will link the VIP Pass to your account in under 2 minutes!'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF091E5B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          for (int i = 0; i < faqs.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            _buildFaqItem(
              index: i,
              question: faqs[i]['q']!,
              answer: faqs[i]['a']!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaqItem({required int index, required String question, required String answer}) {
    final isExpanded = _expandedFaqs.contains(index);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isExpanded) {
            _expandedFaqs.remove(index);
          } else {
            _expandedFaqs.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF091E5B),
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                  color: const Color(0xFF1350D1),
                  size: 20,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                answer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5B6B9A),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. IN-PAGE CTA SECTION (Scrolls with page, doesn't stick to bottom)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInPageCtaSection(String captionText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF07194A),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFFFD25E).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD25E).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD25E), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Join DryClean Plus VIP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Caption Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              captionText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFD25E),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Call & WhatsApp
          Row(
            children: [
              // WhatsApp Quick Action
              GestureDetector(
                onTap: _openWhatsApp,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.chat_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Main Call Button
              Expanded(
                child: GestureDetector(
                  onTap: _callToSubscribe,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD25E), Color(0xFFFFAC1C)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFAC1C).withValues(alpha: 0.5),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_rounded, color: Color(0xFF07194A), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'CALL TO SUBSCRIBE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF07194A),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Phone Number Link
          GestureDetector(
            onTap: _callToSubscribe,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFB4C8FA), size: 14),
                const SizedBox(width: 6),
                Text(
                  '+44 7424 866802',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB4C8FA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Instant phone & WhatsApp activation · zero contract hassle',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
