import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';
import '../widgets/dryclean_loader.dart';
import '../widgets/app_logo.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/guest_helper.dart';
import '../providers/user_provider.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;
  final AuthService _authService = AuthService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _checkExistingUser();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isGuest = prefs.getBool('is_guest') ?? false;

    if (isLoggedIn && !isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (Route<dynamic> route) => false,
          );
        }
      });
    }
  }

  void _navigateWithLoader(String route, {int durationMs = 1200, int loops = 3}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DrycleanLoader(durationMs: durationMs, loops: loops),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(route, (Route<dynamic> route) => false);
    });
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isGuestLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_displayName', 'Guest');
    await prefs.setBool('is_guest', true);
    await prefs.setBool('is_logged_in', true);
    if (mounted) _navigateWithLoader('/guest_prices'); // now 1.2s
    if (mounted) setState(() => _isGuestLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential.user != null && mounted) {
        await GuestHelper.setGuestStatus(false);
        final firestoreService = FirestoreService();
        await firestoreService.initializeUserData();
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserDataFromFirestore(userCredential.user!.uid);
        if (mounted) _navigateWithLoader('/home'); // now 1.2s
      } else if (mounted) {
        _showError('Sign in failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: const Color(0xFFB00020),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: Column(
          children: [
            // Hero content (no Stack wave)
            _HeroSection(),

            // Wave sits here — between hero and card
            CustomPaint(
              size: const Size(double.infinity, 42),
              painter: _WavePainter(),
            ),

            // Login card
            Expanded(child: _LoginCard()),
          ],
        ),
      ),
    );
  }

  Widget _HeroSection() {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.46, // Adjusted slightly for the wave
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background doodle icons (subtle)
          const _DoodleLayer(),

          // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // ── DC+ Logo Badge ──────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF071A09),
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          shape: const CustomOrganicBorder(),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'DC',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '+',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const AppLogo(
                          fontSize: 22,
                          secondaryColor: Colors.red),
                      const SizedBox(width: 6),
                      Icon(Icons.auto_awesome,
                          size: 13, color: Colors.yellow[300]),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Headline ────────────────────────────────
                Text(
                  'Premium Care,\nDelivered to You',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Professional dry cleaning & laundry\nat your doorstep — fast & reliable.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Feature Pills ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _FeaturePill(icon: Icons.flash_on_rounded, label: 'Express'),
                    SizedBox(width: 8),
                    _FeaturePill(icon: Icons.eco_rounded, label: 'Eco-Clean'),
                    SizedBox(width: 8),
                    _FeaturePill(
                        icon: Icons.verified_rounded, label: 'Guaranteed'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _LoginCard() {
    return Container(
      color: AppColors.primaryBlueDark,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in to continue',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Google Button ─────────────────────────
                _GoogleSignInButton(
                  isLoading: _isGoogleLoading,
                  onPressed: _signInWithGoogle,
                ),

                const SizedBox(height: 14),

                // ── OR Divider ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.1),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.1),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Guest Button ──────────────────────────
                _GuestButton(
                  isLoading: _isGuestLoading,
                  onPressed: _continueAsGuest,
                ),

                const Spacer(),

                // ── Legal Footer ──────────────────────────
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'By continuing you agree to our ',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.32),
                          fontSize: 11.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TermsConditionsScreen()),
                        ),
                        child: Text(
                          'Terms',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gold,
                          ),
                        ),
                      ),
                      Text(
                        ' & ',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.32),
                          fontSize: 11.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        ),
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gold,
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
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Feature Pill Widget
// ────────────────────────────────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Doodle Background (subtle, decluttered)
// ────────────────────────────────────────────────────────────────────────────
class _DoodleLayer extends StatelessWidget {
  const _DoodleLayer();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(children: [
        _d(Icons.dry_cleaning,           top: 44,  left: 10,  s: 20, o: 0.18),
        _d(Icons.checkroom,              top: 55,  left: 44,  s: 14, o: 0.11),
        _d(Icons.local_laundry_service,  top: 48,  right: 55, s: 18, o: 0.14),
        _d(Icons.dry_cleaning,           top: 50,  right: 18, s: 20, o: 0.16),
        _d(Icons.checkroom,              top: 80,  left: 22,  s: 16, o: 0.10),
        _d(Icons.local_laundry_service,  top: 90,  right: 30, s: 14, o: 0.10),
        _d(Icons.dry_cleaning,           top: 115, left: 58,  s: 12, o: 0.09),
        _d(Icons.checkroom,              top: 125, right: 65, s: 15, o: 0.09),
        _d(Icons.local_laundry_service,  top: 155, left: 14,  s: 14, o: 0.08),
        _d(Icons.dry_cleaning,           top: 162, right: 16, s: 16, o: 0.10),
      ]),
    );
  }

  Widget _d(IconData icon,
      {double? top, double? bottom, double? left, double? right,
      double s = 16, double o = 0.14}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Opacity(
        opacity: o,
        child: Icon(icon, size: s, color: Colors.white),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Professional Google Sign-In Button
// ────────────────────────────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton(
      {required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.grey.withOpacity(0.15),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                    ),
                  )
                else
                  SvgPicture.string(
                    '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                      <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                      <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                      <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
                      <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                    </svg>''',
                    width: 22,
                    height: 22,
                  ),
                const SizedBox(width: 12),
                Text(
                  isLoading ? 'Signing in...' : 'Continue with Google',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ────────────────────────────────────────────────────────────────────────────
// Guest Button
// ────────────────────────────────────────────────────────────────────────────
class _GuestButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GuestButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                )
              else
                Icon(Icons.person_outline_rounded,
                    color: Colors.white.withOpacity(0.6), size: 20),
              const SizedBox(width: 12),
              Text(
                isLoading ? 'Loading...' : 'Continue as Guest',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Professional Wave Painter (clean S-curve, single smooth wave)
// ────────────────────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlueDark
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * 0.00, size.height * 0.28,  // ctrl-1: left anchor up
        size.width * 0.38, size.height * 0.00,  // ctrl-2: center dip
        size.width * 0.50, size.height * 0.22,  // mid-peak
      )
      ..cubicTo(
        size.width * 0.62, size.height * 0.44,  // ctrl-1: right rise
        size.width * 1.00, size.height * 0.06,  // ctrl-2: right anchor
        size.width * 1.00, size.height * 0.00,  // end top-right
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ────────────────────────────────────────────────────────────────────────────
// Custom Organic Border (unchanged from original)
// ────────────────────────────────────────────────────────────────────────────
class CustomOrganicBorder extends ShapeBorder {
  const CustomOrganicBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.elliptical(rect.width * 0.3, rect.height * 0.3),
        topRight: Radius.elliptical(rect.width * 0.7, rect.height * 0.3),
        bottomRight: Radius.elliptical(rect.width * 0.7, rect.height * 0.7),
        bottomLeft: Radius.elliptical(rect.width * 0.3, rect.height * 0.7),
      ));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(getOuterPath(rect), paint);
  }

  @override
  ShapeBorder scale(double t) => const CustomOrganicBorder();
}