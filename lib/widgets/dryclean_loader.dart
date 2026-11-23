import 'dart:async';
import 'package:flutter/material.dart';
import 'dryclean_splash_view.dart';

/// Full-screen "DrycleanPlus" signature loader.
///
/// Features the exact same onboarding entrance animation:
/// - Swinging hanger with hook
/// - Cursive "DrycleanPlus+" script logo
/// - Wavy animated underline
/// - Cycling tag pill ("Collecting from your door", "Cleaning with care", "Pressing every crease")
/// - Indicator dots
/// - Full London skyline, London Eye, double-decker red bus, and animated DC+ delivery van.
///
/// • [autoDismiss] true (default): plays cycles, fades out and pops itself.
/// • [autoDismiss] false: keeps looping until the caller closes it with `Navigator.pop`.
class DrycleanLoader extends StatefulWidget {
  final int durationMs;
  final int loops;
  final bool autoDismiss;

  const DrycleanLoader({
    super.key,
    this.durationMs = 1800,
    this.loops = 2,
    this.autoDismiss = true,
  });

  @override
  State<DrycleanLoader> createState() => _DrycleanLoaderState();
}

class _DrycleanLoaderState extends State<DrycleanLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _exitController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    if (widget.autoDismiss) {
      final totalMs = widget.durationMs * widget.loops;
      _dismissTimer = Timer(Duration(milliseconds: totalMs), () async {
        if (!mounted) return;
        await _exitController.forward();
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1546C0),
        body: FadeTransition(
          opacity: _exitController.drive(Tween(begin: 1.0, end: 0.0)),
          child: const DrycleanSplashView(
            autoCycle: true,
          ),
        ),
      ),
    );
  }
}
