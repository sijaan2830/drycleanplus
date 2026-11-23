import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Washing Machine Graphic matching Home.html
/// Features realistic body, gold rotary dial, LED display,
/// gold metallic drum with swirling water and rising bubbles,
/// plus badges and sparkling accents.
class DrycleanWashingMachineGraphic extends StatefulWidget {
  final double width;
  final double height;

  const DrycleanWashingMachineGraphic({
    super.key,
    this.width = 132,
    this.height = 148,
  });

  @override
  State<DrycleanWashingMachineGraphic> createState() =>
      _DrycleanWashingMachineGraphicState();
}

class _DrycleanWashingMachineGraphicState
    extends State<DrycleanWashingMachineGraphic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Sparkle 1 (top right) ──
          Positioned(
            right: 4,
            top: 26,
            child: _Sparkle(size: 7),
          ),
          // ── Sparkle 2 (bottom left) ──
          Positioned(
            left: 2,
            bottom: 30,
            child: _Sparkle(size: 8),
          ),
          // ── Sparkle 3 (top left) ──
          Positioned(
            left: 8,
            top: 10,
            child: _Sparkle(size: 6),
          ),

          // ── Main Animated Machine Canvas ──
          Positioned(
            left: 12,
            top: 18,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(106, 122),
                  painter: _WashingMachinePainter(progress: _controller.value),
                );
              },
            ),
          ),

          // ── Badge p1 (Top Right: Navy circle + Gold border + White '+') ──
          Positioned(
            right: 0,
            top: 4,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1245B5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF5B82E), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // ── Badge p2 (Bottom Left: Gold circle + Navy '+') ──
          Positioned(
            left: 0,
            bottom: 8,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF6CB46), Color(0xFFD69A06)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Color(0xFF0B1F5B),
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  const _Sparkle({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5B82E).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WashingMachinePainter extends CustomPainter {
  final double progress;

  _WashingMachinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 96 x 112 base viewBox scaled to size (106 x 122)
    final scaleX = size.width / 96.0;
    final scaleY = size.height / 112.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Shadow underneath
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(48, 109), width: 68, height: 7),
      shadowPaint,
    );

    // 2. Machine Feet (x:12 and x:74, y:102, w:10, h:7, rx:2)
    final footPaint = Paint()..color = const Color(0xFF8FA5D6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 102, 10, 7),
        const Radius.circular(2),
      ),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(74, 102, 10, 7),
        const Radius.circular(2),
      ),
      footPaint,
    );

    // 3. Machine Body (x:6, y:4, w:84, h:100, rx:16)
    final bodyRect = const Rect.fromLTWH(6, 4, 84, 100);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFCFDDFB)],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)),
      bodyPaint,
    );

    // 4. Control Panel Top (M6 20 a16 16 0 0 1 16-16 h52 a16 16 0 0 1 16 16 v12 H6 z)
    final panelPath = Path()
      ..moveTo(6, 20)
      ..arcToPoint(const Offset(22, 4), radius: const Radius.circular(16))
      ..lineTo(74, 4)
      ..arcToPoint(const Offset(90, 20), radius: const Radius.circular(16))
      ..lineTo(90, 32)
      ..lineTo(6, 32)
      ..close();
    final panelPaint = Paint()..color = const Color(0xFFDCE7FF);
    canvas.drawPath(panelPath, panelPaint);

    // Divider line between control panel and lower body
    final dividerPaint = Paint()
      ..color = const Color(0xFFB9CBF2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(6, 32), const Offset(90, 32), dividerPaint);

    // 5. Golden Rotary Dial at (24, 18), r=7
    final dialCenter = const Offset(24, 18);
    final dialPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF9D45C), Color(0xFFD69A06)],
      ).createShader(Rect.fromCircle(center: dialCenter, radius: 7));
    canvas.drawCircle(dialCenter, 7, dialPaint);

    // Dial notch marker
    final dialNotchPaint = Paint()
      ..color = const Color(0xFF7A5200)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(24, 13.5), const Offset(24, 17.5), dialNotchPaint);

    // 6. LED Display Screen at (38, 11), w=32, h=14, rx=7
    final displayRect = const Rect.fromLTWH(38, 11, 32, 14);
    final displayPaint = Paint()..color = const Color(0xFF0B2A7A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(displayRect, const Radius.circular(7)),
      displayPaint,
    );

    // 3 Dots inside display: yellow, yellow, cyan
    final dotYellow = Paint()..color = const Color(0xFFF5B82E);
    final dotCyan = Paint()..color = const Color(0xFF4F95FF);
    canvas.drawCircle(const Offset(47, 18), 2, dotYellow);
    canvas.drawCircle(const Offset(54, 18), 2, dotYellow);
    canvas.drawCircle(const Offset(61, 18), 2, dotCyan);

    // 7. Power button at (80, 18), r=3
    canvas.drawCircle(const Offset(80, 18), 3, dotYellow);

    // 8. Washing Machine Drum (center: 48, 72)
    final drumCenter = const Offset(48, 72);

    // Drum outer gold ring (r=31)
    final outerGoldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF9D45C), Color(0xFFD69A06)],
      ).createShader(Rect.fromCircle(center: drumCenter, radius: 31));
    canvas.drawCircle(drumCenter, 31, outerGoldPaint);

    // Drum inner silver ring (r=26)
    final silverRingPaint = Paint()..color = const Color(0xFFEAF1FF);
    canvas.drawCircle(drumCenter, 26, silverRingPaint);

    // Drum water base background (r=21)
    final waterBasePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3D8BFF), Color(0xFF0B2A7A)],
      ).createShader(Rect.fromCircle(center: drumCenter, radius: 21));
    canvas.drawCircle(drumCenter, 21, waterBasePaint);

    // 9. Drum Water Swirling Wave (Clipped to r=21 circle)
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: drumCenter, radius: 21));
    canvas.clipPath(clipPath);

    // Animated water wave
    final wavePaint = Paint()
      ..color = const Color(0xFF5AA2FF).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    const waterBaseY = 74.0;
    wavePath.moveTo(20, 96);
    wavePath.lineTo(20, waterBaseY);

    final wavePhase = progress * 2 * math.pi;
    for (double x = 20; x <= 76; x += 2) {
      final y = waterBaseY +
          math.sin((x - 20) / 48.0 * 2 * math.pi * 1.5 + wavePhase) * 2.8;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(76, 96);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // 10. Animated Rising Bubbles
    // Bubble 1: base (41, 66), r=3
    _drawRisingBubble(canvas, 41, 68, 3.0, (progress) % 1.0);
    // Bubble 2: base (54, 62), r=2.2
    _drawRisingBubble(canvas, 54, 66, 2.2, (progress + 0.33) % 1.0);
    // Bubble 3: base (50, 78), r=2.6
    _drawRisingBubble(canvas, 49, 78, 2.6, (progress + 0.66) % 1.0);

    canvas.restore(); // end clip

    // 11. Curved Glass Reflection Arc (M34 61 a17 17 0 0 1 11-8)
    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arcPath = Path()
      ..moveTo(34, 61)
      ..arcToPoint(const Offset(45, 53), radius: const Radius.circular(17));
    canvas.drawPath(arcPath, arcPaint);

    canvas.restore(); // end scale
  }

  void _drawRisingBubble(
    Canvas canvas,
    double baseX,
    double baseY,
    double radius,
    double t,
  ) {
    // Rises up by 10px, fades out towards the top
    final currentY = baseY - (t * 12.0);
    final opacity = (1.0 - t).clamp(0.0, 0.85);

    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(baseX, currentY), radius, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant _WashingMachinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
