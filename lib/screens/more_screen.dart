import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../widgets/app_ui.dart';
import 'account_screen.dart';
import 'faq_screen.dart';
import 'membership_screen.dart';
import 'offers_screen.dart';
import 'past_orders_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

/// More Screen matching the compact, proportional More.html mockup.
class MoreScreen extends StatefulWidget {
  final bool? showBottomNav;

  const MoreScreen({super.key, this.showBottomNav});

  bool get _showBottomNav => showBottomNav ?? true;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  void _push(Widget page, {String? routeName}) {
    Navigator.of(context).push(smoothRoute(page, name: routeName));
  }

  void _showCoverageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Active Service Areas',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF0B1F5B)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We currently provide free collection & delivery across 4 regional hubs and surrounding 0–20 mile areas:',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45, color: const Color(0xFF34457D), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildHubItem('1. Walsall (West Midlands)', 'Birmingham, Wolverhampton, Dudley, West Bromwich, Solihull, Sutton Coldfield, Cannock, Lichfield, Coventry, Tamworth, Redditch, Telford'),
              const SizedBox(height: 10),
              _buildHubItem('2. Newark-on-Trent (Nottinghamshire)', 'Nottingham, Newark, Lincoln, Grantham, Mansfield, West Bridgford, Arnold, Southwell, Hucknall, Worksop, Retford, Sleaford'),
              const SizedBox(height: 10),
              _buildHubItem('3. Barnsley (South Yorkshire)', 'Sheffield, Leeds, Wakefield, Rotherham, Huddersfield, Doncaster, Bradford, Halifax, Dewsbury, Pontefract'),
              const SizedBox(height: 10),
              _buildHubItem('4. Stockton-on-Tees (Teesside & Durham)', 'Middlesbrough, Stockton, Darlington, Hartlepool, Durham, Billingham, Thornaby, Yarm, Redcar, Newton Aycliffe, Bishop Auckland'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF1553D6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubItem(String title, String cities) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text(cities, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.35, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1245B5),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2F7BF5),
                Color(0xFF1C61E4),
                Color(0xFF1245B5),
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient circles
              Positioned(
                right: -160,
                top: -150,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -230,
                bottom: 140,
                child: Container(
                  width: 440,
                  height: 440,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(18, 14, 18, widget._showBottomNav ? 110 : 30),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Page Title "More"
                          Text(
                            'More',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Profile Glass Card
                          _buildProfileCard(),
                          const SizedBox(height: 12),

                          // Dryclean Plus+ Compact Banner
                          _buildMembershipBanner(),
                          const SizedBox(height: 18),

                          // Section: Orders
                          _buildSectionHeader('Orders'),
                          const SizedBox(height: 8),
                          _buildGroupCard([
                            _buildItemRow(
                              icon: Icons.receipt_long_rounded,
                              title: 'Orders',
                              subtitle: 'Track your active orders',
                              colorA: const Color(0xFF1553D6),
                              colorB: const Color(0xFF3B82F6),
                              onTap: () => Navigator.of(context).pushNamed('/orders'),
                            ),
                            _buildItemRow(
                              icon: Icons.history_rounded,
                              title: 'Past orders',
                              subtitle: 'Your delivered orders',
                              colorA: const Color(0xFF4338CA),
                              colorB: const Color(0xFF6D4AFF),
                              onTap: () => _push(const PastOrdersScreen(), routeName: '/past_orders'),
                            ),
                            _buildItemRow(
                              icon: Icons.local_offer_rounded,
                              title: 'Offers',
                              subtitle: 'Discounts and coupon codes',
                              colorA: const Color(0xFFE26A00),
                              colorB: const Color(0xFFFFB400),
                              onTap: () => _push(const OffersScreen(), routeName: '/offers'),
                            ),
                          ]),
                          const SizedBox(height: 18),

                          // Section: Support
                          _buildSectionHeader('Support'),
                          const SizedBox(height: 8),
                          _buildGroupCard([
                            _buildItemRow(
                              icon: Icons.map_outlined,
                              title: 'Service Areas',
                              subtitle: 'West Midlands, Nottinghamshire, Yorkshire & Teesside',
                              colorA: const Color(0xFF0284C7),
                              colorB: const Color(0xFF38BDF8),
                              onTap: _showCoverageDialog,
                            ),
                            _buildItemRow(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & FAQs',
                              subtitle: 'Frequently asked questions',
                              colorA: const Color(0xFF0B6E64),
                              colorB: const Color(0xFF12A38A),
                              onTap: () => _push(const FAQScreen(), routeName: '/faq'),
                            ),
                            _buildItemRow(
                              icon: Icons.mail_outline_rounded,
                              title: 'Email Us',
                              subtitle: 'contact@drycleanplus.co.uk',
                              colorA: const Color(0xFF1553D6),
                              colorB: const Color(0xFF4F95FF),
                              onTap: () async {
                                final uri = Uri.parse('mailto:contact@drycleanplus.co.uk');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 18),

                          // Section: Legal
                          _buildSectionHeader('Legal'),
                          const SizedBox(height: 8),
                          _buildGroupCard([
                            _buildItemRow(
                              icon: Icons.shield_outlined,
                              title: 'Privacy Policy',
                              subtitle: null,
                              colorA: const Color(0xFF2E4C9E),
                              colorB: const Color(0xFF5B7BD5),
                              onTap: () => _push(const PrivacyPolicyScreen(), routeName: '/privacy_policy'),
                            ),
                            _buildItemRow(
                              icon: Icons.description_outlined,
                              title: 'Terms of Service',
                              subtitle: null,
                              colorA: const Color(0xFF2E4C9E),
                              colorB: const Color(0xFF5B7BD5),
                              onTap: () => _push(const TermsConditionsScreen(), routeName: '/terms_conditions'),
                            ),
                          ]),
                        ],
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

  // ── Profile Glass Card ────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        final name = '${user.firstName} ${user.lastName}'.trim();
        final a = user.firstName.trim().isNotEmpty ? user.firstName.trim()[0] : '';
        final b = user.lastName.trim().isNotEmpty ? user.lastName.trim()[0] : '';
        final initials = (a + b).toUpperCase();
        final displayInitials = initials.isNotEmpty ? initials : 'U';

        return GestureDetector(
          onTap: () => _push(const AccountScreen(), routeName: '/account'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF02104C).withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                // 60x60 Avatar with gold border
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFC73A), width: 3),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFD6E4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF02104C).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayInitials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1553D6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),

                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Your Account' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email.isNotEmpty ? user.email : 'Manage your details & address',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDDE8FF),
                        ),
                      ),
                    ],
                  ),
                ),

                // 28x28 Glass Chevron button
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── DrycleanPlus+ Membership Banner ───────────────────────────────────────

  Widget _buildMembershipBanner() {
    return GestureDetector(
      onTap: () => _push(const MembershipScreen(), routeName: '/membership'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF1553D6), Color(0xFF2B7FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFFFC73A),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF02104C).withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // 40x40 Coin Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFF0B8), Color(0xFFFFC73A), Color(0xFFC98A00)],
                  center: Alignment(-0.3, -0.3),
                  radius: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC73A).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.local_laundry_service_rounded,
                  size: 21,
                  color: Color(0xFF0A2468),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.satisfy(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Dryclean',
                          style: TextStyle(
                            color: Color(0xFF042407),
                          ),
                        ),
                        TextSpan(
                          text: 'Plus',
                          style: TextStyle(
                            color: Color(0xFFE5262D),
                          ),
                        ),
                        TextSpan(
                          text: '+',
                          style: TextStyle(
                            color: Color(0xFFE5262D),
                            fontWeight: FontWeight.w900,
                            fontSize: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Skip the service fee, £3.99 / month',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDDE8FF),
                    ),
                  ),
                ],
              ),
            ),

            // Join pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Join',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1553D6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(left: 4, right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFC73A),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC73A).withValues(alpha: 0.9),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Group Card (Unified container for section items) ───────────────────────

  Widget _buildGroupCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(items.length, (i) {
          final isNotLast = i < items.length - 1;
          return Column(
            children: [
              items[i],
              if (isNotLast)
                Container(
                  margin: const EdgeInsets.only(left: 64, right: 12),
                  height: 1.5,
                  color: const Color(0xFFEDF1FB),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ── Item Row inside Group ─────────────────────────────────────────────────

  Widget _buildItemRow({
    required IconData icon,
    required String title,
    required String? subtitle,
    required Color colorA,
    required Color colorB,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // 42x42 Gradient Tile
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [colorA, colorB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorA.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 21),
              ),
            ),
            const SizedBox(width: 12),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1F5B),
                      letterSpacing: -0.15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5B6B9A),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 28x28 Circular Chevron button
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEEF3FF),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF0B1F5B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
