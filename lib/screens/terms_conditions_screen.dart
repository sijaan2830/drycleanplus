import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'package:shimmer/shimmer.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/onboarding');
            }
          },
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading ? _buildSkeletonContent() : _buildRealContent(),
    );
  }

  Widget _buildSkeletonContent() {
    return Shimmer.fromColors(
      baseColor: AppColors.white.withOpacity(0.05),
      highlightColor: AppColors.white.withOpacity(0.1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonSection(),
            const SizedBox(height: 20),
            _buildSkeletonSection(),
            const SizedBox(height: 20),
            _buildSkeletonSection(),
            const SizedBox(height: 20),
            _buildSkeletonSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 24,
          color: AppColors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 16,
          color: AppColors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 16,
          color: AppColors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 8),
        Container(
          width: 300,
          height: 16,
          color: AppColors.white.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildRealContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introduction
          _buildSection(
            '1. Introduction',
            'Welcome to DrycleanPlus. These Terms and Conditions govern your use of our dry cleaning and laundry services. By using our services, you agree to be bound by these terms. Please read them carefully before placing an order.',
          ),
          const SizedBox(height: 20),

          // Services
          _buildSection(
            '2. Our Services',
            'DrycleanPlus provides professional dry cleaning, laundry, and garment care services including but not limited to:\n\n'
            '• Dry cleaning for all types of garments\n'
            '• Laundry and ironing services\n'
            '• Duvet and bedding cleaning\n'
            '• Household item cleaning\n'
            '• Collection and delivery services\n\n'
            'We reserve the right to modify, suspend, or discontinue any service at any time without prior notice.',
          ),
          const SizedBox(height: 20),

          // Orders and Payments
          _buildSection(
            '3. Orders and Payments',
            '• All orders are subject to acceptance and availability\n'
            '• Prices are displayed on our app and website and may be updated from time to time\n'
            '• Payment must be made at the time of booking or upon delivery as per the selected payment method\n'
            '• We accept major credit/debit cards and digital payment methods\n'
            '• Prepaid packs are non-refundable but can be used for future services\n'
            '• Prices include VAT where applicable',
          ),
          const SizedBox(height: 20),

          // Collection and Delivery
          _buildSection(
            '4. Collection and Delivery',
            '• Collection and delivery times are estimates and may vary due to traffic or weather conditions\n'
            '• You must ensure someone is available at the specified address during the selected time slot\n'
            '• If access is not possible, we may charge a re-delivery fee\n'
            '• We are not responsible for delays caused by circumstances beyond our control\n'
            '• Safe place delivery is available at your own risk',
          ),
          const SizedBox(height: 20),

          // Garment Care
          _buildSection(
            '5. Garment Care and Liability',
            '• You must inform us of any special care requirements or known issues with garments\n'
            '• We are not liable for damage caused by normal wear and tear, pre-existing conditions, or manufacturer defects\n'
            '• Claims for damaged items must be reported within 24 hours of delivery\n'
            '• Our liability is limited to the replacement value of the garment, up to a maximum of 10 times the cleaning charge\n'
            '• We reserve the right to refuse service for items that may be damaged by cleaning',
          ),
          const SizedBox(height: 20),

          // Cancellations
          _buildSection(
            '6. Cancellations and Refunds',
            '• Orders can be cancelled free of charge up to 2 hours before scheduled collection\n'
            '• Cancellations within 2 hours may incur a cancellation fee\n'
            '• Refunds for prepaid orders will be processed within 5-7 business days\n'
            '• We reserve the right to cancel orders due to unforeseen circumstances\n'
            '• In case of service issues, we may offer re-cleaning or credit towards future services',
          ),
          const SizedBox(height: 20),

          // User Accounts
          _buildSection(
            '7. User Accounts',
            '• You are responsible for maintaining the confidentiality of your account\n'
            '• You must provide accurate and complete information when creating an account\n'
            '• You are responsible for all activities under your account\n'
            '• We reserve the right to suspend or terminate accounts that violate these terms\n'
            '• Guest accounts are available with limited functionality',
          ),
          const SizedBox(height: 20),

          // Privacy
          _buildSection(
            '8. Privacy and Data Protection',
            '• Your personal data is processed in accordance with our Privacy Policy\n'
            '• We collect and store data necessary for service delivery\n'
            '• Location data is used for collection and delivery purposes only\n'
            '• Payment information is securely processed and not stored on our servers\n'
            '• You have the right to access, correct, or delete your personal data',
          ),
          const SizedBox(height: 20),

          // Intellectual Property
          _buildSection(
            '9. Intellectual Property',
            '• All content on our app and website is owned by DrycleanPlus\n'
            '• Our logo, brand name, and designs are protected by intellectual property laws\n'
            '• You may not use our intellectual property without written permission\n'
            '• User-generated content, such as reviews, may be used for marketing purposes',
          ),
          const SizedBox(height: 20),

          // Dispute Resolution
          _buildSection(
            '10. Dispute Resolution',
            '• In case of disputes, please contact our customer service team first\n'
            '• We aim to resolve all complaints within 14 days\n'
            '• Unresolved disputes may be referred to independent arbitration\n'
            '• These terms are governed by the laws of England and Wales\n'
            '• Any legal proceedings shall be conducted in the courts of England and Wales',
          ),
          const SizedBox(height: 20),

          // Changes to Terms
          _buildSection(
            '11. Changes to Terms',
            '• We may update these terms from time to time\n'
            '• Significant changes will be notified via email or app notification\n'
            '• Continued use of our services after changes constitutes acceptance\n'
            '• Previous versions of terms are available upon request',
          ),
          const SizedBox(height: 20),

          // Contact
          _buildSection(
            '12. Contact Us',
            'If you have any questions about these Terms and Conditions, please contact us:\n\n'
            '• Email: info@drycleanplus.com\n'
            '• Phone: +44 7424 866802\n'
            '• Address: 2c Bar Gate, Newark, NG24 1ES, United Kingdom\n'
            '• Live chat available in the app',
          ),
          const SizedBox(height: 30),

          // Last Updated
          Center(
            child: Text(
              'Last Updated: April 2026',
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.white.withOpacity(0.8),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}