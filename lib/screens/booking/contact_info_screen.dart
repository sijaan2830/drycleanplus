import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';

class ContactInfoScreen extends StatefulWidget {
  final bool isEditMode;
  final bool isFromBookingFlow;

  const ContactInfoScreen({
    super.key,
    this.isEditMode = false,
    this.isFromBookingFlow = false,
  });

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  bool _isIndividual = true;
  String _countryCode = 'uk'; // 'uk' (+44) or 'ie' (+353)

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool get _isFormValid {
    final fn = _firstNameController.text.trim();
    final ln = _lastNameController.text.trim();
    final phDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    final baseValid = fn.isNotEmpty && ln.isNotEmpty && phDigits.length >= 7;
    if (!_isIndividual) {
      return baseValid && _companyNameController.text.trim().isNotEmpty;
    }
    return baseValid;
  }

  String get _initials {
    final f = _firstNameController.text.trim();
    final l = _lastNameController.text.trim();
    String res = '';
    if (f.isNotEmpty) res += f[0];
    if (l.isNotEmpty) res += l[0];
    return res.toUpperCase();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      if (userProvider.hasUserData) {
        _firstNameController.text = userProvider.firstName;
        _lastNameController.text = userProvider.lastName;
        _phoneController.text = userProvider.phone;
        _isIndividual = userProvider.customerType != 'company';
        _companyNameController.text = userProvider.companyName ?? '';
      } else if (bookingProvider.hasUserContactInfo) {
        _firstNameController.text = bookingProvider.bookingData.firstName;
        _lastNameController.text = bookingProvider.bookingData.lastName;
        _phoneController.text = bookingProvider.bookingData.phone;
        _isIndividual = bookingProvider.bookingData.customerType != 'company';
        _companyNameController.text = bookingProvider.bookingData.companyName ?? '';
      }
      setState(() {});
    });

    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _companyNameController.addListener(() => setState(() {}));
    _taxNumberController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _taxNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_isFormValid) return;

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final fn = _firstNameController.text.trim();
    final ln = _lastNameController.text.trim();
    final ph = _phoneController.text.trim();
    final cn = !_isIndividual ? _companyNameController.text.trim() : null;
    final cType = _isIndividual ? 'individual' : 'company';

    await bookingProvider.updateContactInfoInFirestore(
      firstName: fn,
      lastName: ln,
      email: bookingProvider.userEmail,
      phone: ph,
    );

    await userProvider.saveUserData(
      firstName: fn,
      lastName: ln,
      phone: ph,
      customerType: cType,
      companyName: cn,
    );

    bookingProvider.updateContactInfo(
      firstName: fn,
      lastName: ln,
      email: bookingProvider.userEmail,
      phone: ph,
      customerType: cType,
      companyName: cn,
    );

    bookingProvider.acceptTerms(true);

    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final inBooking = widget.isFromBookingFlow || (args?['isFromBookingFlow'] == true);

    if (widget.isEditMode) {
      Navigator.of(context).pop();
    } else if (inBooking) {
      Navigator.of(context).pushNamed('/booking_overview');
    } else {
      Navigator.of(context).pushNamed('/booking_overview');
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = _isFormValid;
    final initials = _initials;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: Stack(
          children: [
            // Ambient top-right decorative circle
            Positioned(
              top: -140,
              right: -150,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            // Ambient bottom-left decorative circle
            Positioned(
              bottom: -160,
              left: -210,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        Text(
                          'Contact',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Hero Row: Title & Illustration badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Who’s booking?',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                              height: 1.15,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'We use this to confirm your pickup and keep you updated.',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFDDE8FF),
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // 88x88 Floating Illustration Badge
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFFE8F0FF),
                                          width: 5,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x8C02104C),
                                            blurRadius: 22,
                                            offset: Offset(0, 14),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/price_dryclean.png',
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Segmented Control (Individual / Company)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withValues(alpha: 0.18),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isIndividual = true),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 44,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(999),
                                              color: _isIndividual ? Colors.white : Colors.transparent,
                                              boxShadow: _isIndividual
                                                  ? const [
                                                      BoxShadow(
                                                        color: Color(0x6602104C),
                                                        blurRadius: 12,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person_rounded,
                                                      size: 18,
                                                      color: _isIndividual
                                                          ? const Color(0xFF0B1F5B)
                                                          : Colors.white,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Individual',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 14.0,
                                                        fontWeight: FontWeight.w800,
                                                        color: _isIndividual
                                                            ? const Color(0xFF0B1F5B)
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isIndividual = false),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 44,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(999),
                                              color: !_isIndividual ? Colors.white : Colors.transparent,
                                              boxShadow: !_isIndividual
                                                  ? const [
                                                      BoxShadow(
                                                        color: Color(0x6602104C),
                                                        blurRadius: 12,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.business_rounded,
                                                      size: 18,
                                                      color: !_isIndividual
                                                          ? const Color(0xFF0B1F5B)
                                                          : Colors.white,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Company',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 14.0,
                                                        fontWeight: FontWeight.w800,
                                                        color: !_isIndividual
                                                            ? const Color(0xFF0B1F5B)
                                                            : Colors.white,
                                                      ),
                                                    ),
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
                                const SizedBox(height: 14),

                                // Details Card (cd v)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x8C02104C),
                                        blurRadius: 30,
                                        offset: Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Stack(
                                      children: [
                                        // Background disc
                                        Positioned(
                                          top: -70,
                                          right: -60,
                                          child: Container(
                                            width: 180,
                                            height: 180,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _isIndividual ? const Color(0xFFEEF0FF) : const Color(0xFFE6F4F1),
                                            ),
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // Header - changes dynamically based on Individual vs Company
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 48,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(16),
                                                      gradient: LinearGradient(
                                                        colors: _isIndividual
                                                            ? const [Color(0xFF4338CA), Color(0xFF6D4AFF)]
                                                            : const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: (_isIndividual
                                                                  ? const Color(0xFF4338CA)
                                                                  : const Color(0xFF0F766E))
                                                              .withValues(alpha: 0.35),
                                                          blurRadius: 14,
                                                          offset: const Offset(0, 6),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: _isIndividual
                                                          ? (initials.isNotEmpty
                                                              ? Text(
                                                                  initials,
                                                                  style: GoogleFonts.plusJakartaSans(
                                                                    fontSize: 19,
                                                                    fontWeight: FontWeight.w800,
                                                                    color: Colors.white,
                                                                  ),
                                                                )
                                                              : const Icon(Icons.person_rounded, color: Colors.white, size: 24))
                                                          : const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          _isIndividual ? 'Your details' : 'Company details',
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 19,
                                                            fontWeight: FontWeight.w800,
                                                            color: const Color(0xFF0B1F5B),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          _isIndividual
                                                              ? 'So our driver can reach you'
                                                              : 'Business invoice & order details',
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: const Color(0xFF5B6B9A),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // If Company tab is selected, show company fields prominently first
                                              if (!_isIndividual) ...[
                                                _buildInput(
                                                  controller: _companyNameController,
                                                  label: 'Company name',
                                                  icon: Icons.domain_rounded,
                                                  textCapitalization: TextCapitalization.words,
                                                ),
                                                const SizedBox(height: 12),
                                                _buildInput(
                                                  controller: _taxNumberController,
                                                  label: 'Tax / VAT number (optional)',
                                                  icon: Icons.receipt_long_rounded,
                                                ),
                                                const SizedBox(height: 14),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        color: const Color(0xFFE6F4F1),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF0F766E)),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'CONTACT PERSON',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w800,
                                                              letterSpacing: 0.6,
                                                              color: const Color(0xFF0F766E),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                              ],

                                              // First Name & Last Name in two columns
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildInput(
                                                      controller: _firstNameController,
                                                      label: 'First name',
                                                      textCapitalization: TextCapitalization.words,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: _buildInput(
                                                      controller: _lastNameController,
                                                      label: 'Last name',
                                                      textCapitalization: TextCapitalization.words,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),

                                              // Phone number with country code picker (fixed 2.0px overflow)
                                              Row(
                                                children: [
                                                  // Country Code selector
                                                  Container(
                                                    width: 114,
                                                    height: 60,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(18),
                                                      border: Border.all(color: const Color(0xFFE4EBFB), width: 2),
                                                      color: const Color(0xFFF4F7FF),
                                                    ),
                                                    child: DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        value: _countryCode,
                                                        isExpanded: true,
                                                        iconSize: 20,
                                                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0B1F5B)),
                                                        onChanged: (val) {
                                                          if (val != null) setState(() => _countryCode = val);
                                                        },
                                                        items: [
                                                          DropdownMenuItem(
                                                            value: 'uk',
                                                            child: FittedBox(
                                                              fit: BoxFit.scaleDown,
                                                              alignment: Alignment.centerLeft,
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Text('🇬🇧 ', style: TextStyle(fontSize: 16)),
                                                                  Text(
                                                                    '+44',
                                                                    style: GoogleFonts.plusJakartaSans(
                                                                      fontSize: 14.5,
                                                                      fontWeight: FontWeight.w800,
                                                                      color: const Color(0xFF0B1F5B),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          DropdownMenuItem(
                                                            value: 'ie',
                                                            child: FittedBox(
                                                              fit: BoxFit.scaleDown,
                                                              alignment: Alignment.centerLeft,
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Text('🇮🇪 ', style: TextStyle(fontSize: 16)),
                                                                  Text(
                                                                    '+353',
                                                                    style: GoogleFonts.plusJakartaSans(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w800,
                                                                      color: const Color(0xFF0B1F5B),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),

                                                  // Phone number input
                                                  Expanded(
                                                    child: _buildInput(
                                                      controller: _phoneController,
                                                      label: 'Phone number',
                                                      keyboardType: TextInputType.phone,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+]')),
                                                      ],
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
                                ),
                                const SizedBox(height: 16),

                                // Security Note Box
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white.withValues(alpha: 0.14),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.28),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.lock_rounded,
                                        color: Color(0xFFFFC73A),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Your information is encrypted and stored securely. We never share your details with third parties.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            height: 1.45,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fixed Bottom Dock CTA
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  14 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0A2468).withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: GestureDetector(
                      onTap: valid ? _saveAndContinue : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: valid
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFFFD25E), Color(0xFFFFB400)],
                                )
                              : null,
                          color: valid ? null : Colors.white.withValues(alpha: 0.2),
                          boxShadow: valid
                              ? const [
                                  BoxShadow(
                                    color: Color(0x8CFFB400),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CONTINUE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: valid
                                    ? const Color(0xFF0B1F5B)
                                    : Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: valid
                                  ? const Color(0xFF0B1F5B)
                                  : Colors.white.withValues(alpha: 0.75),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final hasVal = controller.text.trim().isNotEmpty;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasVal ? const Color(0xFF12A38A) : const Color(0xFFE4EBFB),
          width: 2,
        ),
        color: const Color(0xFFF4F7FF),
      ),
      child: Stack(
        children: [
          if (icon != null)
            Positioned(
              left: 14,
              top: 18,
              child: Icon(icon, color: const Color(0xFF6B7BA8), size: 22),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: icon != null ? 46 : 14,
              right: hasVal ? 38 : 14,
              top: 6,
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              cursorColor: const Color(0xFF1553D6),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B1F5B),
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7BA8),
                ),
                floatingLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1553D6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 12, bottom: 4),
              ),
            ),
          ),
          if (hasVal)
            Positioned(
              right: 12,
              top: 20,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF12A38A),
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
