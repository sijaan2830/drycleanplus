import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Accurate implementation of the HTML/CSS prepaid pack card.
class PrepaidPackCard extends StatefulWidget {
  final String packName;
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool isBestValue;
  final double? width;

  const PrepaidPackCard({
    super.key,
    required this.packName,
    required this.item,
    required this.onTap,
    this.isBestValue = false,
    this.width,
  });

  /// Category gradient mapper matching the HTML CSS custom properties (--a, --b)
  static List<Color> getGradient(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('trouser')) {
      return const [Color(0xFF3B2DB5), Color(0xFF5B3FE0)];
    } else if (lower.contains('suit')) {
      return const [Color(0xFF0A5A5E), Color(0xFF0E7C7B)];
    } else if (lower.contains('duvet') || lower.contains('bedding')) {
      return const [Color(0xFF7A1FA2), Color(0xFFA62C99)];
    } else if (lower.contains('shirt')) {
      return const [Color(0xFFB33A0B), Color(0xFFD1470D)];
    } else if (lower.contains('wash') || lower.contains('iron')) {
      return const [Color(0xFF0A1F52), Color(0xFF14409A)];
    }
    return const [Color(0xFF3B2DB5), Color(0xFF5B3FE0)];
  }

  @override
  State<PrepaidPackCard> createState() => _PrepaidPackCardState();
}

class _PrepaidPackCardState extends State<PrepaidPackCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final countStr = item['count']?.toString() ?? '';
    final labelStr = item['label']?.toString() ?? '';
    final oldPrice = item['old']?.toString() ?? '';
    final newPrice = item['new']?.toString() ?? '';
    final off = item['off']?.toString() ?? '';

    // Numeric parsing for savings and price per item
    final oldVal = double.tryParse(oldPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final newVal = double.tryParse(newPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final savings = (oldVal > newVal) ? (oldVal - newVal) : 0.0;

    // Parse pure numeric count (e.g. "5" from "5" or "5×2-piece")
    final numericCount = int.tryParse(countStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final pricePerItem = numericCount > 0 ? (newVal / numericCount) : newVal;

    final gradientColors = PrepaidPackCard.getGradient(widget.packName);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: widget.width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Main Card (Article.cd) ──
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  border: Border.all(
                    color: widget.isBestValue ? const Color(0xFFFFC73A) : Colors.white.withOpacity(0.24),
                    width: widget.isBestValue ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF050F32).withOpacity(0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    if (widget.isBestValue)
                      BoxShadow(
                        color: const Color(0xFFFFC73A).withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // ── Decorative Circles (.dc) ──
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 34,
                        left: -22,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),

                      // ── Content Column ──
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top row: Count + Label on left, Starburst sticker on right
                          Padding(
                            padding: EdgeInsets.fromLTRB(12, widget.isBestValue ? 15 : 12, 10, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          countStr,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.0,
                                            letterSpacing: -0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        labelStr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Starburst Sticker (.st)
                                if (off.isNotEmpty)
                                  Transform.rotate(
                                    angle: 0.17, // ~10 degrees
                                    child: SizedBox(
                                      width: 46,
                                      height: 46,
                                      child: CustomPaint(
                                        painter: _Html16PointStarburstPainter(),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                off.endsWith('%') ? off : '$off%',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF0B1A3D),
                                                  height: 1.0,
                                                ),
                                              ),
                                              Text(
                                                'OFF',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 7.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF0B1A3D),
                                                  letterSpacing: 0.5,
                                                  height: 1.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Price per item (.pi)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white),
                                children: [
                                  TextSpan(
                                    text: '£${pricePerItem.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                  ),
                                  const TextSpan(text: ' / item'),
                                ],
                              ),
                            ),
                          ),

                          // ── Bottom Action Footer (.ft) ──
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF050F3C).withOpacity(0.35),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              '£$newPrice',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (oldPrice.isNotEmpty) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '£$oldPrice',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  color: Colors.white.withOpacity(0.78),
                                                  decoration: TextDecoration.lineThrough,
                                                  decorationColor: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (savings > 0)
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Save £${savings.toStringAsFixed(savings.truncateToDouble() == savings ? 0 : 2)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF8CF0BC),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Circular Yellow Arrow Button (.go)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFC73A),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFF0B1A3D),
                                    size: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Best Value Badge (.bv) ──
              if (widget.isBestValue)
                Positioned(
                  top: -10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFDF00), Color(0xFFFFB800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFB800).withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 13,
                          color: Color(0xFF071739),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          'BEST VALUE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF071739),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 16-point starburst painter matching the HTML CSS clip-path polygon
class _Html16PointStarburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.82;

    final outerPath = Path();
    const points = 16;
    const angleStep = (math.pi * 2) / (points * 2);

    for (int i = 0; i <= points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(i * angleStep - math.pi / 2);
      final y = centerY + radius * math.sin(i * angleStep - math.pi / 2);

      if (i == 0) {
        outerPath.moveTo(x, y);
      } else {
        outerPath.lineTo(x, y);
      }
    }
    outerPath.close();

    // Outer fill: #FFC73A
    final outerPaint = Paint()
      ..color = const Color(0xFFFFC73A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, outerPaint);

    // Inner layer (inset 3.5px): #FFDC7A
    final innerPath = Path();
    final innerOuterRadius = outerRadius - 3.5;
    final innerInnerRadius = innerRadius - 3.5;

    for (int i = 0; i <= points * 2; i++) {
      final radius = i.isEven ? innerOuterRadius : innerInnerRadius;
      final x = centerX + radius * math.cos(i * angleStep - math.pi / 2);
      final y = centerY + radius * math.sin(i * angleStep - math.pi / 2);

      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();

    final innerPaint = Paint()
      ..color = const Color(0xFFFFDC7A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
