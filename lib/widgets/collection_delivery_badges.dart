import 'package:flutter/material.dart';

/// The exact Collection calendar & clock illustration badge painter from Collection_&_Delivery.html
class CollectionBadgePainter extends CustomPainter {
  const CollectionBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64.0, size.height / 64.0);

    final strokeDark = Paint()
      ..color = const Color(0xFF14173F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 1. Calendar Body
    final bodyRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 12, 44, 42),
      const Radius.circular(7),
    );
    canvas.drawRRect(bodyRRect, fillWhite);
    canvas.drawRRect(bodyRRect, strokeDark);

    // 2. Purple Top Bar
    final topBarPath = Path()
      ..moveTo(8, 19)
      ..arcToPoint(const Offset(15, 12), radius: const Radius.circular(7))
      ..lineTo(45, 12)
      ..arcToPoint(const Offset(52, 19), radius: const Radius.circular(7))
      ..lineTo(52, 26)
      ..lineTo(8, 26)
      ..close();
    canvas.drawPath(topBarPath, Paint()..color = const Color(0xFF6D4AFF));
    canvas.drawPath(topBarPath, strokeDark);

    // 3. Two Ring Loops at Top
    final ringPaint = Paint()
      ..color = const Color(0xFF14173F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(20, 7), const Offset(20, 18), ringPaint);
    canvas.drawLine(const Offset(40, 7), const Offset(40, 18), ringPaint);

    // 4. Grid dashes
    canvas.drawLine(const Offset(17, 36), const Offset(23, 36), ringPaint);
    canvas.drawLine(const Offset(28, 36), const Offset(34, 36), ringPaint);
    canvas.drawLine(const Offset(39, 36), const Offset(45, 36), ringPaint);
    canvas.drawLine(const Offset(17, 45), const Offset(23, 45), ringPaint);
    canvas.drawLine(const Offset(28, 45), const Offset(34, 45), ringPaint);

    // 5. Clock Circle at Bottom-Right
    const clockCenter = Offset(47, 46);
    canvas.drawCircle(clockCenter, 12.5, Paint()..color = const Color(0xFFFFC73A));
    canvas.drawCircle(clockCenter, 12.5, strokeDark);

    // 6. Clock Hands
    final handPath = Path()
      ..moveTo(47, 39)
      ..lineTo(47, 46.5)
      ..lineTo(51.5, 49.5);
    canvas.drawPath(handPath, strokeDark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The exact Delivery Van illustration badge painter from Collection_&_Delivery.html
class DeliveryBadgePainter extends CustomPainter {
  const DeliveryBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64.0, size.height / 64.0);

    final strokeDark = Paint()
      ..color = const Color(0xFF14173F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Motion Speed Lines on left
    canvas.drawLine(const Offset(2, 24), const Offset(7, 24), strokeDark);
    canvas.drawLine(const Offset(4, 31), const Offset(8, 31), strokeDark);

    // 2. Van Body Outline & White Fill
    final bodyPath = Path()
      ..moveTo(10, 46)
      ..lineTo(10, 21)
      ..arcToPoint(const Offset(15, 16), radius: const Radius.circular(5))
      ..lineTo(37, 16)
      ..arcToPoint(const Offset(40, 19), radius: const Radius.circular(3))
      ..lineTo(40, 25)
      ..lineTo(48.5, 25)
      ..arcToPoint(const Offset(50.9, 26.2), radius: const Radius.circular(3))
      ..lineTo(59, 36.5)
      ..lineTo(59, 46)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(10, 31, 30, 7), Paint()..color = const Color(0xFF12A38A));
    canvas.drawPath(bodyPath, strokeDark);

    // 3. Windshield
    final winPath = Path()
      ..moveTo(43.5, 28.5)
      ..lineTo(47.7, 28.5)
      ..lineTo(54, 36.5)
      ..lineTo(43.5, 36.5)
      ..close();
    canvas.drawPath(winPath, Paint()..color = const Color(0xFFBFE8FF));
    canvas.drawPath(
      winPath,
      Paint()
        ..color = const Color(0xFF14173F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );

    // 4. Wheels
    for (final cx in [22.0, 49.0]) {
      canvas.drawCircle(Offset(cx, 47), 7.0, Paint()..color = const Color(0xFF14173F));
      canvas.drawCircle(Offset(cx, 47), 2.6, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
