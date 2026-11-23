import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SceneDisplayMode {
  full, // Full 390x330 view used in splash screen
  band, // 390x220 banner band used in onboarding login view
}

/// Highly optimized, 60fps native Flutter rendering of the DrycleanPlus
/// city, London skyline, London Eye, double-decker bus, and delivery van scene.
class DrycleanCityScene extends StatefulWidget {
  final SceneDisplayMode mode;
  final bool animateDriveOut; // when true, van drives forward off-screen; on cancel, enters forward from the rear

  const DrycleanCityScene({
    super.key,
    this.mode = SceneDisplayMode.full,
    this.animateDriveOut = false,
  });

  @override
  State<DrycleanCityScene> createState() => _DrycleanCitySceneState();
}

class _DrycleanCitySceneState extends State<DrycleanCityScene>
    with TickerProviderStateMixin {
  late final AnimationController _farController;
  late final AnimationController _midController;
  late final AnimationController _foreController;
  late final AnimationController _dashController;
  late final AnimationController _wheelController;
  late final AnimationController _busController;
  late final AnimationController _bobController;
  late final AnimationController _driftController;
  late final AnimationController _eyeController;
  late final AnimationController _driveOutController;
  late final AnimationController _driveInController;

  @override
  void initState() {
    super.initState();

    // Far skyline parallax (34s loop)
    _farController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 34),
    )..repeat();

    // Mid skyline parallax (6.5s loop)
    _midController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )..repeat();

    // Foreground parallax (2.6s loop)
    _foreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // Center road dash (360ms loop)
    _dashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..repeat();

    // Wheels rotating (420ms loop)
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat();

    // Red bus passing (9s loop)
    _busController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    // Van vertical bobbing (650ms alternate, soft and gentle)
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    // Van horizontal drift (4.6s alternate)
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat(reverse: true);

    // London Eye ferris wheel continuous rotation (70s loop)
    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
    )..repeat();

    // Drive out exit animation (950ms)
    _driveOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // Drive in entrance from rear on cancel (950ms)
    _driveInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant DrycleanCityScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateDriveOut && !oldWidget.animateDriveOut) {
      _driveInController.value = 1.0;
      _driveOutController.forward(from: 0.0);
    } else if (!widget.animateDriveOut && oldWidget.animateDriveOut) {
      // On cancel, van enters forward from the rear/left
      _driveOutController.value = 0.0;
      _driveInController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _farController.dispose();
    _midController.dispose();
    _foreController.dispose();
    _dashController.dispose();
    _wheelController.dispose();
    _busController.dispose();
    _bobController.dispose();
    _driftController.dispose();
    _eyeController.dispose();
    _driveOutController.dispose();
    _driveInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _farController,
        _midController,
        _foreController,
        _dashController,
        _wheelController,
        _busController,
        _bobController,
        _driftController,
        _eyeController,
        _driveOutController,
        _driveInController,
      ]),
      builder: (context, _) {
        final double farT = _farController.value;
        final double midT = _midController.value;
        final double foreT = _foreController.value;
        final double dashT = _dashController.value;
        final double wheelAngle = _wheelController.value * 2.0 * math.pi;
        final double busT = _busController.value;
        final double bobY = (math.sin(_bobController.value * math.pi) * 0.85);
        final double driftX = (math.sin(_driftController.value * math.pi) * 8.0);
        final double eyeAngle = _eyeController.value * 2.0 * math.pi;

        double vanAnimX = 0.0;
        if (_driveOutController.isAnimating || _driveOutController.value > 0) {
          vanAnimX = Curves.easeInCubic.transform(_driveOutController.value) * 600.0;
        } else if (_driveInController.isAnimating || _driveInController.value < 1.0) {
          vanAnimX = (1.0 - Curves.easeOutCubic.transform(_driveInController.value)) * -400.0;
        }

        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _CityScenePainter(
              mode: widget.mode,
              farT: farT,
              midT: midT,
              foreT: foreT,
              dashT: dashT,
              wheelAngle: wheelAngle,
              busT: busT,
              bobY: bobY,
              driftX: driftX,
              eyeAngle: eyeAngle,
              vanAnimX: vanAnimX,
              isVanSpeeding: _driveOutController.isAnimating,
            ),
          ),
        );
      },
    );
  }
}

class _CityScenePainter extends CustomPainter {
  final SceneDisplayMode mode;
  final double farT;
  final double midT;
  final double foreT;
  final double dashT;
  final double wheelAngle;
  final double busT;
  final double bobY;
  final double driftX;
  final double eyeAngle;
  final double vanAnimX;
  final bool isVanSpeeding;

  _CityScenePainter({
    required this.mode,
    required this.farT,
    required this.midT,
    required this.foreT,
    required this.dashT,
    required this.wheelAngle,
    required this.busT,
    required this.bobY,
    required this.driftX,
    required this.eyeAngle,
    required this.vanAnimX,
    required this.isVanSpeeding,
  });

  static const double viewW = 390.0;
  static const double groundY = 386.0;
  static const double curbY = 398.0;
  static const double roadEndY = 504.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (mode == SceneDisplayMode.full) {
      // Dedicated Splash Screen view matching HTML splash spec:
      // Aspect ratio 310/330, viewBox: 20 190 310 330 with preserveAspectRatio="xMidYMax slice"
      // Big, tall, grand city scene with London Eye, Big Ben & DC+ Shopfront.
      const double vw = 310.0;
      const double vh = 330.0;
      final double sx = size.width / vw;
      final double sy = size.height / vh;
      final double s = math.max(sx, sy);
      canvas.scale(s, s);

      final double dx = 20.0 - (size.width / s - vw) / 2.0;
      final double dy = 520.0 - (size.height / s);
      canvas.translate(-dx, -dy);
    } else {
      // Dedicated Onboarding band view (viewBox: 0 300 390 220 docked to bottom)
      final double s = size.width / 390.0;
      final double dx = (size.width - 390.0 * s) / 2.0;
      final double dy = size.height - (520.0 * s);
      canvas.translate(dx, dy);
      canvas.scale(s, s);
    }

    // 1. Twinkling Stars
    _drawStars(canvas);

    // 2. Far Skyline & London Eye (repeating parallax)
    _drawFarSkyline(canvas);

    // 3. Mid Skyline & DC+ Shopfront (repeating parallax)
    _drawMidSkyline(canvas);

    // 4. Ground, Curbs & Road
    _drawRoadAndPavement(canvas);

    // 5. Red Double-Decker London Bus
    _drawBus(canvas);

    // 6. Animated DC+ Delivery Van with Waving Flag
    _drawVan(canvas);

    // 7. Foreground Lampposts & Red Pillar Box (on bottom curb roadEndY + 4)
    _drawForeground(canvas);

    canvas.restore();
  }

  void _drawStars(Canvas canvas) {
    final paint = Paint()..color = Colors.white;
    const stars = [
      [74.0, 214.0, 0.8, 0.0],
      [300.0, 232.0, 1.0, 0.6],
      [168.0, 206.0, 0.6, 1.2],
      [322.0, 300.0, 0.7, 1.8],
      [62.0, 296.0, 0.6, 0.9],
      [216.0, 262.0, 0.5, 1.5],
    ];

    for (final s in stars) {
      final double x = s[0];
      final double y = s[1];
      final double r = s[2];
      canvas.drawCircle(Offset(x, y), r, paint..color = Colors.white.withValues(alpha: 0.8));
    }
  }

  void _drawFarSkyline(Canvas canvas) {
    final double shift = -farT * viewW;
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(shift + i * viewW, 382.0);

      final bldgPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
      const fb = [
        [4.0, 26.0, 50.0],
        [30.0, 16.0, 70.0],
        [78.0, 24.0, 58.0],
        [104.0, 28.0, 76.0],
        [136.0, 22.0, 48.0],
        [162.0, 30.0, 66.0],
        [196.0, 24.0, 92.0],
        [224.0, 28.0, 56.0],
        [366.0, 20.0, 60.0],
      ];
      for (final b in fb) {
        canvas.drawRect(Rect.fromLTWH(b[0], -b[2], b[1], b[2]), bldgPaint);
      }

      // Spire / Big Ben clocktower silhouette
      canvas.drawRect(const Rect.fromLTWH(52, -148, 16, 148), bldgPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(48, -148, 24, 24), const Radius.circular(2)), bldgPaint);
      final spirePath = Path()
        ..moveTo(48, -148)
        ..lineTo(60, -176)
        ..lineTo(72, -148)
        ..close();
      canvas.drawPath(spirePath, bldgPaint);
      canvas.drawRect(const Rect.fromLTWH(58.5, -190, 3, 16), bldgPaint);
      // Clock face
      final clockPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(55, -142, 10, 10), const Radius.circular(2)), clockPaint);

      // London Eye
      canvas.save();
      canvas.translate(310.0, -64.0);
      final eyeStroke = Paint()
        ..color = Colors.white.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      // Base A-frame legs
      canvas.drawLine(const Offset(0, 0), const Offset(-16, 64), eyeStroke);
      canvas.drawLine(const Offset(0, 0), const Offset(16, 64), eyeStroke);
      canvas.drawLine(const Offset(-24, 64), const Offset(24, 64), eyeStroke);

      // Rotating Wheel
      canvas.save();
      canvas.rotate(eyeAngle);
      eyeStroke.strokeWidth = 2.5;
      canvas.drawCircle(Offset.zero, 50, eyeStroke);
      eyeStroke.strokeWidth = 1.0;
      canvas.drawCircle(Offset.zero, 44, eyeStroke);
      canvas.drawLine(const Offset(-50, 0), const Offset(50, 0), eyeStroke);
      canvas.drawLine(const Offset(0, -50), const Offset(0, 50), eyeStroke);
      canvas.drawLine(const Offset(-35, -35), const Offset(35, 35), eyeStroke);
      canvas.drawLine(const Offset(-35, 35), const Offset(35, -35), eyeStroke);
      canvas.restore();

      canvas.restore();

      canvas.restore();
    }
  }

  void _drawMidSkyline(Canvas canvas) {
    final double shift = -midT * viewW;
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(shift + i * viewW, groundY);

      // Buildings
      _drawMidBuilding(canvas, 6, 60, 66, const Color(0xFF0D36A0), 0);
      _drawMidBuilding(canvas, 70, 56, 84, const Color(0xFF0A2B8A), 1);
      _drawMidBuilding(canvas, 234, 58, 76, const Color(0xFF0D36A0), 2);
      _drawMidBuilding(canvas, 296, 42, 60, const Color(0xFF123FB5), 0);
      _drawMidBuilding(canvas, 342, 44, 90, const Color(0xFF0A2B8A), 1);

      // DC+ Dry Clean Storefront
      _drawDCShopfront(canvas);

      canvas.restore();
    }
  }

  void _drawMidBuilding(Canvas canvas, double x, double w, double h, Color color, int roofType) {
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(x, -h, w, h), paint);

    if (roofType == 1) {
      final roof = Path()
        ..moveTo(x - 3, -h)
        ..lineTo(x + w / 2, -h - 14)
        ..lineTo(x + w + 3, -h)
        ..close();
      canvas.drawPath(roof, paint);
    } else if (roofType == 2) {
      canvas.drawRect(Rect.fromLTWH(x + w - 18, -h - 12, 9, 12), paint);
    }

    final int cols = math.max(1, ((w - 6) / 14).floor());
    final double colOff = (w - (cols * 14 - 6)) / 2;
    final int rows = math.max(1, ((h - 12) / 19).floor());

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final bool lit = ((c * 7 + r * 13) % 5) != 0;
        final winPaint = Paint()
          ..color = lit
              ? const Color(0xFFFFE08A).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.16);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + colOff + c * 14, -h + 10 + r * 19, 8, 11),
            const Radius.circular(1.5),
          ),
          winPaint,
        );
      }
    }
  }

  void _drawDCShopfront(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(130, -64, 100, 64), Paint()..color = const Color(0xFF1B5CF0));

    // Sign background (76x20 at x=142, y=-58)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(140, -58, 80, 20), const Radius.circular(5)),
      Paint()..color = const Color(0xFF071B49),
    );

    // ONLY "DrycleanPlus+" text (NO logo badge, matching user instruction)
    final signTp = TextPainter(
      text: TextSpan(
        style: GoogleFonts.satisfy(
          fontSize: 14.0,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        children: const [
          TextSpan(text: 'Dryclean', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'Plus', style: TextStyle(color: Color(0xFFE5262D))),
          TextSpan(
            text: '+',
            style: TextStyle(color: Color(0xFFE5262D), fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    signTp.paint(canvas, Offset(180 - signTp.width / 2.0, -48 - signTp.height / 2.0));

    for (int i = 0; i < 6; i++) {
      final awningColor = (i % 2 == 1) ? const Color(0xFF9CC2FF) : Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(134.0 + i * 15.33, -36, 15.33, 10),
        Paint()..color = awningColor,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(142, -22, 62, 18), const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFE9A8),
    );
    canvas.drawLine(
      const Offset(146, -20),
      const Offset(200, -20),
      Paint()
        ..color = const Color(0xFF8A6A1F)
        ..strokeWidth = 1.4,
    );

    const shirtColors = [
      Color(0xFF1550E8),
      Color(0xFF12B76A),
      Color(0xFFE5484D),
      Color(0xFF1550E8),
    ];
    for (int i = 0; i < 4; i++) {
      final double sx = 156.0 + i * 14.0;
      final path = Path()
        ..moveTo(sx, -19)
        ..lineTo(sx - 4, -17)
        ..lineTo(sx - 3, -14)
        ..lineTo(sx - 1, -14.6)
        ..lineTo(sx - 1, -7.6)
        ..lineTo(sx + 5, -7.6)
        ..lineTo(sx + 5, -14.6)
        ..lineTo(sx + 7, -14)
        ..lineTo(sx + 8, -17)
        ..lineTo(sx + 4, -19)
        ..close();
      canvas.drawPath(path, Paint()..color = shirtColors[i]);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(210, -26, 14, 26), const Radius.circular(3)),
      Paint()..color = const Color(0xFF071B49),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(213, -22, 8, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: 0.8),
    );
  }

  void _drawRoadAndPavement(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(-150, groundY, viewW + 300, 12), Paint()..color = const Color(0xFF0D36A0));
    canvas.drawRect(const Rect.fromLTWH(-150, curbY, viewW + 300, 3), Paint()..color = const Color(0xFF336EE0));
    canvas.drawRect(const Rect.fromLTWH(-150, curbY + 3, viewW + 300, roadEndY - curbY), Paint()..color = const Color(0xFF09205A));

    final double dashShift = -dashT * 54.0;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 3.0;

    for (double x = -150.0 + dashShift; x < 550.0; x += 54.0) {
      canvas.drawLine(Offset(x, 451), Offset(x + 30, 451), dashPaint);
    }

    canvas.drawRect(const Rect.fromLTWH(-150, roadEndY, viewW + 300, 16), Paint()..color = const Color(0xFF12358F));
    canvas.drawRect(const Rect.fromLTWH(-150, roadEndY, viewW + 300, 2), Paint()..color = const Color(0xFF3A74F0));
  }

  void _drawBus(Canvas canvas) {
    // Bus drives smoothly across in 36% of cycle, then waits offscreen matching HTML spec
    double busX;
    if (busT < 0.36) {
      final double progress = busT / 0.36;
      busX = 470.0 - (progress * 670.0);
    } else {
      return;
    }
    if (busX < -200.0 || busX > 470.0) return;

    canvas.save();
    canvas.translate(busX, 391.0);
    canvas.scale(0.62, 0.62);

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 120, 64), const Radius.circular(9)),
      Paint()..color = const Color(0xFFE5484D),
    );
    canvas.drawRect(const Rect.fromLTWH(0, 42, 120, 6), Paint()..color = const Color(0xFFB92F35));

    final winPaint = Paint()..color = const Color(0xFFBFE0FF);
    for (int u = 0; u < 6; u++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(9.0 + u * 18.0, 9, 13, 14), const Radius.circular(3)),
        winPaint,
      );
    }
    for (int l = 0; l < 5; l++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(9.0 + l * 18.0, 29, 13, 14), const Radius.circular(3)),
        winPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(99, 29, 14, 30), const Radius.circular(3)),
      Paint()..color = const Color(0xFF8FC2FF),
    );
    canvas.drawRect(const Rect.fromLTWH(-1, 48, 5, 7), Paint()..color = const Color(0xFFFFE08A));

    for (final wx in [26.0, 94.0]) {
      canvas.save();
      canvas.translate(wx, 66.0);
      canvas.drawCircle(Offset.zero, 10, Paint()..color = const Color(0xFF101A38));
      canvas.rotate(-wheelAngle);
      canvas.drawCircle(Offset.zero, 5, Paint()..color = const Color(0xFFD3DCEF));
      final spPaint = Paint()
        ..color = const Color(0xFF6C7A99)
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(-5, 0), const Offset(5, 0), spPaint);
      canvas.drawLine(const Offset(0, -5), const Offset(0, 5), spPaint);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawVan(Canvas canvas) {
    canvas.save();

    final bool isFull = mode == SceneDisplayMode.full;
    // Normalized so physical van size on user screen is exactly equal in both Splash and Onboarding!
    final double vanScale = isFull ? 0.81 : 1.02;
    final double baseVanX = isFull ? 96.0 : 112.0;
    final double baseVanY = 474.0 - (92.0 * vanScale);

    canvas.translate(baseVanX + driftX + vanAnimX, baseVanY + bobY);
    canvas.scale(vanScale, vanScale);

    // Waving Flag Banner trailing behind the van
    _drawWavingFlag(canvas);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(98, 104), width: 208, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Exactly 2 aerodynamic trailing wave lines rippling behind the van
    final waveLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final double wavePhase = dashT * 2.0 * math.pi;
    final path1 = Path()
      ..moveTo(-10, 52)
      ..quadraticBezierTo(-30, 52 + math.sin(wavePhase) * 2.5, -56, 52);
    canvas.drawPath(path1, waveLinePaint);

    final path2 = Path()
      ..moveTo(-16, 76)
      ..quadraticBezierTo(-38, 76 + math.cos(wavePhase) * 2.5, -64, 76);
    canvas.drawPath(path2, waveLinePaint);

    final vanBodyGradient = const LinearGradient(
      colors: [Colors.white, Color(0xFFC9D4EA)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final vanPaint = Paint()
      ..shader = vanBodyGradient.createShader(const Rect.fromLTWH(0, 0, 190, 82));

    // Cargo box
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 125, 82), const Radius.circular(10)),
      vanPaint,
    );

    // Driver cab
    final cabPath = Path()
      ..moveTo(125, 16)
      ..lineTo(147, 16)
      ..cubicTo(158, 16, 177, 44, 185, 52)
      ..lineTo(185, 82)
      ..lineTo(125, 82)
      ..close();
    canvas.drawPath(cabPath, vanPaint);

    // Bumper
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(180, 72, 10, 10), const Radius.circular(3)),
      Paint()..color = const Color(0xFF8EA3C7),
    );

    // Windshield
    final wsPath = Path()
      ..moveTo(133, 22)
      ..lineTo(146, 22)
      ..cubicTo(153, 22, 167, 42, 172, 48)
      ..lineTo(133, 48)
      ..close();
    canvas.drawPath(wsPath, Paint()..color = const Color(0xFF225ED6));

    // Side Door Seam
    canvas.drawLine(
      const Offset(125, 16),
      const Offset(125, 82),
      Paint()
        ..color = const Color(0xFFBAC7DF)
        ..strokeWidth = 1.2,
    );

    // Vibrant Teal Stripe
    canvas.drawRect(const Rect.fromLTWH(0, 52, 185, 6), Paint()..color = const Color(0xFF0F9F90));

    // Organic Pick Badge on Van side
    _drawVanPickBadge(canvas, const Offset(14, 20), 22);

    // Cursive "DrycleanPlus+" brand on van side
    final vanBrandTp = TextPainter(
      text: TextSpan(
        style: GoogleFonts.satisfy(
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        children: const [
          TextSpan(
            text: 'Dryclean',
            style: TextStyle(color: Color(0xFF0B2545)),
          ),
          TextSpan(
            text: 'Plus',
            style: TextStyle(color: Color(0xFFE5262D)),
          ),
          TextSpan(
            text: '+',
            style: TextStyle(color: Color(0xFFE5262D), fontSize: 13),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    vanBrandTp.paint(canvas, const Offset(38, 17));

    // Tagline constrained inside cargo box
    final subTp = TextPainter(
      text: const TextSpan(
        text: 'Premium care · Delivered to you',
        style: TextStyle(
          fontSize: 5.2,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.05,
          color: Color(0xFF1550E8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    subTp.paint(canvas, const Offset(38, 35));

    // Luminous illuminated headlight beam cone projecting forward onto road
    final beamPath = Path()
      ..moveTo(187, 66)
      ..lineTo(356, 26)
      ..lineTo(356, 118)
      ..lineTo(187, 76)
      ..close();
    final beamGradient = const LinearGradient(
      colors: [
        Color(0xB3FFF8C4),
        Color(0x66FFE885),
        Color(0x00FFE885),
      ],
      stops: [0.0, 0.45, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = beamGradient.createShader(const Rect.fromLTWH(187, 26, 169, 92)),
    );

    // Inner bright core light cone
    final coreBeamPath = Path()
      ..moveTo(187, 68)
      ..lineTo(312, 48)
      ..lineTo(312, 98)
      ..lineTo(187, 74)
      ..close();
    canvas.drawPath(
      coreBeamPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xEEFFFFFF), Color(0x55FFF3B8), Color(0x00FFF3B8)],
          stops: [0.0, 0.40, 1.0],
        ).createShader(const Rect.fromLTWH(187, 48, 125, 50)),
    );

    // Projected warm luminous pool of light on the asphalt road surface
    canvas.drawOval(
      const Rect.fromLTWH(206, 76, 134, 20),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x59FFE885), Color(0x00FFE885)],
        ).createShader(const Rect.fromLTWH(206, 76, 134, 20)),
    );

    // Radiant glowing headlight bulb & lens flare
    canvas.drawCircle(
      const Offset(187, 71),
      10,
      Paint()..color = const Color(0x55FFE885),
    );
    canvas.drawCircle(
      const Offset(187, 71),
      6,
      Paint()..color = const Color(0xFFFFFAEB),
    );
    canvas.drawCircle(
      const Offset(187, 71),
      3.2,
      Paint()..color = Colors.white,
    );

    // Taillight
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-2, 52, 4, 9), const Radius.circular(1)),
      Paint()..color = const Color(0xFFFF5A4D),
    );

    // Wheels
    _drawWheel(canvas, const Offset(42, 82));
    _drawWheel(canvas, const Offset(150, 82));

    canvas.restore();
  }

  void _drawVanPickBadge(Canvas canvas, Offset offset, double size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final w = size;
    final h = size;

    final path = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, w, h),
        topLeft: Radius.elliptical(w * 0.30, h * 0.30),
        topRight: Radius.elliptical(w * 0.70, h * 0.30),
        bottomRight: Radius.elliptical(w * 0.70, h * 0.70),
        bottomLeft: Radius.elliptical(w * 0.30, h * 0.70),
      ));

    canvas.drawPath(path, Paint()..color = const Color(0xFF071F14));

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final badgeTp = TextPainter(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
        children: const [
          TextSpan(text: 'DC', style: TextStyle(color: Colors.white)),
          TextSpan(text: '+', style: TextStyle(color: Color(0xFFE5262D))),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    badgeTp.paint(
      canvas,
      Offset((w - badgeTp.width) / 2.0, (h - badgeTp.height) / 2.0),
    );

    canvas.restore();
  }

  void _drawWheel(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.drawCircle(Offset.zero, 18, Paint()..color = const Color(0xFF1B2333));
    canvas.drawCircle(Offset.zero, 12, Paint()..color = const Color(0xFFC7D3E8));
    canvas.drawCircle(Offset.zero, 6, Paint()..color = const Color(0xFF0B2545));

    canvas.rotate(wheelAngle);
    final spokePaint = Paint()
      ..color = const Color(0xFF6B7E9F)
      ..strokeWidth = 2;
    for (int i = 0; i < 5; i++) {
      final double rad = i * 2.0 * math.pi / 5.0;
      canvas.drawLine(Offset.zero, Offset(math.cos(rad) * 12, math.sin(rad) * 12), spokePaint);
    }

    canvas.restore();
  }

  void _drawWavingFlag(Canvas canvas) {
    canvas.save();

    final double speedFactor = isVanSpeeding ? 2.4 : 1.0;
    // Calm, gentle ~1.3 Hz cruising wave that accelerates gracefully when speeding up
    final double animPhase = (midT * 8.5 * 2.0 * math.pi) * speedFactor;

    // Flag seamlessly flows from van rear with a sleek chrome mount
    final polePaint = Paint()
      ..color = const Color(0xFFD4DEEE)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 16), const Offset(0, 38), polePaint);

    const double startY = 15.0;
    const double flagLength = 62.0;
    const double flagHeight = 22.0;
    const int segments = 20;

    final List<Offset> topPoints = [];
    final List<Offset> botPoints = [];

    for (int i = 0; i <= segments; i++) {
      final double progress = i / segments.toDouble();
      final double x = -progress * flagLength;
      final double wave1 = math.sin(animPhase - progress * 1.8 * math.pi) * (1.2 * progress * speedFactor);
      final double wave2 = math.cos(animPhase * 0.8 - progress * 2.6 * math.pi) * (0.5 * progress * speedFactor);
      final double totalWave = wave1 + wave2;

      topPoints.add(Offset(x, startY + totalWave));
      botPoints.add(Offset(x, startY + flagHeight + totalWave));
    }

    final flagPath = Path();
    flagPath.moveTo(topPoints.first.dx, topPoints.first.dy);
    for (int i = 1; i < topPoints.length; i++) {
      flagPath.lineTo(topPoints[i].dx, topPoints[i].dy);
    }

    final double tailWave = topPoints.last.dy - startY;
    final Offset notchPoint = Offset(-flagLength + 8.0, startY + (flagHeight / 2.0) + tailWave);
    flagPath.lineTo(notchPoint.dx, notchPoint.dy);
    flagPath.lineTo(botPoints.last.dx, botPoints.last.dy);

    for (int i = botPoints.length - 2; i >= 0; i--) {
      flagPath.lineTo(botPoints[i].dx, botPoints[i].dy);
    }
    flagPath.close();

    final shadowPath = flagPath.shift(const Offset(-1, 2.5));
    canvas.drawPath(shadowPath, Paint()..color = Colors.black.withValues(alpha: 0.18));

    final flagGradient = const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        Color(0xFF1B5DF2),
        Color(0xFF1347C8),
        Color(0xFF0C2D8C),
      ],
      stops: [0.0, 0.55, 1.0],
    );

    canvas.drawPath(
      flagPath,
      Paint()..shader = flagGradient.createShader(const Rect.fromLTWH(-flagLength, startY - 6, flagLength, flagHeight + 12)),
    );

    canvas.drawPath(
      flagPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    final int midIdx = (segments * 0.46).round();
    final double midX = topPoints[midIdx].dx;
    final double midY = (topPoints[midIdx].dy + botPoints[midIdx].dy) / 2.0;

    final double dx = topPoints[midIdx + 1].dx - topPoints[midIdx - 1].dx;
    final double dy = topPoints[midIdx + 1].dy - topPoints[midIdx - 1].dy;
    final double waveAngle = math.atan2(dy, dx) - math.pi;

    canvas.save();
    canvas.translate(midX, midY);
    canvas.rotate(waveAngle);

    final flagTp = TextPainter(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 6.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          height: 1.15,
        ),
        children: const [
          TextSpan(
            text: 'PREMIUM CARE\n',
            style: TextStyle(
              color: Colors.white,
              shadows: [Shadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
          TextSpan(
            text: 'Delivered to you',
            style: TextStyle(
              color: Color(0xFFFFD25E),
              fontWeight: FontWeight.w700,
              fontSize: 5.7,
              shadows: [Shadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 56);

    flagTp.paint(canvas, Offset(-flagTp.width / 2.0, -flagTp.height / 2.0));
    canvas.restore();

    canvas.restore();
  }

  void _drawForeground(Canvas canvas) {
    final double shift = -foreT * viewW;
    for (int i = 0; i < 3; i++) {
      canvas.save();
      // Foreground translates to roadEndY + 4.0 (508.0) matching HTML FORE: ${RB+4}
      canvas.translate(shift + i * viewW, roadEndY + 4.0);

      // 15 Fence railings along foreground curb matching HTML FORE
      for (int f = 0; f < 15; f++) {
        canvas.drawLine(
          Offset(f * 26.0 + 8.0, -4),
          Offset(f * 26.0 + 8.0, 12),
          Paint()
            ..color = const Color(0xFF0B2A75)
            ..strokeWidth = 2.0,
        );
      }

      // Lampposts grounded at bottom curb (508), extending up 192 units to 316
      for (final lx in [72.0, 266.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(lx - 6, -6, 12, 6), const Radius.circular(2)),
          Paint()..color = const Color(0xFF071B49),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(lx - 2.5, -196, 5, 192), const Radius.circular(2)),
          Paint()..color = const Color(0xFF071B49),
        );
        final armPath = Path()
          ..moveTo(lx, -196)
          ..quadraticBezierTo(lx, -204, lx + 14, -205)
          ..lineTo(lx + 34, -205);
        canvas.drawPath(
          armPath,
          Paint()
            ..color = const Color(0xFF071B49)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(lx + 40, -199), width: 56, height: 18),
          Paint()..color = const Color(0xFFFFE9A0).withValues(alpha: 0.22),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(lx + 28, -209, 24, 8), const Radius.circular(4)),
          Paint()..color = const Color(0xFFFFE9A0),
        );
      }

      // Red UK pillar box (postbox / fire hydrant) standing on foreground curb at 508 - 48 = 460
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(162, -48, 16, 48), const Radius.circular(5)),
        Paint()..color = const Color(0xFFE5484D),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(159, -53, 22, 9), const Radius.circular(4.5)),
        Paint()..color = const Color(0xFFC93A40),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(165, -34, 10, 3), const Radius.circular(1.5)),
        Paint()..color = const Color(0xFF071B49),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CityScenePainter oldDelegate) {
    return oldDelegate.farT != farT ||
        oldDelegate.midT != midT ||
        oldDelegate.dashT != dashT ||
        oldDelegate.wheelAngle != wheelAngle ||
        oldDelegate.busT != busT ||
        oldDelegate.bobY != bobY ||
        oldDelegate.driftX != driftX ||
        oldDelegate.eyeAngle != eyeAngle ||
        oldDelegate.vanAnimX != vanAnimX ||
        oldDelegate.isVanSpeeding != isVanSpeeding;
  }
}
