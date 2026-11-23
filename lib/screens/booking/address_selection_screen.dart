import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_ui.dart';
import 'add_address_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  final bool isEditMode;
  final bool isFromBookingFlow;

  const AddressSelectionScreen({
    super.key,
    this.isEditMode = false,
    this.isFromBookingFlow = false,
  });

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  Address? _selectedAddress;
  bool _hasCheckedDefault = false;
  bool _redirecting = false;
  bool _autoOpenedAdd = false;

  bool get _inBookingFlow {
    final args = ModalRoute.of(context)?.settings.arguments;
    final fromArgs = args is Map && args['isFromBookingFlow'] == true;
    return fromArgs || widget.isFromBookingFlow;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedDefault) {
      _hasCheckedDefault = true;
      _checkForDefaultAddress();
    }
  }

  void _redirect(String routeName, {Map<String, dynamic>? arguments}) {
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
    });
  }

  void _checkForDefaultAddress() {
    final fromFlow = _inBookingFlow;
    final booking = Provider.of<BookingProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);

    if (user.hasAddress && !widget.isEditMode) {
      booking.setUserDefaultAddress(
        Address(
          id: user.savedAddressId ?? 'user_profile_address',
          line1: user.savedAddressLine1!,
          line2: user.savedAddressLine2,
          city: user.savedCity ?? '',
          postalCode: user.savedPostcode!,
          isDefault: true,
        ),
      );
      if (fromFlow) {
        _redirect('/contact_info', arguments: {'isFromBookingFlow': true});
      } else {
        _redirect('/service_selection');
      }
      return;
    }

    if (booking.hasUserDefaultAddress && !widget.isEditMode && !fromFlow) {
      _redirect('/service_selection');
      return;
    }

    if (fromFlow && booking.hasUserDefaultAddress && !widget.isEditMode) {
      if (booking.hasUserContactInfo) {
        _redirect('/booking_overview', arguments: {'isFromBookingFlow': true});
      } else {
        _redirect('/contact_info', arguments: {'isFromBookingFlow': true});
      }
      return;
    }

    _selectedAddress = booking.bookingData.selectedAddress;
  }

  Future<void> _openAdd({bool autoLocate = true}) async {
    final saved = await Navigator.of(context).push<Address>(
      smoothRoute<Address>(AddAddressScreen(autoLocate: autoLocate), name: '/add_address'),
    );
    if (!mounted) return;
    if (saved != null) {
      setState(() => _selectedAddress = saved);
      if (_inBookingFlow && !widget.isEditMode) {
        await _continue();
      }
    }
  }

  Future<void> _continue() async {
    final address = _selectedAddress;
    if (address == null) return;

    final booking = Provider.of<BookingProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);
    booking.setUserDefaultAddress(address);

    await user.saveAddressData(
      addressId: address.id,
      addressLine1: address.line1,
      addressLine2: address.line2,
      city: address.city,
      postcode: address.postalCode,
    );
    if (!mounted) return;

    if (widget.isEditMode) {
      Navigator.of(context).pop();
    } else if (_inBookingFlow) {
      Navigator.of(context).pushNamed('/contact_info', arguments: {'isFromBookingFlow': true});
    } else {
      Navigator.of(context).pushNamed('/service_selection');
    }
  }

  Future<void> _confirmDelete(Address a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1F5B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Remove address?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: Text(
          a.fullAddress,
          style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFFFF8A80)),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await Provider.of<BookingProvider>(context, listen: false).removeAddress(a.id);
      if (mounted && _selectedAddress?.id == a.id) {
        setState(() => _selectedAddress = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_redirecting) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        final addresses = provider.userAddresses;

        if (addresses.isEmpty && _inBookingFlow && !widget.isEditMode && !_autoOpenedAdd) {
          _autoOpenedAdd = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openAdd(autoLocate: true);
          });
        }

        final canContinue = _selectedAddress != null;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.bgGradient,
            ),
            child: Stack(
              children: [
                // Ambient top decorative circle
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
                // Ambient bottom decorative circle
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
                      // Header Bar
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
                              widget.isEditMode ? 'Your addresses' : 'Collection address',
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

                      // Content List
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
                                    // Hero Row with illustration badge
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Choose where we should collect from and deliver to.',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFDDE8FF),
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
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
                                    const SizedBox(height: 16),

                                    // Quick Action: Use my current location
                                    GestureDetector(
                                      onTap: () => _openAdd(autoLocate: true),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(26),
                                          color: Colors.white,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x8C02104C),
                                              blurRadius: 30,
                                              offset: Offset(0, 16),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF1553D6), Color(0xFF3B82F6)],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF1553D6).withValues(alpha: 0.35),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.my_location_rounded, color: Colors.white, size: 26),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Use my current location',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w800,
                                                      color: const Color(0xFF0B1F5B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'We fill in your address for you',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF5B6B9A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFFE6ECFB),
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.chevron_right_rounded, color: Color(0xFF0B1F5B), size: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 22),

                                    // Section Header: Saved addresses
                                    Row(
                                      children: [
                                        Text(
                                          'Saved addresses',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(999),
                                            color: const Color(0xFFFFC73A),
                                          ),
                                          child: Text(
                                            '${addresses.length}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0B1F5B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Addresses List
                                    if (addresses.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(24),
                                          color: Colors.white.withValues(alpha: 0.14),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          'No saved addresses yet.\nAdd one to book a collection.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.4,
                                          ),
                                        ),
                                      )
                                    else
                                      Column(
                                        children: addresses.map((addr) {
                                          final isSel = _selectedAddress?.id == addr.id;
                                          return _buildAddressCard(addr, isSel);
                                        }).toList(),
                                      ),

                                    const SizedBox(height: 14),

                                    // "Add a new address" button
                                    GestureDetector(
                                      onTap: () => _openAdd(autoLocate: false),
                                      child: Container(
                                        height: 58,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(22),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.55),
                                            width: 2,
                                            style: BorderStyle.solid,
                                          ),
                                          color: Colors.white.withValues(alpha: 0.1),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Add a new address',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Warning Box
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        color: const Color(0xFFFFC73A).withValues(alpha: 0.16),
                                        border: Border.all(
                                          color: const Color(0xFFFFC73A).withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline_rounded, color: Color(0xFFFFC73A), size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Changing the address might affect your selected services and time slots.',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                height: 1.4,
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
                          onTap: canContinue ? _continue : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: canContinue
                                  ? const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0xFFFFD25E), Color(0xFFFFB400)],
                                    )
                                  : null,
                              color: canContinue ? null : Colors.white.withValues(alpha: 0.2),
                              boxShadow: canContinue
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
                                  widget.isEditMode ? 'SAVE ADDRESS' : 'CONTINUE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: canContinue
                                        ? const Color(0xFF0B1F5B)
                                        : Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: canContinue
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
      },
    );
  }

  Widget _buildAddressCard(Address addr, bool isSelected) {
    // Label classification
    final labelLower = addr.line1.toLowerCase();
    IconData icon;
    LinearGradient tileGrad;

    if (labelLower.contains('work') || labelLower.contains('office')) {
      icon = Icons.work_outline_rounded;
      tileGrad = const LinearGradient(colors: [Color(0xFF0B6E64), Color(0xFF12876F)]);
    } else if (labelLower.contains('home')) {
      icon = Icons.home_rounded;
      tileGrad = const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6D4AFF)]);
    } else {
      icon = Icons.location_on_rounded;
      tileGrad = const LinearGradient(colors: [Color(0xFF1553D6), Color(0xFF3B82F6)]);
    }

    final title = addr.line1;
    final subtitle = [addr.line2, addr.city, addr.postalCode].where((e) => e != null && e.isNotEmpty).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedAddress = addr),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFEFEF8), Color(0xFFFFF7DD)],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFFFFC73A) : Colors.transparent,
              width: isSelected ? 3.5 : 0,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x8CFFB400),
                      blurRadius: 26,
                      offset: Offset(0, 14),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x6602104C),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // 52x52 Gradient Tile
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: tileGrad,
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.isNotEmpty ? subtitle : addr.fullAddress,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5B6B9A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xFFFFF1C7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, color: Color(0xFF7A5200), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Selected',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF7A5200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              GestureDetector(
                onTap: () => _confirmDelete(addr),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFEDEE),
                  ),
                  child: const Center(
                    child: Icon(Icons.delete_outline_rounded, color: Color(0xFFC22A3A), size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
