import 'dc_plus_logo_badge.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dryclean_city_scene.dart';

/// The exact signature animated Splash & Loader view from the DrycleanPlus design:
/// - Swinging clothes hanger
/// - Cursive "DrycleanPlus+" brand
/// - Wavy animated brush underline
/// - Twinkling star sparkles
/// - Cycling tag pill ("Collecting from your door", "Cleaning with care", "Pressing every crease")
/// - Animated expanding indicator dots
/// - Full-height city skyline, London Eye, double-decker bus, and animated DC+ delivery van.
class DrycleanSplashView extends StatefulWidget {
  final VoidCallback? onFinished;
  final bool autoCycle;
  final Duration cycleDuration;

  const DrycleanSplashView({
    super.key,
    this.onFinished,
    this.autoCycle = true,
    this.cycleDuration = const Duration(milliseconds: 1900),
  });

  @override
  State<DrycleanSplashView> createState() => _DrycleanSplashViewState();
}

class _DrycleanSplashViewState extends State<DrycleanSplashView>
    with TickerProviderStateMixin {
  int _tagIndex = 0;
  Timer? _tagTimer;

  static const List<String> _tags = [
    'Collecting from your door',
    'Cleaning with care',
    'Pressing every crease',
  ];

  late final AnimationController _swingController;
  late final AnimationController _waveController;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();

    // Hanger pendulum swing (3.4s loop, rotating between -2.4° and +2.4°)
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);

    // Wavy line drawing animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Sparkles twinkling
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    if (widget.autoCycle) {
      _startTagTimer();
    }
  }

  void _startTagTimer() {
    int count = 0;
    _tagTimer = Timer.periodic(widget.cycleDuration, (timer) {
      if (!mounted) return;
      count++;
      setState(() {
        _tagIndex = (_tagIndex + 1) % _tags.length;
      });

      // After cycling through all tags, notify onFinished if provided
      if (count >= _tags.length && widget.onFinished != null) {
        timer.cancel();
        widget.onFinished!();
      }
    });
  }

  @override
  void dispose() {
    _tagTimer?.cancel();
    _swingController.dispose();
    _waveController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Stack(
        children: [
          // City, Skyline, Bus & Van Scene in lower half
          const Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AspectRatio(
                aspectRatio: 300 / 330,
                child: DrycleanCityScene(mode: SceneDisplayMode.full),
              ),
            ),
          ),

          // Upper Section: Swinging Hanger, Brand, Tags & Dots
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Swinging Hanger & Cursive Logo ──────────────────────────
                AnimatedBuilder(
                  animation: _swingController,
                  builder: (context, child) {
                    final double angle = math.sin(_swingController.value * 2 * math.pi) * 0.042;
                    return Transform.rotate(
                      angle: angle,
                      alignment: const Alignment(0, -1),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hanger SVG Outline
                          SizedBox(
                            width: 150,
                            height: 54,
                            child: CustomPaint(
                              painter: _HangerPainter(),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Cursive "DrycleanPlus+" Brand Badge & Signature Logo
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const DCPlusLogoBadge(size: 38),
                                const SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.satisfy(
                                      fontSize: 32,
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
                                          fontSize: 34,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Animated Wavy Underline
                          SizedBox(
                            width: 290,
                            height: 24,
                            child: CustomPaint(
                              painter: _WavyLinePainter(),
                            ),
                          ),
                        ],
                      ),

                      // Twinkling Star Sparkles
                      Positioned(
                        right: 8,
                        top: 56,
                        child: _buildSparkle(22),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 0,
                        child: _buildSparkle(16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Cycling Tag Pill ─────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey<int>(_tagIndex),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _tags[_tagIndex],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE6EFFF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 3 Indicator Dots ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final bool isActive = (i == _tagIndex);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 30 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFD6E5FF)
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle(double size) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, _) {
        final double s = 0.7 + 0.3 * math.sin(_sparkleController.value * 2 * math.pi);
        return Transform.scale(
          scale: s,
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white.withValues(alpha: 0.85),
            size: size,
          ),
        );
      },
    );
  }
}

/// Custom painter for the silver hanger wire & hook
class _HangerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6EFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      // Top hook
      ..moveTo(size.width * 0.5, 27)
      ..lineTo(size.width * 0.5, 21)
      ..arcToPoint(
        Offset(size.width * 0.5 - 14, 14),
        radius: const Radius.circular(7),
        clockwise: false,
      )
      // Triangle body
      ..moveTo(size.width * 0.5, 27)
      ..lineTo(14, 51)
      ..lineTo(size.width - 14, 51)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the wavy brush line underneath DrycleanPlus+
class _WavyLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFFC4DBFF),
          Color(0xFF7CC4FF),
          Colors.transparent,
        ],
        stops: [0.0, 0.2, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(6, 16)
      ..cubicTo(58, 6, 98, 22, 148, 14)
      ..cubicTo(198, 6, 238, 6, 284, 11);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
