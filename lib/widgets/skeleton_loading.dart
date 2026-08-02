import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import 'dart:math' as math;

/// A skeleton loading widget that displays a "Cleaning Swipe" shimmer effect
/// with "Live Sparkles" for a premium feel.
class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Layer 1: The "Cleaning Swipe" Shimmer ────────────────────────────
        Shimmer(
          period: const Duration(milliseconds: 2200),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white.withOpacity(0.15),
              AppColors.white.withOpacity(0.45),
              AppColors.goldLight.withOpacity(0.9), // Powerful gold shine
              AppColors.white.withOpacity(0.45),
              AppColors.white.withOpacity(0.15),
            ],
            stops: const [0.1, 0.4, 0.5, 0.6, 0.9],
          ),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueDark.withOpacity(0.52), // More visible structure
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.white.withOpacity(0.15),
                width: 1.2,
              ),
            ),
          ),
        ),

        // ── Layer 2: The "Live Sparkles" Overlay ──────────────────────────────
        Positioned.fill(
          child: _LiveSparkleOverlay(
            borderRadius: borderRadius,
          ),
        ),
      ],
    );
  }
}

/// Private widget to handle the live "sparkle dots" effect
class _LiveSparkleOverlay extends StatefulWidget {
  final double borderRadius;
  const _LiveSparkleOverlay({required this.borderRadius});

  @override
  State<_LiveSparkleOverlay> createState() => _LiveSparkleOverlayState();
}

class _LiveSparkleOverlayState extends State<_LiveSparkleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, _) {
        return CustomPaint(
          painter: _SparklePainter(
            progress: _sparkleController.value,
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final math.Random random = math.Random(101);

  _SparklePainter({required this.progress, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // Increased density to 10 for a richer "Magic cleaning" feel
    for (int i = 0; i < 10; i++) {
      double sparkleProgress = (progress + (i * 0.1)) % 1.0;
      double opacity = 0.0;
      
      // Sharper Twinkle (Jhelek) logic
      if (sparkleProgress < 0.25) {
        opacity = sparkleProgress / 0.25; 
      } else if (sparkleProgress < 0.5) {
        opacity = (0.5 - sparkleProgress) / 0.25;
      }

      if (opacity <= 0.05) continue;

      final sparkleRandom = math.Random(i * 91);
      final x = sparkleRandom.nextDouble() * size.width;
      final y = sparkleRandom.nextDouble() * size.height;
      
      // Bigger and more diverse star sizes
      final baseSize = 3.0 + sparkleRandom.nextDouble() * 4.0;
      final currentSize = baseSize * opacity;
      final rotation = progress * math.pi * 2.0; // Faster/smoother spin

      final Paint paint = Paint()..style = PaintingStyle.fill;
      final color = i % 2 == 0 ? AppColors.white : AppColors.goldLight;
      
      // Layer 1: Enhanced Glow
      paint.color = color.withOpacity(opacity * 0.4);
      _drawSparkleStar(canvas, Offset(x, y), currentSize * 2.8, rotation, paint);
      
      // Layer 2: Core Sparkle
      paint.color = color.withOpacity(opacity * 1.0);
      _drawSparkleStar(canvas, Offset(x, y), currentSize, rotation, paint);
    }
  }

  /// Draws a premium 4-pointed star shape (sparkle)
  void _drawSparkleStar(Canvas canvas, Offset center, double size, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    
    final path = Path();
    // A 4-pointed star with curved insets (magic/cleaning style)
    path.moveTo(0, -size); // Top
    path.quadraticBezierTo(0, 0, size, 0); // To Right
    path.quadraticBezierTo(0, 0, 0, size); // To Bottom
    path.quadraticBezierTo(0, 0, -size, 0); // To Left
    path.quadraticBezierTo(0, 0, 0, -size); // Back to top
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A skeleton loading card for list items
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({
    super.key,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SkeletonLoading(
            width: 60,
            height: 60,
            borderRadius: 8,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                ),
                const SizedBox(height: 8),
                SkeletonLoading(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton loading list with multiple items
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonCard(height: itemHeight);
      },
    );
  }
}

/// A skeleton loading grid
class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return const SkeletonLoading(
          borderRadius: 12,
        );
      },
    );
  }
}
