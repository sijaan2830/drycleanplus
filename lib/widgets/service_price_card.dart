import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Preset configurations matching Prices.html design
/// Card colours shared with the admin console and the website (light, strong).
const kCardPalette = <List<Color>>[
  [Color(0xFFFFA3A8), Color(0xFFFF7B86)], // Rose
  [Color(0xFFFFE58C), Color(0xFFFFCB4F)], // Sunny
  [Color(0xFFA9E3FF), Color(0xFF7BCBFB)], // Sky
  [Color(0xFFC9F78E), Color(0xFFA6EB60)], // Lime
  [Color(0xFFDCD0FF), Color(0xFFB9A8FF)], // Lavender
  [Color(0xFFFFD9A8), Color(0xFFF5B66B)], // Peach
  [Color(0xFFA8F0D5), Color(0xFF5EDBB0)], // Mint
  [Color(0xFFFFC4AD), Color(0xFFFF9E7A)], // Coral
  [Color(0xFFAFC8FF), Color(0xFF6C9BFF)], // Ocean
  [Color(0xFFF5C2FA), Color(0xFFE58BF0)], // Orchid
];

/// A new section's colour when none was picked — same rule as the admin and website,
/// so a section like "Shoe care" has one colour everywhere.
List<Color> autoCardColors(String name) {
  var h = 0;
  for (final c in name.toLowerCase().trim().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kCardPalette[h % kCardPalette.length];
}

Color? _hexColor(Object? v) {
  final h = '${v ?? ''}'.replaceAll('#', '').trim();
  final n = int.tryParse(h, radix: 16);
  return h.length == 6 && n != null ? Color(0xFF000000 | n) : null;
}

/// Card colours for a service map: picked in the admin, else our own look, else automatic.
List<Color> serviceCardColors(Map<String, dynamic> service) {
  final raw = service['cardColors'];
  if (raw is List && raw.length > 1) {
    final a = _hexColor(raw[0]), b = _hexColor(raw[1]);
    if (a != null && b != null) return [a, b];
  }
  return ServicePriceConfig.forTitle('${service['title'] ?? service['name'] ?? ''}').gradientColors;
}

class ServicePriceConfig {
  final List<Color> gradientColors;
  final String? flag;
  final bool hasStarInFlag;
  final String assetImage;
  final double rotationDeg;
  final String defaultPrice;
  final String defaultPriceLabel;
  final List<String> defaultTags;
  final String defaultDescription;
  final Offset? sparkleOffset;

  const ServicePriceConfig({
    required this.gradientColors,
    this.flag,
    this.hasStarInFlag = false,
    required this.assetImage,
    this.rotationDeg = 0.0,
    required this.defaultPrice,
    required this.defaultPriceLabel,
    required this.defaultTags,
    required this.defaultDescription,
    this.sparkleOffset,
  });

  static ServicePriceConfig forTitle(String title) {
    final lower = title.toLowerCase().trim();
    if (lower.contains('special') || lower.contains('leather') || lower.contains('suede')) {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFFFD9A8), Color(0xFFF5B66B)],
        flag: 'NEW',
        hasStarInFlag: true,
        assetImage: 'assets/images/special-items.png',
        rotationDeg: -6.0,
        defaultPrice: '18.95',
        defaultPriceLabel: 'From · per item',
        defaultTags: ['Leather', 'Suede'],
        defaultDescription: 'Leather and suede deep cleaned and polished, plus wedding dresses, shoes and bags.',
      );
    } else if (lower.contains('dry clean')) {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFFFA3A8), Color(0xFFFF7B86)],
        flag: 'POPULAR',
        hasStarInFlag: true,
        assetImage: 'assets/images/dry-cleaning.png',
        rotationDeg: 7.0,
        defaultPrice: '1.45',
        defaultPriceLabel: 'From · per item',
        defaultTags: ['Dry cleaning', 'Ironing'],
        defaultDescription: 'Expert dry cleaning for delicate fabrics and formal wear.',
      );
    } else if (lower.contains('duvet') || lower.contains('bedding')) {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFA9E3FF), Color(0xFF7BCBFB)],
        flag: 'NEW',
        hasStarInFlag: false,
        assetImage: 'assets/images/duvets-bedding.png',
        rotationDeg: -8.0,
        defaultPrice: '14.95',
        defaultPriceLabel: 'From · per item',
        defaultTags: ['Bedding', 'Hygienic'],
        defaultDescription: 'Feather & synthetic duvets, pillows, bedspreads & throws.',
        sparkleOffset: Offset(8, 74),
      );
    } else if (lower.contains('ironing') || lower == 'iron') {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFDCD0FF), Color(0xFFB9A8FF)],
        assetImage: 'assets/images/ironing.png',
        rotationDeg: 0.0,
        defaultPrice: '1.00',
        defaultPriceLabel: 'From · per item',
        defaultTags: ['Ironing', 'Crisp Press'],
        defaultDescription: 'Everyday ironing for shirts, trousers, linens & garments.',
      );
    } else if (lower.contains('household') || lower.contains('linens')) {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFA8F0D5), Color(0xFF5EDBB0)],
        assetImage: 'assets/images/household.png',
        rotationDeg: 6.0,
        defaultPrice: '1.45',
        defaultPriceLabel: 'From · per item',
        defaultTags: ['Household', 'Home care'],
        defaultDescription: 'Tablecloths, curtains, bed sheets & household fabrics.',
        sparkleOffset: Offset(90, -6),
      );
    } else if (lower.contains('wash & fold') || lower.contains('service wash') || lower == 'wash') {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFFFE58C), Color(0xFFFFCB4F)],
        flag: 'PER KG',
        hasStarInFlag: false,
        assetImage: 'assets/images/laundry.png',
        rotationDeg: -5.0,
        defaultPrice: '4.00',
        defaultPriceLabel: 'From · by weight',
        defaultTags: ['Wash & Fold', 'Doorstep weighing'],
        defaultDescription: 'Everyday wash, dry & fold service by weight.',
      );
    } else if (lower.contains('wash & iron') || lower.contains('wash and iron')) {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFC9F78E), Color(0xFFA6EB60)],
        flag: 'PER KG',
        hasStarInFlag: false,
        assetImage: 'assets/images/shirts.png',
        rotationDeg: 6.0,
        defaultPrice: '1.95',
        defaultPriceLabel: 'From · per item',
        defaultTags: ['Wash & Iron', 'Crisp press'],
        defaultDescription: 'Washed, tumble-dried and crisply pressed shirts & trousers.',
      );
    } else if (lower.contains('laundry')) {
      return const ServicePriceConfig(
        gradientColors: [Color(0xFFFFE58C), Color(0xFFFFCB4F)],
        assetImage: 'assets/images/laundry.png',
        rotationDeg: -5.0,
        defaultPrice: '1.95',
        defaultPriceLabel: 'By weight · 6kg',
        defaultTags: ['Wash', 'Ironing'],
        defaultDescription: 'For everyday laundry, bedsheets and towels.',
      );
    }

    // Any other service (added in the admin): its own automatic colour, not always pink
    return ServicePriceConfig(
      gradientColors: autoCardColors(title),
      assetImage: 'assets/images/dry-cleaning.png',
      rotationDeg: 4.0,
      defaultPrice: '4.95',
      defaultPriceLabel: 'From · per item',
      defaultTags: ['Service', 'Care'],
      defaultDescription: 'Professional care for all garments and textiles.',
    );
  }
}

/// Squiggly underline painter for the "Prices" header
/// SVG path: M2 7c7-7 13-7 20 0s13 7 20 0 13-7 20 0 13 7 20 0 13-7 20 0
class SquigglyUnderlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const SquigglyUnderlinePainter({
    this.color = const Color(0xFFFFD25E),
    this.strokeWidth = 4.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final waveCount = 6;
    final waveLength = size.width / waveCount;
    final midY = size.height * 0.55;
    final amplitude = size.height * 0.42;

    path.moveTo(2, midY);
    for (int i = 0; i < waveCount; i++) {
      final startX = 2 + i * waveLength;
      final controlX1 = startX + waveLength * 0.35;
      final controlY1 = (i % 2 == 0) ? midY - amplitude : midY + amplitude;
      final controlX2 = startX + waveLength * 0.65;
      final controlY2 = (i % 2 == 0) ? midY - amplitude : midY + amplitude;
      final endX = startX + waveLength;
      final endY = midY;
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, endX, endY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SquigglyUnderlinePainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

/// Dot Grid Texture Painter (HTML .bg .dots)
class DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double dotRadius;

  const DotGridPainter({
    this.color = const Color(0x400B1F5B),
    this.spacing = 10.0,
    this.dotRadius = 1.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double y = dotRadius; y < size.height; y += spacing) {
      for (double x = dotRadius; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) =>
      color != oldDelegate.color || spacing != oldDelegate.spacing;
}

/// 4-point Sparkle Star (HTML .sp)
class SparkleStarWidget extends StatelessWidget {
  final double size;
  final Color color;

  const SparkleStarWidget({
    super.key,
    this.size = 14.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparkleStarPainter(color: color),
      ),
    );
  }
}

class _SparkleStarPainter extends CustomPainter {
  final Color color;

  const _SparkleStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0x3502104C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final sx = size.width / 24.0;
    final sy = size.height / 24.0;

    Path createPath(double dx, double dy) {
      final p = Path();
      p.moveTo(12 * sx + dx, 0 * sy + dy);
      p.cubicTo(12.8 * sx + dx, 6.2 * sy + dy, 17.8 * sx + dx, 11.2 * sy + dy, 24 * sx + dx, 12 * sy + dy);
      p.cubicTo(17.8 * sx + dx, 12.8 * sy + dy, 12.8 * sx + dx, 17.8 * sy + dy, 12 * sx + dx, 24 * sy + dy);
      p.cubicTo(11.2 * sx + dx, 17.8 * sy + dy, 6.2 * sx + dx, 12.8 * sy + dy, 0 * sx + dx, 12 * sy + dy);
      p.cubicTo(6.2 * sx + dx, 11.2 * sy + dy, 11.2 * sx + dx, 6.2 * sy + dy, 12 * sx + dx, 0 * sy + dy);
      p.close();
      return p;
    }

    canvas.drawPath(createPath(0, 1.5), shadowPaint);
    canvas.drawPath(createPath(0, 0), paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) => color != oldDelegate.color;
}

/// Marker-highlighted price text widget
class MarkerHighlightText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color highlightColor;

  const MarkerHighlightText({
    super.key,
    required this.text,
    required this.style,
    this.highlightColor = const Color(0xB3FFFFFF), // rgba(255,255,255,.7)
  });

  @override
  Widget build(BuildContext context) {
    final fs = style.fontSize ?? 26.0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 2,
          height: fs * 0.40,
          child: Container(
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(text, style: style),
        ),
      ],
    );
  }
}

/// Sections whose art ships inside the app as round 3D badges (look better than the flat icon).
bool hasBundledArt(String iconUrl) => const ['dry-cleaning', 'duvets-bedding', 'household', 'laundry', 'special-items'].any((k) => iconUrl.endsWith('/$k.png'));

/// Icon picked in the admin panel, shown on a white disc like the bundled price badges.
Widget hostedServiceIcon(String url, {required double size, String fallback = ''}) => Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .14),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback.isEmpty
            ? const Icon(Icons.dry_cleaning_rounded, color: Color(0xFF0B1F5B))
            : Image.asset(fallback, fit: BoxFit.contain),
      ),
    );

/// Helper to render service image (admin-picked icon, then bundled asset PNG, then network / data / fallback)
Widget buildServiceIcon(Map<String, dynamic> item, ServicePriceConfig config, {required double size}) {
  // Icon chosen in the admin panel (hosted image) wins, so new sections get their own icon
  final hosted = (item['imageUrl'] ?? '').toString();
  if (hosted.startsWith('http') && !hasBundledArt(hosted)) return hostedServiceIcon(hosted, size: size, fallback: config.assetImage);
  // If asset exists, load it
  if (config.assetImage.isNotEmpty) {
    return Image.asset(
      config.assetImage,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackIcon(item, size),
    );
  }
  return _fallbackIcon(item, size);
}

Widget _fallbackIcon(Map<String, dynamic> item, double size) {
  final imageUrl = (item['imageUrl'] ?? '').toString();
  final iconPath = item['iconPath'];

  Widget placeholder() => Container(
        width: size,
        height: size,
        color: const Color(0xFFE8F0FF),
        child: const Icon(Icons.dry_cleaning_rounded, color: Color(0xFF0B1F5B), size: 30),
      );

  if (imageUrl.startsWith('data:image/')) {
    try {
      final Uint8List bytes = base64Decode(imageUrl.split(',')[1]);
      return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => placeholder());
    } catch (_) {
      return placeholder();
    }
  }
  if (imageUrl.isNotEmpty) {
    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }
  if (iconPath != null) {
    return Image.asset(
      iconPath.toString(),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }
  return placeholder();
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED HERO PRICE CARD (e.g. Dry Clean)
// ─────────────────────────────────────────────────────────────────────────────

class FeaturedPriceCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const FeaturedPriceCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<FeaturedPriceCard> createState() => _FeaturedPriceCardState();
}

class _FeaturedPriceCardState extends State<FeaturedPriceCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final title = (widget.item['title'] ?? 'Dry Clean').toString();
    final config = ServicePriceConfig.forTitle(title);
    final rawPrice = (widget.item['price'] ?? config.defaultPrice).toString();
    final priceStr = rawPrice.startsWith('£') ? rawPrice : '£$rawPrice';

    final description = (widget.item['description'] ?? config.defaultDescription).toString();
    final rawTags = (widget.item['tags'] as List?)?.map((e) => e.toString()).toList() ?? config.defaultTags;
    final tags = rawTags.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Card Body
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: const Alignment(-0.6, -1.0),
                    end: const Alignment(0.6, 1.0),
                    colors: serviceCardColors(widget.item),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF02104C).withOpacity(0.38),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.55),
                      blurRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      // Background Disc (top right)
                      Positioned(
                        right: -70,
                        top: -70,
                        width: 220,
                        height: 220,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.34),
                          ),
                        ),
                      ),
                      // Background Ring (bottom left)
                      Positioned(
                        left: -46,
                        bottom: -46,
                        width: 120,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.24), width: 15),
                          ),
                        ),
                      ),
                      // Background Dots (bottom right)
                      const Positioned(
                        right: 20,
                        bottom: 85,
                        width: 70,
                        height: 40,
                        child: CustomPaint(
                          painter: DotGridPainter(color: Color(0x380B1F5B)),
                        ),
                      ),
                      // Foreground Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            // Title
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1F5B),
                                letterSpacing: -0.9,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 7),
                            // Description (constrained to left side so it doesn't overlap 128px icon)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 195),
                              child: Text(
                                description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1F3274),
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Tags
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: tags.map((t) => _buildTag(t)).toList(),
                            ),
                            const SizedBox(height: 20),
                            // Footer (Price & CTA)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        config.defaultPriceLabel.toUpperCase(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1F3274),
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      MarkerHighlightText(
                                        text: priceStr,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 44,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0B1F5B),
                                          letterSpacing: -1.4,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // CTA Button: "See prices"
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.only(left: 18, right: 7),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: const Color(0xFF0B1F5B),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF02104C).withOpacity(0.34),
                                        blurRadius: 16,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'See prices',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 17,
                                          color: Color(0xFF0B1F5B),
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
                    ],
                  ),
                ),
              ),

              // Pop-out Floating Sticker Icon (128x128 at top: -26, right: 16, rotated 7deg)
              Positioned(
                top: -26,
                right: 16,
                child: Transform.rotate(
                  angle: 7.0 * math.pi / 180,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 0,
                          spreadRadius: 7,
                        ),
                        BoxShadow(
                          color: const Color(0xFF02104C).withOpacity(0.36),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: buildServiceIcon(widget.item, config, size: 120),
                      ),
                    ),
                  ),
                ),
              ),

              // Sparkle Star at right: 155, top: -4
              const Positioned(
                right: 155,
                top: -4,
                child: SparkleStarWidget(size: 15),
              ),
              // Sparkle Star at right: 12, top: 118
              const Positioned(
                right: 12,
                top: 118,
                child: SparkleStarWidget(size: 11),
              ),

              // Flag Badge at top: -13, left: 16, rotated -4deg
              Positioned(
                top: -13,
                left: 16,
                child: Transform.rotate(
                  angle: -4.0 * math.pi / 180,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1F5B),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF02104C).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFD25E)),
                        const SizedBox(width: 5),
                        Text(
                          'POPULAR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF0B1F5B).withOpacity(0.42), width: 1.5),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0B1F5B),
          letterSpacing: 0.6,
          height: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGGERED 2-COLUMN PRICE CARD
// ─────────────────────────────────────────────────────────────────────────────

class StaggeredPriceCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final int index;

  const StaggeredPriceCard({
    super.key,
    required this.item,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<StaggeredPriceCard> createState() => _StaggeredPriceCardState();
}

class _StaggeredPriceCardState extends State<StaggeredPriceCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final title = (widget.item['title'] ?? '').toString();
    final config = ServicePriceConfig.forTitle(title);
    final rawPrice = (widget.item['price'] ?? config.defaultPrice).toString();
    final priceStr = rawPrice.startsWith('£') ? rawPrice : '£$rawPrice';

    final description = (widget.item['description'] ?? config.defaultDescription).toString();
    final rawTags = (widget.item['tags'] as List?)?.map((e) => e.toString()).toList() ?? config.defaultTags;
    final tags = rawTags.take(2).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Card Container
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: const Alignment(-0.6, -1.0),
                    end: const Alignment(0.6, 1.0),
                    colors: serviceCardColors(widget.item),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF02104C).withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.55),
                      blurRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Background Disc (top right)
                      Positioned(
                        right: -50,
                        top: -50,
                        width: 150,
                        height: 150,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.34),
                          ),
                        ),
                      ),
                      // Background Ring (bottom left)
                      Positioned(
                        left: -46,
                        bottom: -46,
                        width: 120,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.24), width: 15),
                          ),
                        ),
                      ),
                      // Background Dots (top left)
                      const Positioned(
                        left: 15,
                        top: 20,
                        width: 58,
                        height: 38,
                        child: CustomPaint(
                          painter: DotGridPainter(color: Color(0x350B1F5B)),
                        ),
                      ),
                      // Foreground Card Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 58, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1F5B),
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 7),
                            // Description
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F3274),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Tags
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: tags.map((t) => _buildTag(t)).toList(),
                            ),
                            const SizedBox(height: 16),
                            // Footer Row: Price & Circular Go Arrow
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        config.defaultPriceLabel.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1F3274),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: MarkerHighlightText(
                                          text: priceStr,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0B1F5B),
                                            letterSpacing: -0.8,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Circular .go arrow button
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0B1F5B),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF02104C).withOpacity(0.32),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Pop-out Sticker Icon (80x80 at top: -20, right: 10)
              Positioned(
                top: -20,
                right: 10,
                child: Transform.rotate(
                  angle: config.rotationDeg * math.pi / 180,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 0,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: const Color(0xFF02104C).withOpacity(0.34),
                          blurRadius: 22,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: buildServiceIcon(widget.item, config, size: 74),
                      ),
                    ),
                  ),
                ),
              ),

              // Optional Sparkle Star
              if (config.sparkleOffset != null)
                Positioned(
                  right: config.sparkleOffset!.dx,
                  top: config.sparkleOffset!.dy,
                  child: const SparkleStarWidget(size: 12),
                ),

              // Flag Badge (e.g. "NEW") at top: -12, left: 12
              if (config.flag != null)
                Positioned(
                  top: -12,
                  left: 12,
                  child: Transform.rotate(
                    angle: -4.0 * math.pi / 180,
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1F5B),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF02104C).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          config.flag!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF0B1F5B).withOpacity(0.42), width: 1.5),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0B1F5B),
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compatibility Wrapper: ServicePriceCard
// ─────────────────────────────────────────────────────────────────────────────

class ServicePriceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final int index;
  final bool isFeatured;

  const ServicePriceCard({
    super.key,
    required this.item,
    required this.onTap,
    this.index = 0,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? '').toString().toLowerCase();
    if (isFeatured || title.contains('dry clean')) {
      return FeaturedPriceCard(item: item, onTap: onTap);
    }
    return StaggeredPriceCard(item: item, onTap: onTap, index: index);
  }
}
