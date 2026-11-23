import 'dc_plus_logo_badge.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dryclean_city_scene.dart';

/// The exact signature animated Splash & Loader view from the DrycleanPlus design:
/// - Swinging clothes hanger
/// - Cursive "DrycleanPlus+" brand written with an animated pen outline,
///   followed by rich signature green & red color filling in
/// - Fixed white pill badge container
/// - Wavy animated brush underline
/// - Twinkling star sparkles
/// - Cycling tag pill ("Collecting from your door", "Cleaning with care", "Pressing every crease")
/// - Animated expanding indicator dots
/// - Full-height city skyline, London Eye, double-decker bus, and animated DC+ delivery van.
/// - Completely overflow-safe on all phone sizes and orientations.
class DrycleanSplashView extends StatefulWidget {
  final VoidCallback? onFinished;
  final bool autoCycle;
  final Duration cycleDuration;

  const DrycleanSplashView({
    super.key,
    this.onFinished,
    this.autoCycle = true,
    this.cycleDuration = const Duration(milliseconds: 1400),
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
  late final AnimationController _signatureController;

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

    // Signature pen writing & color-fill animation (repeating continuous loop)
    _signatureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
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
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenH = mediaQuery.size.height;

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
          // City, Skyline, Bus & Van Scene in lower section (isolated GPU layer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: math.min(screenH * 0.62, 530.0),
            child: const RepaintBoundary(
              child: ClipRect(
                child: DrycleanCityScene(mode: SceneDisplayMode.full),
              ),
            ),
          ),

          // Upper Section: Swinging Hanger, Brand, Tags & Dots (isolated GPU layer)
          SafeArea(
            child: RepaintBoundary(
              child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isShort = constraints.maxHeight < 680;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: isShort ? 12 : 24),

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

                                    // Cursive "DrycleanPlus+" Brand Badge & Signature Logo (Rock-solid fixed white card)
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

                                          // Signature pen stroke & color-fill animation
                                          _SignatureBrandLogo(
                                            animation: _signatureController,
                                            fontSize: 30,
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
                          SizedBox(height: isShort ? 10 : 18),

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
                          SizedBox(height: isShort ? 10 : 16),

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
                  ),
                );
              },
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Signature Brand Logo with Pen Outline & Color Fill
// ─────────────────────────────────────────────────────────────────────────────

class _SignatureBrandLogo extends StatelessWidget {
  final Animation<double> animation;
  final double fontSize;

  const _SignatureBrandLogo({
    required this.animation,
    this.fontSize = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    // 220px width ensures "DrycleanPlus +" has plenty of room and never truncates or wraps the plus sign
    const double textWidth = 220.0;
    const double textHeight = 44.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double t = animation.value;

        // Loop phase transitions:
        // 0.00 -> 0.52: Pen writes outline
        // 0.36 -> 0.68: Color fill floods in
        // 0.68 -> 0.88: Completed vibrant logo displays & rests
        // 0.88 -> 1.00: Gentle fade to loop seamlessly
        final double loopFade = t > 0.88 ? ((1.0 - t) / 0.12).clamp(0.0, 1.0) : 1.0;

        // Stage 1: Outline stroke drawn by pen (0.00 -> 0.52)
        final double strokeProgress = (t / 0.52).clamp(0.0, 1.0);
        final double strokeCurved = Curves.easeInOutCubic.transform(strokeProgress);

        // Stage 2: Color fill flooding in (0.36 -> 0.68)
        final double fillProgress = ((t - 0.36) / 0.32).clamp(0.0, 1.0);
        final double fillCurved = Curves.easeInOutCubic.transform(fillProgress);

        // Pen position along the cursive baseline ending right at the plus icon
        final double penX = (textWidth * strokeCurved) - 2.0;
        final double penY = 17.0 + math.sin(strokeCurved * 8.0 * math.pi) * 3.5;

        // Pen opacity: visible while writing, fades out cleanly as plus icon completes (0.50 -> 0.58)
        final double penOpacity = strokeProgress < 1.0
            ? (t < 0.02 ? (t / 0.02) : 1.0)
            : (1.0 - ((t - 0.50) / 0.08)).clamp(0.0, 1.0);

        final Color currentPenColor = strokeCurved < 0.56
            ? const Color(0xFF042407) // Deep signature green for "Dryclean"
            : const Color(0xFFE5262D); // Brand vibrant red for "Plus+"

        return Opacity(
          opacity: loopFade,
          child: SizedBox(
          width: textWidth,
          height: textHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Hollow Outline Layer (Stroke drawn like a pen)
              if (strokeProgress > 0)
                ClipRect(
                  clipper: _SignatureClipper(strokeCurved),
                  child: RichText(
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    text: TextSpan(
                      style: GoogleFonts.satisfy(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                      children: [
                        TextSpan(
                          text: 'Dryclean',
                          style: TextStyle(
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 1.4
                              ..strokeCap = StrokeCap.round
                              ..strokeJoin = StrokeJoin.round
                              ..color = const Color(0xFF042407),
                          ),
                        ),
                        TextSpan(
                          text: 'Plus',
                          style: TextStyle(
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 1.4
                              ..strokeCap = StrokeCap.round
                              ..strokeJoin = StrokeJoin.round
                              ..color = const Color(0xFFE5262D),
                          ),
                        ),
                        TextSpan(
                          text: ' +',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: fontSize * 0.95,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.normal,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2.0
                              ..strokeCap = StrokeCap.round
                              ..strokeJoin = StrokeJoin.round
                              ..color = const Color(0xFFE5262D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Solid Fill Layer (Sobuj & Lal rong bhore jay)
              if (fillProgress > 0)
                Opacity(
                  opacity: fillCurved,
                  child: ClipRect(
                    clipper: _SignatureClipper(fillCurved),
                    child: RichText(
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      text: TextSpan(
                        style: GoogleFonts.satisfy(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Dryclean',
                            style: TextStyle(
                              color: Color(0xFF042407), // Deep signature green
                            ),
                          ),
                          const TextSpan(
                            text: 'Plus',
                            style: TextStyle(
                              color: Color(0xFFE5262D), // Vibrant brand red
                            ),
                          ),
                          TextSpan(
                            text: ' +',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFE5262D),
                              fontWeight: FontWeight.w900,
                              fontSize: fontSize * 0.95,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Animated Pen Nib / Stylus following the stroke
              if (penOpacity > 0 && strokeProgress > 0.02)
                Positioned(
                  left: (penX - 8.0).clamp(-4.0, textWidth + 6.0),
                  top: penY - 14.0,
                  child: Opacity(
                    opacity: penOpacity,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Pen Icon angled at 45 deg
                        Transform.rotate(
                          angle: -math.pi / 4,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 17,
                            color: currentPenColor,
                          ),
                        ),
                        // Ink sparkle at pen tip
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentPenColor,
                              boxShadow: [
                                BoxShadow(
                                  color: currentPenColor.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}

class _SignatureClipper extends CustomClipper<Rect> {
  final double progress;
  _SignatureClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final double maxW = size.width + 16.0;
    return Rect.fromLTWH(0, -6, maxW * progress.clamp(0.0, 1.0), size.height + 12);
  }

  @override
  bool shouldReclip(_SignatureClipper oldClipper) => oldClipper.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

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
