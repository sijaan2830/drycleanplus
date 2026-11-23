import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/dryclean_city_scene.dart';
import '../widgets/dryclean_splash_view.dart';
import '../widgets/dryclean_loader.dart';
import '../widgets/dc_plus_logo_badge.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/guest_helper.dart';
import '../utils/route_helpers.dart';
import '../providers/user_provider.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

/// DrycleanPlus Customer Onboarding Screen matching the exact DrycleanPlus Onboarding design:
///
/// 1. Splash Stage:
///    - Swinging silver hanger
///    - Cursive "DrycleanPlus+" brand with glowing underline wave & sparkles
///    - Cycling tag pill ("Collecting from your door", "Cleaning with care", "Pressing every crease")
///    - Indicator dots
///    - Full London skyline, London Eye, double-decker bus, and animated DC+ delivery van.
///    - Tap anywhere or auto-transition after cycles to the Login Stage.
///
/// 2. Login Stage:
///    - Frosted glass brand pill with official DC+ pick badge
///    - Full animated city & van scene band (uncovered, vibrant, crisp)
///    - Compact white card at the bottom with Google & Guest sign-in
///    - Interactive van drive-out on sign-in
///    - Full-screen signature DrycleanLoader shown after sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  bool _isSplash = true;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isGuestLoading = false;
  bool _vanDriveOut = false;

  final AuthService _authService = AuthService();

  late final AnimationController _shimmerController;
  late final AnimationController _loginFadeController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _loginFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkExistingUser();

    // Custom splash screen (city scene with van & animated tags) auto-transitions after all tags complete (~4.4 seconds)
    Future.delayed(const Duration(milliseconds: 4400), () {
      if (mounted && _isSplash) {
        _transitionToLogin();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _loginFadeController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isGuest = prefs.getBool('is_guest') ?? false;

    if (isLoggedIn && !isGuest && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (Route<dynamic> route) => false,
      );
    }
  }

  void _transitionToLogin() {
    if (!_isSplash) return;
    setState(() => _isSplash = false);
    _loginFadeController.forward();
  }

  void _navigateWithLoader(String route, {int durationMs = 1800, int loops = 2}) {
    RouteNotifier().endLogout();
    Navigator.of(context).push(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/loader'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DrycleanLoader(durationMs: durationMs, loops: loops),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    ).then((_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (Route<dynamic> route) => false);
      }
    });
  }

  Future<void> _continueAsGuest() async {
    if (_isGuestLoading || _isGoogleLoading) return;
    setState(() {
      _isGuestLoading = true;
      _vanDriveOut = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_displayName', 'Guest');
    await prefs.setBool('is_guest', true);
    await prefs.setBool('is_logged_in', true);
    await GuestHelper.setGuestStatus(true);

    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      _navigateWithLoader('/home', durationMs: 1200, loops: 1);
    }
    if (mounted) setState(() => _isGuestLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading || _isGuestLoading) return;
    setState(() {
      _isGoogleLoading = true;
      _vanDriveOut = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && userCredential.user != null && mounted) {
        await GuestHelper.setGuestStatus(false);
        final firestoreService = FirestoreService();
        await firestoreService.initializeUserData();
        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserDataFromFirestore(userCredential.user!.uid);

        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) {
          _navigateWithLoader('/home', durationMs: 1800, loops: 2);
        }
      } else if (mounted) {
        setState(() => _vanDriveOut = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _vanDriveOut = false);
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    if (_isAppleLoading || _isGoogleLoading || _isGuestLoading) return;
    setState(() {
      _isAppleLoading = true;
      _vanDriveOut = true;
    });

    try {
      final userCredential = await _authService.signInWithApple();
      if (userCredential != null && userCredential.user != null && mounted) {
        await GuestHelper.setGuestStatus(false);
        final firestoreService = FirestoreService();
        await firestoreService.initializeUserData();
        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserDataFromFirestore(userCredential.user!.uid);

        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) {
          _navigateWithLoader('/home', durationMs: 1800, loops: 2);
        }
      } else if (mounted) {
        setState(() => _vanDriveOut = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _vanDriveOut = false);
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white)),
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
        backgroundColor: const Color(0xFF1546C0),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isSplash
              ? GestureDetector(
                  onTap: _transitionToLogin,
                  child: DrycleanSplashView(
                    key: const ValueKey('splash_view'),
                    autoCycle: true,
                    cycleDuration: const Duration(milliseconds: 1400),
                    onFinished: _transitionToLogin,
                  ),
                )
              : _buildLoginScreen(),
        ),
      ),
    );
  }

  // ── Login Screen ──────────────────────────────────────────────────────────

  Widget _buildLoginScreen() {
    return Container(
      key: const ValueKey('login_view'),
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2D82F7),
            Color(0xFF1C5FE6),
            Color(0xFF1546C0),
          ],
          stops: [0.0, 0.42, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Top Frosted Glass Brand Pill
                      _buildBrandPill(),
                      const SizedBox(height: 4),

                      // Full animated city scene with van & flag (uncovered, plenty of room)
                      Expanded(
                        child: ClipRect(
                          child: DrycleanCityScene(
                            mode: SceneDisplayMode.band,
                            animateDriveOut: _vanDriveOut,
                          ),
                        ),
                      ),

                      // 3 Feature Chips
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildFeatureChip(Icons.local_shipping_rounded, 'Doorstep collection'),
                            _buildFeatureChip(Icons.bolt_rounded, 'Fast turnaround'),
                            _buildFeatureChip(Icons.verified_rounded, 'Careful cleaning'),
                          ],
                        ),
                      ),

                      // Bottom White Sign-in Sheet (compact size, taking minimal space)
                      _buildBottomSheet(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Brand Pill (.lpill) ───────────────────────────────────────────────────

  Widget _buildBrandPill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DCPlusLogoBadge(size: 38),
          const SizedBox(width: 8),

          // Cursive Logo matching Home screen last card
          RichText(
            text: TextSpan(
              style: GoogleFonts.satisfy(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
              children: const [
                TextSpan(
                  text: 'Dryclean',
                  style: TextStyle(
                    color: Color(0xFF042407), // Home card dark green
                  ),
                ),
                TextSpan(
                  text: 'Plus',
                  style: TextStyle(
                    color: Color(0xFFE5262D), // Home card red
                  ),
                ),
                TextSpan(
                  text: '+',
                  style: TextStyle(
                    color: Color(0xFFE5262D),
                    fontWeight: FontWeight.w900,
                    fontSize: 27,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFD75E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact White Bottom Sheet ────────────────────────────────────────────

  Widget _buildBottomSheet() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        18 + (bottomInset > 10 ? bottomInset - 4 : bottomInset),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x280A2A70),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gray handle
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE4EAF5),
              borderRadius: BorderRadius.circular(9),
            ),
          ),

          // Title
          Text(
            "Let's get started",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24.0,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF14213D),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            'Sign in to book and track your orders',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6F7D96),
            ),
          ),
          const SizedBox(height: 18),

          // Continue with Google Button (.gb)
          _buildGoogleButton(),
          const SizedBox(height: 12),

          // Optional Apple Button (on iOS or if supported)
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            _buildAppleButton(),
            const SizedBox(height: 12),
          ],

          // "or" divider (.orl)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: const Color(0xFFE4EAF5))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6F7D96),
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: const Color(0xFFE4EAF5))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Continue as guest Button (.gs)
          _buildGuestButton(),
          const SizedBox(height: 16),

          // Terms & Privacy Policy
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6F7D96),
                height: 1.45,
              ),
              children: [
                const TextSpan(text: 'By continuing you agree to our '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                      );
                    },
                    child: Text(
                      'Terms',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1550E8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' & '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      );
                    },
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1550E8),
                        decoration: TextDecoration.underline,
                      ),
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

  // ── Google Button (.gb) ───────────────────────────────────────────────────

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _signInWithGoogle,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE4EAF5), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180A2A70),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Google 'G' Icon in soft circle
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F0FF),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _GoogleLogoPainter(),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Continue with Google',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF14213D),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1550E8)),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF6F7D96),
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Apple Button ──────────────────────────────────────────────────────────

  Widget _buildAppleButton() {
    return GestureDetector(
      onTap: _isAppleLoading ? null : _signInWithApple,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const Center(
                child: Icon(Icons.apple, color: Colors.white, size: 22),
              ),
            ),
            Expanded(
              child: Text(
                'Continue with Apple',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: _isAppleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Guest Button (.gs) ────────────────────────────────────────────────────

  Widget _buildGuestButton() {
    return GestureDetector(
      onTap: _isGuestLoading ? null : _continueAsGuest,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5AA4FF), Color(0xFF1352D6)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1352D6).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              child: const Center(
                child: Icon(Icons.explore_outlined, color: Colors.white, size: 22),
              ),
            ),
            Expanded(
              child: Text(
                'Continue as guest',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: _isGuestLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Official 4-color Google 'G' vector painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48.0, size.height / 48.0);

    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
      ..lineTo(24, 20)
      ..lineTo(24, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
      ..cubicTo(9.77, 22.4, 10.05, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
      ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
