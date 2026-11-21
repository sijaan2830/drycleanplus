import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The official DrycleanPlus organic guitar-pick logo badge matching
/// the user's uploaded brand mark (dark forest green organic shape with white "DC" and red "+").
class DCPlusLogoBadge extends StatelessWidget {
  final double size;
  final bool showShadow;

  const DCPlusLogoBadge({
    super.key,
    this.size = 38,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: const Color(0xFF071F14),
        shadows: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        shape: const CustomOrganicBorder(),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'DC',
              style: GoogleFonts.inter(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 2.0),
            Text(
              '+',
              style: GoogleFonts.inter(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE5262D),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exact Organic Guitar Pick Shape Border matching the original brand mark
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
        topLeft: Radius.elliptical(rect.width * 0.30, rect.height * 0.30),
        topRight: Radius.elliptical(rect.width * 0.70, rect.height * 0.30),
        bottomRight: Radius.elliptical(rect.width * 0.70, rect.height * 0.70),
        bottomLeft: Radius.elliptical(rect.width * 0.30, rect.height * 0.70),
      ));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(getOuterPath(rect), paint);
  }

  @override
  ShapeBorder scale(double t) => const CustomOrganicBorder();
}
