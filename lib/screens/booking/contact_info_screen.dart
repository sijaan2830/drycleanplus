import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';

class ContactInfoScreen extends StatefulWidget {
  final bool isEditMode;
  final bool isFromBookingFlow;

  const ContactInfoScreen(
      {super.key, this.isEditMode = false, this.isFromBookingFlow = false});

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen>
    with SingleTickerProviderStateMixin {
  // Form State
  bool isIndividual = true;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  // Simple validation logic
  bool get isFormValid {
    bool baseValid = _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;

    if (!isIndividual) {
      return baseValid && _companyNameController.text.isNotEmpty;
    }
    return baseValid;
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['isFromBookingFlow'] == true) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.hasUserData) {
        _firstNameController.text = userProvider.firstName;
        _lastNameController.text = userProvider.lastName;
        _phoneController.text = userProvider.phone;
        isIndividual = userProvider.customerType == 'individual';
        _companyNameController.text = userProvider.companyName ?? '';
        setState(() {});
      }
    });

    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _companyNameController.addListener(() => setState(() {}));
    _phoneController.addListener(() {
      setState(() {});
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.updatePhone(_phoneController.text.trim());
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _taxNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveAndContinue() async {
    if (isFormValid) {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await bookingProvider.updateContactInfoInFirestore(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: bookingProvider.userEmail,
        phone: _phoneController.text.trim(),
      );

      await userProvider.saveUserData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        customerType: isIndividual ? 'individual' : 'company',
        companyName:
            !isIndividual ? _companyNameController.text.trim() : null,
      );

      bookingProvider.updateContactInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: '',
        phone: _phoneController.text.trim(),
        customerType: isIndividual ? 'individual' : 'company',
        companyName:
            !isIndividual ? _companyNameController.text.trim() : null,
      );

      bookingProvider.acceptTerms(true);

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isFromBookingFlow =
          widget.isFromBookingFlow || (args?['isFromBookingFlow'] == true);

      if (widget.isEditMode) {
        Navigator.of(context).pop();
      } else if (isFromBookingFlow) {
        Navigator.of(context).pushNamed('/booking_overview');
      } else {
        Navigator.of(context).pushNamed('/booking_overview');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.white, size: 16),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        centerTitle: true,
        // ── "Contact" title using Cormorant Garamond (Google Font) ──
        title: Text(
          "Contact",
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
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
                  AppColors.gold.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Type Toggle ────────────────────────────────────
                    _buildTypeSelector(),
                    const SizedBox(height: 20),

                    // ── First + Last Name ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _firstNameController,
                            hint: "First name",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _lastNameController,
                            hint: "Last name",
                          ),
                        ),
                      ],
                    ),

                    // ── Company Fields ─────────────────────────────────
                    if (!isIndividual) ...[
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _companyNameController,
                        hint: "Company name",
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _taxNumberController,
                        hint: "Tax number (optional)",
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ── Phone ──────────────────────────────────────────
                    _buildPhoneField(),

                    const SizedBox(height: 28),

                    // ── Privacy Notice ─────────────────────────────────
                    _buildPrivacyNotice(),
                  ],
                ),
              ),
            ),

            // ── Sticky Save Button ─────────────────────────────────────
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ─── Type Selector ──────────────────────────────────────────────────────────
  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildTypeTab("Individual", isIndividual, () {
            setState(() => isIndividual = true);
          }),
          _buildTypeTab("Company", !isIndividual, () {
            setState(() => isIndividual = false);
          }),
        ],
      ),
    );
  }

  Widget _buildTypeTab(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.gold.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.gold, width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.white.withOpacity(0.55),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Field — hint text only, no floating label ──────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppColors.white.withOpacity(0.35),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.primaryBlueDark.withOpacity(0.85),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.gold.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
    );
  }

  // ─── Phone Field ────────────────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark.withOpacity(0.85),
        border:
            Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Country badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withOpacity(0.18),
                  AppColors.gold.withOpacity(0.06),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              border: const Border(
                right: BorderSide(color: AppColors.gold, width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🇬🇧", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  "UK",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Number input — hint only, no label
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Mobile number",
                hintStyle: GoogleFonts.inter(
                  color: AppColors.white.withOpacity(0.35),
                  fontSize: 14,
                ),
                prefixText: "+44 ",
                prefixStyle: GoogleFonts.inter(
                  color: AppColors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Privacy Notice — white text ─────────────────────────────────────────────
  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 16, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your information is encrypted and stored securely. "
              "We never share your details with third parties.",
              style: GoogleFonts.inter(
                fontSize: 12.5,
                // ── bright white, clearly readable ──
                color: AppColors.white,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Save Button ────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedOpacity(
          opacity: isFormValid ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: isFormValid ? _saveAndContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: isFormValid
                    ? LinearGradient(
                        colors: [
                          AppColors.gold,
                          AppColors.gold.withOpacity(0.82),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isFormValid ? null : AppColors.primaryBlueDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold, width: 1.5),
                boxShadow: isFormValid
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isEditMode ? "SAVE CHANGES" : "CONTINUE",
                      style: GoogleFonts.inter(
                        color: isFormValid
                            ? AppColors.primaryBlue
                            : AppColors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.4,
                      ),
                    ),
                    if (isFormValid) ...[
                      const SizedBox(width: 10),
                      Icon(
                        widget.isEditMode
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}