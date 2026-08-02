import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'faq_screen.dart';
import 'offers_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'past_orders_screen.dart';

class MoreScreen extends StatefulWidget {
  final bool? showBottomNav;

  const MoreScreen({super.key, this.showBottomNav});

  bool get _showBottomNav => showBottomNav ?? true;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'More',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // First Group
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Account',
                onTap: () => Navigator.of(context).pushNamed('/account'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Orders',
                onTap: () => Navigator.of(context).pushNamed('/orders'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.history_rounded,
                title: 'Past Orders',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PastOrdersScreen()),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.local_offer_outlined,
                title: 'Offers',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OffersScreen()),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FAQScreen()),
                ),
              ),

              // Legal Section
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 32, bottom: 8),
                child: Text(
                  'LEGAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold.withOpacity(0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              _buildMenuItem(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
                ),
              ),
              
              SizedBox(height: widget._showBottomNav ? 100 : 50),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build consistent menu items
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.gold,
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gold,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for thin dividers
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60), // Align divider after the icon
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.white.withOpacity(0.1),
      ),
    );
  }
}
