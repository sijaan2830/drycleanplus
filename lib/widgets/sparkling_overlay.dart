import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/theme.dart';

/// A premium overlay that adds a "Live Sparkling" effect to its child.
/// It displays multiple twinkling 4-pointed stars at random positions.
class SparklingOverlay extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final int sparkleCount;
  final bool isLive;

  const SparklingOverlay({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.sparkleCount = 8,
    this.isLive = true,
  });

  @override
  State<SparklingOverlay> createState() => _SparklingOverlayState();
}

class _SparklingOverlayState extends State<SparklingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat();
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: AnimatedBuilder(
                animation: _controller!,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SparklePainter(
                      progress: _controller!.value,
                      count: widget.sparkleCount,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final int count;

  _SparklePainter({required this.progress, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final Paint paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < count; i++) {
      // Use index-based seed for consistent positioning per sparkle
      final math.Random random = math.Random(i * 123);
      
      // Offset each sparkle's timing
      double spProgress = (progress + (i / count)) % 1.0;
      
      double opacity = 0.0;
      double scale = 0.0;
      
      // Twinkle (Jhelek) timing logic
      if (spProgress < 0.2) {
        opacity = spProgress / 0.2;
        scale = opacity;
      } else if (spProgress < 0.4) {
        opacity = (0.4 - spProgress) / 0.2;
        scale = opacity;
      }

      if (opacity <= 0.1) continue;

      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final baseSize = 4.0 + random.nextDouble() * 6.0;
      final currentSize = baseSize * scale;
      final rotation = i * math.pi / 4; // Static rotation for stars

      // Layer 1: Glow
      paint.color = AppColors.white.withOpacity(opacity * 0.3);
      _drawStar(canvas, Offset(x, y), currentSize * 2.0, rotation, paint);
      
      // Layer 2: Core
      paint.color = i % 2 == 0 ? AppColors.gold.withOpacity(opacity * 0.9) : AppColors.white.withOpacity(opacity * 0.9);
      _drawStar(canvas, Offset(x, y), currentSize, rotation, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(0, 0, size, 0);
    path.quadraticBezierTo(0, 0, 0, size);
    path.quadraticBezierTo(0, 0, -size, 0);
    path.quadraticBezierTo(0, 0, 0, -size);
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.progress != progress;
}
