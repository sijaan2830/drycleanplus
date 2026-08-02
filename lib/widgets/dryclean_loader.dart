import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'app_logo.dart';

class DrycleanLoader extends StatefulWidget {
  final int durationMs;
  final int loops;

  const DrycleanLoader({
    super.key,
    this.durationMs = 1200,
    this.loops = 3,
  });

  @override
  State<DrycleanLoader> createState() => _DrycleanLoaderState();
}

class _DrycleanLoaderState extends State<DrycleanLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;
  late Animation<double> _revealAnimation;
  int _loopCount = 0;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    _revealAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo, // Snappy fast reveal
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.forward();

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        _loopCount++;
        if (_loopCount < widget.loops) {
          _controller.reset();
          _controller.forward();
        } else {
          if (mounted) {
            setState(() => _isExiting = true);
            await _exitController.forward();
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: FadeTransition(
        opacity: _exitController.drive(Tween(begin: 1.0, end: 0.0)),
        child: ScaleTransition(
          scale: _exitController.drive(Tween(begin: 1.0, end: 0.95)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Signature Animation Container
                AnimatedBuilder(
                  animation: _revealAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // The actual logo with clipping to reveal
                        ClipRect(
                          clipper: _SignatureClipper(_revealAnimation.value),
                          child: const AppLogo(
                            fontSize: 48,
                            mainColor: Color(0xFF042407), // Extra Dark Green
                            secondaryColor: Colors.red,    // Red
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Signature "Underline" that also reveals with same curve
                AnimatedBuilder(
                  animation: _revealAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 150 * _revealAnimation.value,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF042407),
                            Colors.red.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Status Text
                const StatusText(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusText extends StatefulWidget {
  const StatusText({super.key});

  @override
  State<StatusText> createState() => _StatusTextState();
}

class _StatusTextState extends State<StatusText> with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    _dotController.addListener(() {
      int newCount = (_dotController.value * 4).floor();
      if (newCount != _dotCount) {
        setState(() => _dotCount = newCount % 4);
      }
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tumbling into freshness${'.' * _dotCount}',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.white.withOpacity(0.7),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SignatureClipper extends CustomClipper<Rect> {
  final double progress;
  _SignatureClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_SignatureClipper oldClipper) => oldClipper.progress != progress;
}
