import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Exact coupon "ticket" matching HTML Offers & Promotions template:
/// - Top section with 18-point starburst rotated -8deg, tag, title, description,
///   circular notches on bottom-left and bottom-right (r=13).
/// - Bottom section with dashed border promo box, strike-through or copyable code,
///   circular notches on top-left and top-right (r=13), and calendar indicator.
class OfferCard extends StatefulWidget {
  final Map<String, dynamic> offer;
  final VoidCallback? onTap;
  final bool isUsed;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.isUsed = false,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _down = false;
  bool _copied = false;

  Future<void> _handleCopy(String code) async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF8CF0BC), size: 20),
            const SizedBox(width: 10),
            Text('Promo code $code copied!'),
          ],
        ),
        backgroundColor: const Color(0xFF071A45),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.offer;
    final expiry = data['expiryDate'] as DateTime?;
    final expired = expiry != null && expiry.isBefore(DateTime.now());
    final inactive = expired || widget.isUsed;

    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final tag = (data['tag'] ?? '').toString();
    final image = (data['image'] ?? '').toString();
    final code = (data['discountCode'] ?? '').toString();
    final value = (data['discountValue'] as num?)?.toDouble() ?? (data['discountPct'] as num?)?.toDouble() ?? 0.0;
    final type = (data['discountType'] ?? 'percentage').toString();

    final big = type == 'fixed' ? '£${_num(value)}' : '${_num(value)}%';

    int? daysLeft;
    if (expiry != null && !expired) {
      daysLeft = expiry.difference(DateTime.now()).inDays;
    }

    return AnimatedScale(
      scale: _down && !inactive ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x52050F32), // rgba(5,15,50,.32)
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── TOP SECTION (.tp) ──────────────────────────────────────
            ClipPath(
              clipper: const _TicketTopClipper(),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 104),
                decoration: BoxDecoration(
                  gradient: inactive
                      ? const LinearGradient(
                          begin: Alignment(-0.8, -0.6),
                          end: Alignment(0.8, 0.6),
                          colors: [Color(0xFF6683B3), Color(0xFF3F5C8F)],
                        )
                      : const LinearGradient(
                          begin: Alignment(-0.8, -0.6),
                          end: Alignment(0.8, 0.6),
                          colors: [Color(0xFF286DF1), Color(0xFF134BB8)],
                        ),
                ),
                child: Stack(
                  children: [
                    // Decorative bubble (right: -40, top: -50, 150x150)
                    Positioned(
                      right: -40,
                      top: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(inactive ? 0.09 : 0.12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 18-point starburst badge (.sb) rotated -8deg
                          _buildStarburst(big: big, inactive: inactive),
                          const SizedBox(width: 14),
                          // Content (.tx)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tag.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.24),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      tag.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    height: 1.18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (image.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            _thumb(image),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM SECTION (.bt) ───────────────────────────────────
            ClipPath(
              clipper: const _TicketBottomClipper(),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEAF1FF), Color(0xFFDCE8FC)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Dashed seam divider along top
                    Positioned(
                      top: 0,
                      left: 18,
                      right: 18,
                      child: CustomPaint(
                        size: const Size(double.infinity, 2),
                        painter: _DashedDividerPainter(
                          color: const Color(0x4026407A), // rgba(38,64,122,.25)
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          // Promo code box (.cb)
                          Expanded(
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _down = true),
                              onTapCancel: () => setState(() => _down = false),
                              onTapUp: (_) => setState(() => _down = false),
                              onTap: () {
                                if (!inactive && code.isNotEmpty) {
                                  _handleCopy(code);
                                } else if (widget.onTap != null) {
                                  widget.onTap!();
                                }
                              },
                              child: _buildCodeBox(code: code, inactive: inactive),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status indicator (.ex)
                          _buildStatus(
                            expiry: expiry,
                            expired: expired,
                            daysLeft: daysLeft,
                            isUsed: widget.isUsed,
                          ),
                        ],
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
  }

  String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _buildStarburst({required String big, required bool inactive}) {
    // 76x76 18-point starburst with 6px inset inner starburst
    final outerColor = inactive ? const Color(0xFFD6E3F8) : const Color(0xFFFFC73A);
    final innerColor = inactive ? const Color(0xFFF2F7FF) : const Color(0xFFFFF9E6);
    final textColor = inactive ? const Color(0xFF3F5C8F) : const Color(0xFF0B1A3D);

    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x4D050F32), // rgba(5,15,50,.3)
            blurRadius: 8,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: -8 * math.pi / 180, // -8 deg
        child: CustomPaint(
          size: const Size(76, 76),
          painter: _Html18PointStarburstPainter(
            outerColor: outerColor,
            innerColor: innerColor,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      big,
                      style: GoogleFonts.inter(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        letterSpacing: -0.5,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  'OFF',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox({required String code, required bool inactive}) {
    if (code.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9FB4DB), width: 1.5),
        ),
        child: Text(
          'No code needed',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4B5F8C),
          ),
        ),
      );
    }

    return CustomPaint(
      painter: _DashedRRectPainter(
        color: inactive ? const Color(0xFF9FB4DB) : const Color(0xFF7FA7EC),
        strokeWidth: 2.0,
        radius: 16.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(inactive ? 0.55 : 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PROMO CODE',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: const Color(0xFF4B5F8C),
              ),
            ),
            const SizedBox(height: 1),
            if (_copied)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF009668)),
                  const SizedBox(width: 5),
                  Text(
                    'COPIED!',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: const Color(0xFF009668),
                    ),
                  ),
                ],
              )
            else if (inactive)
              Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: const Color(0xFF33497A),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: const Color(0xFFB3263A),
                  decorationThickness: 2.5,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: const Color(0xFF1450C8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF1450C8)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus({
    required DateTime? expiry,
    required bool expired,
    required int? daysLeft,
    required bool isUsed,
  }) {
    if (isUsed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 24, color: Color(0xFF4B5F8C)),
          const SizedBox(height: 3),
          Text(
            'Claimed',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4B5F8C),
            ),
          ),
        ],
      );
    }

    if (expired) {
      final dateStr = expiry != null ? DateFormat('MMM dd').format(expiry) : 'Recently';
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(26, 26),
            painter: const _ExpiredCalendarPainter(color: Color(0xFFB3263A)),
          ),
          const SizedBox(height: 3),
          Text(
            'Expired $dateStr',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB3263A),
              height: 1.2,
            ),
          ),
        ],
      );
    }

    // Active
    final bool soon = daysLeft != null && daysLeft <= 3;
    final color = soon ? const Color(0xFFD97706) : const Color(0xFF1553D6);
    final String label;
    if (soon) {
      label = daysLeft <= 0 ? 'Ends today' : '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    } else if (expiry != null) {
      label = 'Expires ${DateFormat('MMM dd').format(expiry)}';
    } else {
      label = 'No expiry';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: const Size(26, 26),
          painter: _ActiveCalendarPainter(color: color),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _thumb(String image) {
    Widget child;
    try {
      if (image.startsWith('data:image/')) {
        child = Image.memory(base64Decode(image.split(',')[1]), fit: BoxFit.cover);
      } else {
        child = Image.network(image, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink());
      }
    } catch (_) {
      child = const SizedBox.shrink();
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }
}

/// 18-point starburst painter matching exact CSS polygon:
/// 36 vertices alternating between outer radius and inner radius (rIn = rOut * 0.84).
class _Html18PointStarburstPainter extends CustomPainter {
  final Color outerColor;
  final Color innerColor;

  const _Html18PointStarburstPainter({
    required this.outerColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOuter = size.width / 2;
    final rInner = rOuter * 0.84;

    Path createStarPath(double rOut, double rIn) {
      final path = Path();
      const numPoints = 36;
      for (int i = 0; i < numPoints; i++) {
        final theta = -math.pi / 2 + i * (2 * math.pi / numPoints);
        final r = (i % 2 == 0) ? rOut : rIn;
        final x = cx + r * math.cos(theta);
        final y = cy + r * math.sin(theta);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    }

    // Outer starburst
    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(createStarPath(rOuter, rInner), outerPaint);

    // Inner starburst (inset 6px)
    final innerRout = math.max(0.0, rOuter - 6.0);
    final innerRin = innerRout * 0.84;
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(createStarPath(innerRout, innerRin), innerPaint);
  }

  @override
  bool shouldRepaint(covariant _Html18PointStarburstPainter oldDelegate) =>
      oldDelegate.outerColor != outerColor || oldDelegate.innerColor != innerColor;
}

/// Top half clipper: rounded top corners (24px) + circle cutouts (13px) at bottom-left and bottom-right.
class _TicketTopClipper extends CustomClipper<Path> {
  const _TicketTopClipper();

  @override
  Path getClip(Size size) {
    const r = 24.0;
    const notch = 13.0;

    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: const Radius.circular(r),
      topRight: const Radius.circular(r),
    );
    var path = Path()..addRRect(rrect);

    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, size.height), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(size.width, size.height), radius: notch));
    path = Path.combine(PathOperation.difference, path, holes);
    return path;
  }

  @override
  bool shouldReclip(covariant _TicketTopClipper old) => false;
}

/// Bottom half clipper: rounded bottom corners (24px) + circle cutouts (13px) at top-left and top-right.
class _TicketBottomClipper extends CustomClipper<Path> {
  const _TicketBottomClipper();

  @override
  Path getClip(Size size) {
    const r = 24.0;
    const notch = 13.0;

    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      bottomLeft: const Radius.circular(r),
      bottomRight: const Radius.circular(r),
    );
    var path = Path()..addRRect(rrect);

    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, 0), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(size.width, 0), radius: notch));
    path = Path.combine(PathOperation.difference, path, holes);
    return path;
  }

  @override
  bool shouldReclip(covariant _TicketBottomClipper old) => false;
}

/// Dashed horizontal line divider
class _DashedDividerPainter extends CustomPainter {
  final Color color;
  const _DashedDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;
    while (startX < size.width) {
      final x2 = math.min(startX + dashWidth, size.width);
      canvas.drawLine(Offset(startX, 0), Offset(x2, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) => oldDelegate.color != color;
}

/// Dashed rounded rectangle border for promo code box
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedRRectPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Expired calendar SVG icon painter matching exact HTML svg
class _ExpiredCalendarPainter extends CustomPainter {
  final Color color;
  const _ExpiredCalendarPainter({this.color = const Color(0xFFB3263A)});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * scale, 4.5 * scale, 18 * scale, 16 * scale),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(rrect, paint);

    canvas.drawLine(Offset(8 * scale, 2.5 * scale), Offset(8 * scale, 6.5 * scale), paint);
    canvas.drawLine(Offset(16 * scale, 2.5 * scale), Offset(16 * scale, 6.5 * scale), paint);
    canvas.drawLine(Offset(3 * scale, 10 * scale), Offset(21 * scale, 10 * scale), paint);

    // Cross in lower portion
    canvas.drawLine(Offset(10 * scale, 13.5 * scale), Offset(14 * scale, 17.5 * scale), paint);
    canvas.drawLine(Offset(14 * scale, 13.5 * scale), Offset(10 * scale, 17.5 * scale), paint);
  }

  @override
  bool shouldRepaint(covariant _ExpiredCalendarPainter oldDelegate) => oldDelegate.color != color;
}

/// Active calendar SVG icon painter with checkmark
class _ActiveCalendarPainter extends CustomPainter {
  final Color color;
  const _ActiveCalendarPainter({this.color = const Color(0xFF1553D6)});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * scale, 4.5 * scale, 18 * scale, 16 * scale),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(rrect, paint);

    canvas.drawLine(Offset(8 * scale, 2.5 * scale), Offset(8 * scale, 6.5 * scale), paint);
    canvas.drawLine(Offset(16 * scale, 2.5 * scale), Offset(16 * scale, 6.5 * scale), paint);
    canvas.drawLine(Offset(3 * scale, 10 * scale), Offset(21 * scale, 10 * scale), paint);

    final check = Path()
      ..moveTo(9.5 * scale, 15.5 * scale)
      ..lineTo(11.5 * scale, 17.5 * scale)
      ..lineTo(15.5 * scale, 13.5 * scale);
    canvas.drawPath(check, paint);
  }

  @override
  bool shouldRepaint(covariant _ActiveCalendarPainter oldDelegate) => oldDelegate.color != color;
}
