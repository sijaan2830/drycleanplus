import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dryclean_loader.dart';
import '../widgets/persistent_footer_app.dart';
import '../widgets/app_ui.dart';
import '../utils/route_helpers.dart';
import '../providers/booking_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../utils/guest_helper.dart';
import 'booking/address_selection_screen.dart';
import 'booking/contact_info_screen.dart';

/// Account Screen matching the compact, proportional Account_(1).html mockup.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/more');
    }
  }

  String _initials(String first, String last) {
    final a = first.trim().isNotEmpty ? first.trim()[0] : '';
    final b = last.trim().isNotEmpty ? last.trim()[0] : '';
    final s = (a + b).toUpperCase();
    return s.isEmpty ? 'U' : s;
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
              child: Column(
                children: [
                  // App Bar (40px glass back button, 18px bold title, 40px spacer)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _goBack,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
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
                        Text(
                          'Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: Consumer2<BookingProvider, UserProvider>(
                      builder: (context, booking, user, _) {
                        final fullName = '${user.firstName} ${user.lastName}'.trim();
                        final displayName = fullName.isNotEmpty ? fullName : 'Shajedur Rashid';
                        final initials = _initials(user.firstName, user.lastName);
                        final email = user.email.isNotEmpty ? user.email : 'shajedurrashid87@gmail.com';
                        final phone = user.phone.isNotEmpty ? user.phone : '07700 900123';

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Profile Glass Card (.me)
                                  _buildProfileHeader(displayName, email, initials),
                                  const SizedBox(height: 12),

                                  // Address Card (.cd)
                                  _buildAddressCard(booking),
                                  const SizedBox(height: 12),

                                  // Contact Details Card (.cd with .g2)
                                  _buildContactCard(user, phone, email),
                                  const SizedBox(height: 12),

                                  // Country Card (.cd with UK flag)
                                  _buildCountryCard(),
                                  const SizedBox(height: 20),

                                  // Log Out Pill Button (.lo)
                                  _buildLogoutButton(email),
                                  const SizedBox(height: 6),

                                  // Delete Account Button (.dl)
                                  _buildDeleteAccountButton(email),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  // ── Profile Glass Card (.me) ──────────────────────────────────────────────

  Widget _buildProfileHeader(String name, String email, String initials) {
    return Container(
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
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          // 68x68 Conic gold gradient avatar (.av)
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: const Color(0xFF02104C).withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: const SweepGradient(
                colors: [
                  Color(0xFFFFE9A3),
                  Color(0xFFFFB400),
                  Color(0xFFFFF3C4),
                  Color(0xFFFFB400),
                  Color(0xFFFFE9A3),
                ],
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFD6E4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1553D6),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDDE8FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Address Card (.cd) ────────────────────────────────────────────────────

  Widget _buildAddressCard(BookingProvider booking) {
    final address = booking.userDefaultAddress;
    final title = (address?.buildingName != null && address!.buildingName!.isNotEmpty)
        ? address.buildingName!
        : 'Home';
    final fullDisplay = address != null && address.fullAddress.isNotEmpty
        ? address.fullAddress
        : 'Add your address to get started';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1F5B),
                  letterSpacing: -0.2,
                ),
              ),
              _buildEditButton(
                onTap: () {
                  Navigator.of(context)
                      .push(smoothRoute(const AddressSelectionScreen(isEditMode: true), name: '/address_selection'))
                      .then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address Row (.fd)
          Row(
            children: [
              _buildTile(Icons.location_on_rounded, const Color(0xFFD6336C), const Color(0xFFFF6B8B)),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5B6B9A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      fullDisplay,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contact Details Card (.cd with .g2) ───────────────────────────────────

  Widget _buildContactCard(UserProvider user, String phone, String email) {
    final firstName = user.firstName.isNotEmpty ? user.firstName : 'Shajedur';
    final lastName = user.lastName.isNotEmpty ? user.lastName : 'Rashid';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1F5B),
                  letterSpacing: -0.2,
                ),
              ),
              _buildEditButton(
                onTap: () {
                  Navigator.of(context)
                      .push(smoothRoute(const ContactInfoScreen(isEditMode: true), name: '/contact_info'))
                      .then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-column grid (.g2) for First Name and Last Name
          Row(
            children: [
              Expanded(
                child: _buildFieldItem(
                  icon: Icons.person_rounded,
                  label: 'First name',
                  value: firstName,
                  colorA: const Color(0xFF4338CA),
                  colorB: const Color(0xFF6D4AFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFieldItem(
                  icon: Icons.badge_rounded,
                  label: 'Last name',
                  value: lastName,
                  colorA: const Color(0xFF1553D6),
                  colorB: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mobile Number Row
          _buildFieldItem(
            icon: Icons.phone_rounded,
            label: 'Mobile number',
            value: phone,
            colorA: const Color(0xFF0B6E64),
            colorB: const Color(0xFF12A38A),
          ),
          const SizedBox(height: 12),

          // Email Row
          _buildFieldItem(
            icon: Icons.email_rounded,
            label: 'Email',
            value: email,
            colorA: const Color(0xFFE26A00),
            colorB: const Color(0xFFFFB400),
          ),
        ],
      ),
    );
  }

  // ── Field Item (.fd) ──────────────────────────────────────────────────────

  Widget _buildFieldItem({
    required IconData icon,
    required String label,
    required String value,
    required Color colorA,
    required Color colorB,
  }) {
    return Row(
      children: [
        _buildTile(icon, colorA, colorB),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B6B9A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1F5B),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Country Card (.cd with flag) ──────────────────────────────────────────

  Widget _buildCountryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flag (44x31, rounded 8px)
          Container(
            width: 44,
            height: 31,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF02104C).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: const CustomPaint(painter: UKFlagPainter()),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Country',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B6B9A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'United Kingdom',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1F5B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Edit Button (.ed) ─────────────────────────────────────────────────────

  Widget _buildEditButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.fromLTRB(11, 0, 14, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF1553D6)),
            const SizedBox(width: 6),
            Text(
              'Edit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1553D6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient Icon Tile (.tile) ────────────────────────────────────────────

  Widget _buildTile(IconData icon, Color colorA, Color colorB) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [colorA, colorB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorA.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── Log Out Button (.lo) ──────────────────────────────────────────────────

  Widget _buildLogoutButton(String email) {
    return GestureDetector(
      onTap: () => _showConfirmationSheet(
        title: 'Log out?',
        message: 'You can log back in any time with your email.',
        actionLabel: 'Log out',
        cancelLabel: 'Cancel',
        colorA: const Color(0xFF1553D6),
        colorB: const Color(0xFF3B82F6),
        confirmGradient: const [Color(0xFF1553D6), Color(0xFF4F46E5)],
        icon: Icons.logout_rounded,
        onConfirm: _logout,
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'LOG OUT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Account Button (.dl) ───────────────────────────────────────────

  Widget _buildDeleteAccountButton(String email) {
    return GestureDetector(
      onTap: () => _showConfirmationSheet(
        title: 'Delete your account?',
        message: 'This permanently removes your details and order history. This cannot be undone.',
        actionLabel: 'Delete',
        cancelLabel: 'Cancel',
        colorA: const Color(0xFFD92D4A),
        colorB: const Color(0xFFF0566E),
        confirmGradient: const [Color(0xFFD92D4A), Color(0xFFF0566E)],
        icon: Icons.warning_amber_rounded,
        onConfirm: _deleteAccount,
      ),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFFFB3BC), size: 18),
            const SizedBox(width: 8),
            Text(
              'Delete account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFB3BC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom-Sheet Confirmation Dialog (.ov .sh) ────────────────────────────

  void _showConfirmationSheet({
    required String title,
    required String message,
    required String actionLabel,
    required String cancelLabel,
    required Color colorA,
    required Color colorB,
    required List<Color> confirmGradient,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle (.hn)
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DEF2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Themed 58x58 tile (.sh .tile)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [colorA, colorB],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorA.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 12),

              // Title (.sh h2)
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1F5B),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle (.sh p)
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B6B9A),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // 2-column buttons (.sb)
              Row(
                children: [
                  // Cancel button (.cn)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text(
                            cancelLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1F5B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Confirm button (.go)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: confirmGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: confirmGradient.first.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            actionLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Logout & Delete Account Logic ─────────────────────────────────────────

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    // 1. Immediately hide footer so it never flashes or remains visible during splash loader
    RouteNotifier().startLogout();
    persistentFooterAppState?.resetToHomeTab();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DrycleanLoader(autoDismiss: false),
    );
    final minShow = Future.delayed(const Duration(milliseconds: 1200));

    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    await GuestHelper.setGuestStatus(false);
    await userProvider.clearUserData();
    bookingProvider.clearBookingData();
    await _clearAdditionalUserData();

    await minShow;
    nav.pop();
    nav.pushNamedAndRemoveUntil('/onboarding', (route) => false);
  }

  Future<void> _deleteAccount() async {
    final nav = Navigator.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    // 1. Immediately hide footer
    RouteNotifier().startLogout();
    persistentFooterAppState?.resetToHomeTab();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DrycleanLoader(autoDismiss: false),
    );
    final minShow = Future.delayed(const Duration(milliseconds: 1200));

    try {
      await _authService.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      nav.pop();
      RouteNotifier().endLogout();
      RouteNotifier().updateRoute('/account');
      if (!mounted) return;
      showAppSnack(
        context,
        e.code == 'requires-recent-login'
            ? 'For security, please log out, sign in again, then delete your account.'
            : 'Could not delete your account. Please try again.',
        error: true,
      );
      return;
    } catch (e) {
      nav.pop();
      RouteNotifier().endLogout();
      RouteNotifier().updateRoute('/account');
      if (!mounted) return;
      showAppSnack(context, 'Could not delete your account. Please try again.', error: true);
      return;
    }

    try {
      await _authService.signOut();
    } catch (_) {}
    await GuestHelper.setGuestStatus(false);
    await userProvider.clearUserData();
    bookingProvider.clearBookingData();
    await _clearAdditionalUserData();

    await minShow;
    nav.pop();
    nav.pushNamedAndRemoveUntil('/onboarding', (route) => false);
  }

  Future<void> _clearAdditionalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_displayName');
      await prefs.remove('is_guest');
      await prefs.remove('is_logged_in');
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('session_start_time');
      await prefs.remove('last_active_time');
    } catch (e) {
      debugPrint('Error clearing additional user data: $e');
    }
  }
}

/// Custom painter for the UK flag matching SVG specifications in Account_(1).html.
class UKFlagPainter extends CustomPainter {
  const UKFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;

    // Background Blue (#012169)
    paint.color = const Color(0xFF012169);
    canvas.drawRect(rect, paint);

    // White Diagonals
    paint.color = Colors.white;
    paint.strokeWidth = size.height * 0.2;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Red Diagonals (#C8102E)
    paint.color = const Color(0xFFC8102E);
    paint.strokeWidth = size.height * 0.12;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // White Cross
    paint.color = Colors.white;
    paint.strokeWidth = size.height * 0.3;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Red Cross (#C8102E)
    paint.color = const Color(0xFFC8102E);
    paint.strokeWidth = size.height * 0.18;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
