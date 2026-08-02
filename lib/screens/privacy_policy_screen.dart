import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'package:shimmer/shimmer.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
          'Privacy Policy',
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
            'DrycleanPlus ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.\n\n'
            'Please read this privacy policy carefully. By using our services, you consent to the practices described in this policy.',
          ),
          const SizedBox(height: 20),

          // Information We Collect
          _buildSection(
            '2. Information We Collect',
            'We collect information that you provide directly to us and information that is collected automatically when you use our services.\n\n'
            'Personal Information:\n'
            '• Name and contact details (email, phone number)\n'
            '• Delivery and collection addresses\n'
            '• Payment information (processed securely via third-party providers)\n'
            '• Account credentials\n'
            '• Communication preferences\n\n'
            'Automatically Collected Information:\n'
            '• Device information (type, operating system, unique identifiers)\n'
            '• Location data (for collection and delivery services)\n'
            '• Usage data (app interactions, features used)\n'
            '• Log data (access times, pages viewed, referring URL)',
          ),
          const SizedBox(height: 20),

          // How We Use Information
          _buildSection(
            '3. How We Use Your Information',
            'We use the information we collect for various purposes, including:\n\n'
            '• To provide and maintain our services\n'
            '• To process your orders and payments\n'
            '• To arrange collection and delivery of your items\n'
            '• To communicate with you about your orders\n'
            '• To send promotional materials (with your consent)\n'
            '• To improve our services and develop new features\n'
            '• To detect and prevent fraud\n'
            '• To comply with legal obligations\n'
            '• To resolve disputes and enforce our agreements',
          ),
          const SizedBox(height: 20),

          // Legal Basis
          _buildSection(
            '4. Legal Basis for Processing',
            'We process your personal data under the following legal bases:\n\n'
            '• Contract: To fulfill our service agreement with you\n'
            '• Consent: For marketing communications and certain data uses\n'
            '• Legitimate Interest: To improve our services and prevent fraud\n'
            '• Legal Obligation: To comply with applicable laws and regulations\n'
            '• Vital Interests: To protect the safety of individuals',
          ),
          const SizedBox(height: 20),

          // Information Sharing
          _buildSection(
            '5. Information Sharing',
            'We may share your information with:\n\n'
            '• Service Providers: Third parties who help us deliver our services (payment processors, delivery partners, cloud services)\n'
            '• Business Partners: For joint services or promotions (with your consent)\n'
            '• Legal Requirements: When required by law or to protect our rights\n'
            '• Business Transfers: In connection with merger, acquisition, or sale of assets\n\n'
            'We do not sell your personal information to third parties.',
          ),
          const SizedBox(height: 20),

          // Data Security
          _buildSection(
            '6. Data Security',
            'We implement appropriate technical and organizational measures to protect your personal data, including:\n\n'
            '• Encryption of data in transit and at rest\n'
            '• Secure servers and databases\n'
            '• Regular security assessments\n'
            '• Access controls and authentication\n'
            '• Staff training on data protection\n\n'
            'However, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security.',
          ),
          const SizedBox(height: 20),

          // Data Retention
          _buildSection(
            '7. Data Retention',
            'We retain your personal data for as long as necessary to:\n\n'
            '• Provide our services to you\n'
            '• Comply with legal obligations\n'
            '• Resolve disputes\n'
            '• Enforce our agreements\n\n'
            'When data is no longer needed, we securely delete or anonymize it. Order records are typically kept for 7 years for tax and legal purposes.',
          ),
          const SizedBox(height: 20),

          // Your Rights
          _buildSection(
            '8. Your Rights',
            'Under data protection laws, you have the following rights:\n\n'
            '• Access: Request a copy of your personal data\n'
            '• Rectification: Request correction of inaccurate data\n'
            '• Erasure: Request deletion of your data ("right to be forgotten")\n'
            '• Restriction: Request limitation of processing\n'
            '• Portability: Receive your data in a portable format\n'
            '• Objection: Object to certain processing activities\n'
            '• Withdraw Consent: Withdraw consent at any time\n\n'
            'To exercise these rights, contact us at info@drycleanplus.com',
          ),
          const SizedBox(height: 20),

          // Location Data
          _buildSection(
            '9. Location Data',
            'We collect and use your location data for:\n\n'
            '• Arranging collection and delivery services\n'
            '• Optimizing delivery routes\n'
            '• Providing accurate service availability\n'
            '• Improving our service coverage\n\n'
            'Location data is collected with your permission and can be disabled in your device settings. This may affect certain features of our service.',
          ),
          const SizedBox(height: 20),

          // Cookies and Tracking
          _buildSection(
            '10. Cookies and Tracking Technologies',
            'Our app may use the following technologies:\n\n'
            '• Analytics: To understand how users interact with our app\n'
            '• Crash Reporting: To identify and fix technical issues\n'
            '• Performance Monitoring: To optimize app performance\n'
            '• Advertising Identifiers: For personalized advertising (with consent)\n\n'
            'You can manage these settings in your device preferences and within our app.',
          ),
          const SizedBox(height: 20),

          // Children's Privacy
          _buildSection(
            '11. Children\'s Privacy',
            'Our services are not intended for children under 16 years of age. We do not knowingly collect personal data from children. If we become aware that we have collected data from a child, we will take steps to delete it.\n\n'
            'Parents or guardians who believe their child has provided personal data to us should contact us immediately.',
          ),
          const SizedBox(height: 20),

          // International Transfers
          _buildSection(
            '12. International Data Transfers',
            'Your data may be transferred to and processed in countries outside the UK/EU. When this occurs, we ensure appropriate safeguards are in place, including:\n\n'
            '• Standard Contractual Clauses approved by relevant authorities\n'
            '• Adequacy decisions where applicable\n'
            '• Binding Corporate Rules for intra-group transfers\n'
            '• Other legally recognized transfer mechanisms',
          ),
          const SizedBox(height: 20),

          // Third-Party Links
          _buildSection(
            '13. Third-Party Links',
            'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies before providing any personal information.',
          ),
          const SizedBox(height: 20),

          // Changes to Policy
          _buildSection(
            '14. Changes to This Policy',
            'We may update this privacy policy from time to time. We will notify you of any significant changes by:\n\n'
            '• Posting a notice in the app\n'
            '• Sending you an email notification\n'
            '• Updating the "Last Updated" date\n\n'
            'We encourage you to review this policy periodically. Your continued use of our services after changes constitutes acceptance of the updated policy.',
          ),
          const SizedBox(height: 20),

          // Contact
          _buildSection(
            '15. Contact Us',
            'If you have any questions about this Privacy Policy or wish to exercise your rights, please contact us:\n\n'
            'Data Protection Officer\n'
            'Email: info@drycleanplus.com\n'
            'Phone: +44 7424 866802\n'
            'Address: 2c Bar Gate, Newark, NG24 1ES, United Kingdom\n\n'
            'You also have the right to lodge a complaint with the Information Commissioner\'s Office (ICO) at www.ico.org.uk',
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