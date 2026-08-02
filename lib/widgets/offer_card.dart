import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

// ─── Internal color tokens (premium coupon palette) ───────────────────────────

class _C {
  static const navy      = Color(0xFF0B1630);
  static const navyDeep  = Color(0xFF060E1F);
  static const navyMid   = Color(0xFF0F1D3A);
  static const gold      = Color(0xFFC9A227);
  static const goldLight = Color(0xFFF7E27A);
  static const goldFaded = Color(0x28C9A227);
  static const white     = Color(0xFFFFFFFF);
  static const green     = Color(0xFF10B981);
  static const red       = Color(0xFFF87171);
  static const redFaded  = Color(0x2EEF4444);
  static const redBorder = Color(0x5AEF4444);
}

// ─── Painters ─────────────────────────────────────────────────────────────────

/// Conic gold gradient border around the whole card.
class _GoldBorderPainter extends CustomPainter {
  final double radius;
  const _GoldBorderPainter({this.radius = 26});

  @override
  void paint(Canvas canvas, Size size) {
    final rect  = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final shader = SweepGradient(
      colors: const [
        Color(0xFFC9A227),
        Color(0xFFF7E27A),
        Color(0xFFC9A227),
        Color(0xFFA07C10),
        Color(0xFFF7E27A),
        Color(0xFFC9A227),
      ],
    ).createShader(rect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader     = shader
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Premium Scalloped (Wavy) seal painter for the discount badge.
class _ScallopedSealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    const int segments = 24;
    const double pi = 3.1415926535897932;
    const double step = (2 * pi) / segments;
    
    final innerR = radius * 0.90;
    final outerR = radius;

    for (int i = 0; i < segments; i++) {
      final double startAngle = i * step;
      final double endAngle   = (i + 1) * step;
      final double midAngle   = startAngle + (step / 2);
      
      if (i == 0) {
        path.moveTo(
          center.dx + outerR * _cos(startAngle),
          center.dy + outerR * _sin(startAngle),
        );
      }
      
      // Arc / bump
      path.quadraticBezierTo(
        center.dx + (outerR * 1.08) * _cos(midAngle),
        center.dy + (outerR * 1.08) * _sin(midAngle),
        center.dx + outerR * _cos(endAngle),
        center.dy + outerR * _sin(endAngle),
      );
    }
    path.close();

    // ── Outer Metallic Gradient ──
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldLight,
          AppColors.gold,
          AppColors.goldDark,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // ── Shine Effect ──
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.4, 0.5, 0.6],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, shinePaint);

    // ── Inner Decorations ──
    final innerDecorationPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, radius * 0.8, innerDecorationPaint);

    // ── Shine ──
    canvas.drawPath(
      path,
      Paint()
        ..color       = Colors.white.withOpacity(0.3)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    
    // ── Inner ring ──
    canvas.drawCircle(
      center,
      innerR * 0.85,
      Paint()
        ..color       = Colors.black.withOpacity(0.15)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  static double _cos(double a) {
    double x = a % 6.28318530718;
    if (x < 0) x += 6.28318530718;
    double c = 1, t = 1;
    for (int i = 1; i <= 10; i++) {
        t *= -x * x / ((2 * i - 1) * (2 * i));
        c += t;
    }
    return c;
  }

  static double _sin(double a) {
    double x = a % 6.28318530718;
    if (x < 0) x += 6.28318530718;
    double s = x, t = x;
    for (int i = 1; i <= 10; i++) {
        t *= -x * x / ((2 * i) * (2 * i + 1));
        s += t;
    }
    return s;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Dashed wavy tear-line between the body and the code section.
class _WavyLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = _C.gold.withOpacity(0.3)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap   = StrokeCap.round;

    final w  = size.width;
    final cy = size.height / 2;

    final wavePath = Path();
    const waves = 10;
    final ww    = w / waves;

    wavePath.moveTo(0, cy);
    for (int i = 0; i < waves; i++) {
      wavePath.cubicTo(
        i * ww + ww / 4, cy - 8,
        i * ww + ww * 3 / 4, cy + 8,
        (i + 1) * ww, cy,
      );
    }

    // draw as dashes
    final metric  = wavePath.computeMetrics().first;
    final total   = metric.length;
    double pos    = 0;
    bool drawing  = true;

    while (pos < total) {
      final seg = drawing ? 5.0 : 5.0;
      final end = (pos + seg).clamp(0.0, total);
      if (drawing) canvas.drawPath(metric.extractPath(pos, end), paint);
      pos     = end;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── V2 Pattern Painter ──────────────────────────────────────────────────
class _V2PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ultra-subtle grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5;

    const double spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Modern floating dots
    final dotPaint = Paint()..color = AppColors.gold.withOpacity(0.035);
    const double dotSize = 1.2;
    const double dotSpacing = 16.0;
    
    for (double x = 0; x < size.width; x += dotSpacing) {
      for (double y = 0; y < size.height; y += dotSpacing) {
        if ((x + y) % (dotSpacing * 2) == 0) {
          canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── OfferCard ────────────────────────────────────────────────────────────────

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

class _OfferCardState extends State<OfferCard>
    with SingleTickerProviderStateMixin {
  // ── shimmer animation (kept from original) ────────────────────────────────
  late AnimationController _shimmerCtrl;
  late Animation<double>   _shimmerAnim;

  bool _copied = false;

  // ── gradient/icon palettes (kept from original) ───────────────────────────
  static const List<List<Color>> _gradients = [
    [Color(0xFF1A1F3A), Color(0xFF2D3561), Color(0xFF1A1F3A)],
    [Color(0xFF0D2137), Color(0xFF0F4C75), Color(0xFF0D2137)],
    [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    [Color(0xFF2C1654), Color(0xFF1A1040), Color(0xFF2C1654)],
    [Color(0xFF0B3D2E), Color(0xFF0D5C42), Color(0xFF0B3D2E)],
  ];

  static const List<IconData> _categoryIcons = [
    Icons.local_laundry_service_rounded,
    Icons.dry_cleaning_rounded,
    Icons.star_rounded,
    Icons.celebration_rounded,
    Icons.workspace_premium_rounded,
    Icons.bolt_rounded,
  ];

  List<Color> _getGradient(String id) =>
      _gradients[id.hashCode.abs() % _gradients.length];

  IconData _getIcon(String id) =>
      _categoryIcons[id.hashCode.abs() % _categoryIcons.length];

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── copy helper ───────────────────────────────────────────────────────────
  void _copyCode(String code) async {
    if (widget.isUsed) return;
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data       = widget.offer;
    final expiryDate = data['expiryDate'] as DateTime?;
    final bool isExpired =
        expiryDate != null && expiryDate.isBefore(DateTime.now());
    final String tag       = data['tag']?.toString() ?? '';
    final String image     = data['image']?.toString() ?? '';
    final String promoCode = data['discountCode']?.toString() ?? '';
    final String offerId   = data['id']?.toString() ?? data['title'] ?? 'x';
    final double discountVal = (data['discountValue'] as num?)?.toDouble() ?? 
                                (data['discountPct'] as num?)?.toDouble() ?? 0.0;
    final String discountType = data['discountType'] as String? ?? 'percentage';
    final bool   hasImage  = image.isNotEmpty;

    final gradient = _getGradient(offerId);
    final cardIcon = _getIcon(offerId);

    int? daysLeft;
    if (expiryDate != null && !isExpired) {
      daysLeft = expiryDate.difference(DateTime.now()).inDays;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: CustomPaint(
        painter: const _GoldBorderPainter(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isUsed ? null : widget.onTap,
              splashColor: AppColors.gold.withOpacity(0.1),
              highlightColor: Colors.transparent,
              child: Stack(
                children: [
                  // ── navy base + grid pattern ────────────────────────
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _C.navy,
                            _C.navyDeep,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _V2PatternPainter()),
                  ),

                  // ── original gradient/image background ─────────────
                  // (kept so image-based offers still look great)
                  if (hasImage)
                    Positioned.fill(
                      child: _buildImageBackground(image, offerId),
                    )
                  else
                    Positioned.fill(
                      child: _buildGradientBackground(gradient),
                    ),

                  // ── shimmer overlay (kept from original) ───────────
                  Positioned.fill(
                    child: _buildShimmerOverlay(),
                  ),

                  // ── card content ───────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopSection(
                        data: data,
                        tag: tag,
                        isExpired: isExpired,
                        cardIcon: cardIcon,
                        daysLeft: daysLeft,
                        promoCode: promoCode,
                        discountVal: discountVal,
                        discountType: discountType,
                      ),
                      _buildTearLine(context),
                      _buildCodeBar(promoCode),
                      _buildStatusBar(expiryDate, isExpired, daysLeft),
                    ],
                  ),

                  // ── expired overlay ───────────────────────────────
                  if (isExpired)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black.withOpacity(0.55),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.red.shade300, width: 1),
                            ),
                            child: Text(
                              'EXPIRED',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade300,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── consumed overlay ──────────────────────────────
                  if (widget.isUsed && !isExpired)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black.withOpacity(0.55),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: AppColors.gold, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'ALREADY USED',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gold,
                                    letterSpacing: 2,
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
          ),
        ),
      ),
    );
  }

  // ── background builders (kept from original) ──────────────────────────────

  Widget _buildImageBackground(String image, String offerId) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildGradientBackground(_getGradient(offerId)),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBackground(List<Color> gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient.first.withOpacity(0.4),
            gradient.last.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.08),
                    AppColors.gold.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -10,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlueLight.withOpacity(0.05),
                    AppColors.primaryBlueLight.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [
              (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
              _shimmerAnim.value.clamp(0.0, 1.0),
              (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.04),
              Colors.transparent,
            ],
          ).createShader(bounds),
          child: Container(color: Colors.white),
        );
      },
    );
  }

  // ── top section ───────────────────────────────────────────────────────────

  Widget _buildTopSection({
    required Map<String, dynamic> data,
    required String tag,
    required bool isExpired,
    required IconData cardIcon,
    required int? daysLeft,
    required String promoCode,
    required double discountVal,
    required String discountType,
  }) {
    return Padding(
      // REDUCED: top padding from 14 to 10, bottom to 8
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Premium Scalloped Seal with Discount ──────────────
          _buildSealColumn(cardIcon, discountVal, discountType),
          const SizedBox(width: 14),
 
          // ── Text Content ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (tag.isNotEmpty)
                      _TagPill(label: tag.toUpperCase(), isHot: true),
                    if (widget.isUsed)
                      const _TagPill(label: 'USED', isHot: false),
                    if (daysLeft != null && daysLeft <= 7 && !isExpired && !widget.isUsed)
                      _UrgencyPill(
                        label: daysLeft == 0 ? 'ENDS TODAY' : 'ENDS IN ${daysLeft}D',
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['title'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  // ── seal (Premium scalloped sticker) ─────────────────────────────────────────────
 
  Widget _buildSealColumn(IconData cardIcon, double discountVal, String discountType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 62, // REDUCED seal size from 72 to 62
          height: 62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(62, 62),
                painter: _ScallopedSealPainter(),
              ),
              // Percentage / Value Display
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (discountType == 'fixed')
                        Text('£', 
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: _C.navy)),
                      Text(
                        discountType == 'percentage' 
                            ? discountVal.toInt().toString() 
                            : discountVal.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _C.navy, // NAVY text on gold
                          height: 1,
                        ),
                      ),
                      if (discountType == 'percentage')
                        Text('%', 
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: _C.navy)),
                    ],
                  ),
                  Text(
                    'OFF',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _C.navy.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'EXCLUSIVE',
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: AppColors.gold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── wavy tear line ────────────────────────────────────────────────────────

  Widget _buildTearLine(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: 14, // REDUCED height from 22 to 14
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _WavyLinePainter()),
          ),
          // left notch cutout
          Positioned(
            left: -10, top: 1,
            child: Container(
              width: 18, height: 12, // REDUCED notch size
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topRight:    Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),
          ),
          // right notch cutout
          Positioned(
            right: -10, top: 3,
            child: Container(
              width: 20, height: 16,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── promo code bar ────────────────────────────────────────────────────────

  Widget _buildCodeBar(String promoCode) {
    // If no code, show original inline promo widget style (kept from original)
    if (promoCode.isEmpty) return const SizedBox.shrink();

    return Container(
      color: _C.navyMid,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // REDUCED vertical padding
      child: Row(
        children: [
          // code display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USE PROMO CODE',
                  style: GoogleFonts.inter(
                    fontSize: 8, // REDUCED font
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold.withOpacity(0.55),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  promoCode,
                  style: GoogleFonts.inter(
                    fontSize: 18, // REDUCED font
                    fontWeight: FontWeight.w900,
                    color: widget.isUsed ? AppColors.gold.withOpacity(0.3) : AppColors.gold,
                    letterSpacing: 2,
                    decoration: widget.isUsed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          // tap-to-copy pill button
          GestureDetector(
            onTap: widget.isUsed ? null : () => _copyCode(promoCode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8), // REDUCED padding
              decoration: BoxDecoration(
                color: widget.isUsed 
                    ? Colors.white.withOpacity(0.05)
                    : (_copied ? _C.green.withOpacity(0.15) : Colors.transparent),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: widget.isUsed 
                      ? Colors.white.withOpacity(0.2)
                      : (_copied ? _C.green : AppColors.gold),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isUsed 
                        ? Icons.check_circle_rounded 
                        : (_copied ? Icons.check_circle_rounded : Icons.copy_rounded),
                    size: 14,
                    color: widget.isUsed 
                        ? Colors.white.withOpacity(0.3)
                        : (_copied ? _C.green : AppColors.gold),
                  ),
                  const SizedBox(width: 7),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      widget.isUsed 
                          ? 'Used' 
                          : (_copied ? 'Copied!' : 'Tap to copy'),
                      key: ValueKey(widget.isUsed ? 'used' : _copied.toString()),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.isUsed 
                            ? Colors.white.withOpacity(0.3)
                            : (_copied ? _C.green : AppColors.gold),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── status / expiry bar ───────────────────────────────────────────────────
  // (merged from original _buildBottomBar)

  Widget _buildStatusBar(
    DateTime? expiryDate,
    bool isExpired,
    int? daysLeft,
  ) {
    final dotColor = isExpired
        ? Colors.red
        : daysLeft != null && daysLeft <= 7
            ? Colors.orange
            : const Color(0xFF10B981);

    final expiryLabel = expiryDate != null
        ? (isExpired
            ? 'Expired ${DateFormat('MMM dd').format(expiryDate)}'
            : daysLeft == 0
                ? 'Ends today'
                : daysLeft != null && daysLeft <= 30
                    ? '$daysLeft days left'
                    : 'Until ${DateFormat('MMM dd, yyyy').format(expiryDate)}')
        : 'Limited time offer';

    return Container(
      color: _C.navyDeep,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7), // REDUCED vertical padding
      child: Row(
        children: [
          // validity dot (kept from original)
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isExpired ? 'Offer expired' : 'Offer active',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
            ),
          ),

          const Spacer(),

          // clock + expiry (kept from original)
          Icon(
            Icons.access_time_rounded,
            size: 13,
            color: isExpired
                ? Colors.red.withOpacity(0.8)
                : Colors.white.withOpacity(0.45),
          ),
          const SizedBox(width: 5),
          Text(
            expiryLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isExpired
                  ? Colors.red.withOpacity(0.8)
                  : Colors.white.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small sub-widgets ────────────────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  final String label;
  final bool   isHot;
  const _TagPill({required this.label, this.isHot = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: isHot ? AppColors.gold : AppColors.gold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: isHot ? const Color(0xFF0D1A3A) : AppColors.gold,
            letterSpacing: 1,
          ),
        ),
      );
}

class _UrgencyPill extends StatelessWidget {
  final String label;
  const _UrgencyPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _C.redFaded,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.redBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 10,
              color: _C.red,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: _C.red,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
}