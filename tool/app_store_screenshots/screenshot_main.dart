// App Store screenshot entry point (not shipped in the app).
//
// Build:  flutter build web -t tool/app_store_screenshots/screenshot_main.dart
// Open:   http://localhost:PORT/?shot=home   (onboarding | home | prices |
//         service | prepaid | tracking | more | faq | select_services | membership)
//
// It runs the real DrycleanPlusApp with a demo customer so every screen can be
// captured at iPhone size without a device or a login.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drycleanplus_app/firebase_options.dart';
import 'package:drycleanplus_app/main.dart' as app;
import 'package:drycleanplus_app/models/booking_models.dart' as models;
import 'package:drycleanplus_app/screens/service_overview_screen.dart';
import 'package:drycleanplus_app/screens/track_order_screen.dart';
import 'package:drycleanplus_app/utils/guest_helper.dart';
import 'package:drycleanplus_app/utils/route_helpers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final shot = Uri.base.queryParameters['shot'] ?? 'onboarding';

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (shot != 'onboarding') {
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('is_guest', false);
    await prefs.setString('user_displayName', 'Sarah Thompson');
    await prefs.setString('user_email', 'sarah@example.com');
    await prefs.setString('user_firstName', 'Sarah');
    await prefs.setString('user_lastName', 'Thompson');
  }
  await GuestHelper.initialize();

  const tabRoutes = {
    'home': '/home',
    'prices': '/prices',
    'prepaid': '/prepaid',
    'more': '/more',
    'service': '/prices',
    'tracking': '/home',
    'faq': '/more',
    'select_services': '/home',
    'membership': '/more',
  };
  final initialRoute = tabRoutes[shot] ?? '/onboarding';

  // Status bar is always white (every screen has a blue header); the home
  // indicator turns dark where the bottom of the screen is white.
  final darkHomeIndicator = Uri.base.queryParameters['home'] == 'dark';
  runApp(_IPhoneFrame(
    darkHomeIndicator: darkHomeIndicator,
    child: app.DrycleanPlusApp(initialRoute: initialRoute),
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    switch (shot) {
      case 'service':
        nav.push(MaterialPageRoute(
          settings: const RouteSettings(name: '/service_overview'),
          builder: (_) => const ServiceOverviewScreen(serviceType: 'Dry Clean'),
        ));
      case 'tracking':
        nav.push(MaterialPageRoute(
          settings: const RouteSettings(name: '/track_order'),
          builder: (_) => TrackOrderScreen(order: _demoOrder()),
        ));
      case 'faq':
        nav.pushNamed('/faq');
      case 'select_services':
        nav.pushNamed('/select_services');
      case 'membership':
        nav.pushNamed('/membership');
    }
  });
}

models.Order _demoOrder() {
  final now = DateTime.now();
  return models.Order(
    id: 'appstore-demo-order',
    orderId: 'DCP-48213',
    status: 'cleaning',
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now.subtract(const Duration(hours: 3)),
    paymentMethod: 'sumup',
    transactionAmount: 46.50,
    bookingData: models.BookingData(
      selectedAddress: models.Address(
        id: 'demo-address',
        line1: '24 Kensington High Street',
        city: 'London',
        postalCode: 'W8 4PT',
        isDefault: true,
      ),
      collectionDate: 'Monday',
      collectionTime: '09:00 - 11:00',
      deliveryDate: 'Wednesday',
      deliveryTime: '18:00 - 20:00',
      firstName: 'Sarah',
      lastName: 'Thompson',
      email: 'sarah@example.com',
      selectedServices: const ['Dry Clean', 'Wash & Iron'],
      totalPrice: 46.50,
      paymentMethod: 'sumup',
      status: 'cleaning',
    ),
  );
}

/// Gives the app iPhone 16 safe areas (59pt top, 34pt bottom) and draws the
/// iOS status bar + home indicator on top, like a real device screenshot.
class _IPhoneFrame extends StatelessWidget {
  const _IPhoneFrame({required this.child, required this.darkHomeIndicator});
  final Widget child;
  final bool darkHomeIndicator;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    const insets = EdgeInsets.only(top: 59, bottom: 34);
    const color = Colors.white;
    final homeColor = darkHomeIndicator ? Colors.black : Colors.white;
    return MediaQuery(
      data: mq.copyWith(padding: insets, viewPadding: insets),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 54,
              child: const IgnorePointer(child: CustomPaint(painter: _StatusBarPainter(color))),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 139,
                    height: 5,
                    decoration: BoxDecoration(
                      color: homeColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBarPainter extends CustomPainter {
  const _StatusBarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    const cy = 30.0;

    // Time
    final tp = TextPainter(
      text: TextSpan(
        text: '9:41',
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: '.SF Pro Text',
          fontFamilyFallback: const ['Roboto', 'Arial'],
          letterSpacing: -0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(52 - tp.width / 2 + 2, cy - tp.height / 2));

    // Battery (right-most)
    final right = size.width - 26;
    final bodyW = 25.0, bodyH = 12.0;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(right - bodyW - 2, cy - bodyH / 2, bodyW, bodyH),
      const Radius.circular(3.8),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(right - bodyW, cy - bodyH / 2 + 2, bodyW - 4, bodyH - 4),
        const Radius.circular(2.2),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(right - 1, cy - 2, 1.6, 4), const Radius.circular(1)),
      Paint()..color = color.withValues(alpha: 0.4),
    );

    // Wi-Fi
    final wx = right - bodyW - 2 - 6 - 8.5;
    final wy = cy + 5.5;
    for (var i = 0; i < 3; i++) {
      final r = 3.0 + i * 4.0;
      final path = Path()
        ..moveTo(wx, wy)
        ..arcTo(Rect.fromCircle(center: Offset(wx, wy), radius: r), -2.35, 1.57, false)
        ..close();
      if (i == 0) {
        canvas.drawPath(path, fill);
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(wx, wy), radius: r),
          -2.35,
          1.57,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Cellular signal
    final sx = wx - 8.5 - 6 - 18;
    for (var i = 0; i < 4; i++) {
      final h = 4.0 + i * 2.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx + i * 4.8, cy + 6 - h, 3.2, h),
          const Radius.circular(1),
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StatusBarPainter old) => old.color != color;
}
