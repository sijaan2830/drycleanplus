import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Soft soap bubbles that slowly rise — used behind onboarding and the loader.
class BubbleField extends StatefulWidget {
  final int count;
  final int seed;
  const BubbleField({super.key, this.count = 14, this.seed = 7});

  @override
  State<BubbleField> createState() => _BubbleFieldState();
}

class _BubbleSpec {
  final double x, size, speed, phase, wobble, opacity;
  const _BubbleSpec(this.x, this.size, this.speed, this.phase, this.wobble, this.opacity);
}

class _BubbleFieldState extends State<BubbleField> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  late final List<_BubbleSpec> _bubbles = () {
    final r = math.Random(widget.seed);
    return List.generate(widget.count, (_) {
      return _BubbleSpec(
        r.nextDouble(),
        8 + r.nextDouble() * 30,
        0.6 + r.nextDouble() * 1.6,
        r.nextDouble(),
        6 + r.nextDouble() * 14,
        0.10 + r.nextDouble() * 0.16,
      );
    });
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _BubblePainter(_bubbles, _c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<_BubbleSpec> bubbles;
  final double t;
  _BubblePainter(this.bubbles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      // 0 → bottom, 1 → top; each bubble loops at its own speed.
      final p = (t * b.speed * 2 + b.phase) % 1.0;
      final y = size.height + b.size - p * (size.height + b.size * 2);
      final x = b.x * size.width + math.sin((t * 2 * math.pi * 2) + b.phase * 6.28) * b.wobble;
      final center = Offset(x, y);
      final r = b.size / 2;

      final fade = p < 0.1 ? p / 0.1 : (p > 0.9 ? (1 - p) / 0.1 : 1.0);

      canvas.drawCircle(
        center,
        r,
        Paint()..color = Colors.white.withOpacity(b.opacity * 0.55 * fade),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(b.opacity * 1.6 * fade),
      );
      // little highlight
      canvas.drawCircle(
        center.translate(-r * 0.35, -r * 0.35),
        r * 0.18,
        Paint()..color = Colors.white.withOpacity(0.7 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t;
}
