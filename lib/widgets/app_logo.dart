import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The official DrycleanPlus logo widget.
/// Now simplified and clean, relying on external overlays for advanced effects.
class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool isItalic;
  final bool showSecondaryIcon;
  final Color? mainColor;
  final Color? secondaryColor;

  const AppLogo({
    super.key,
    this.fontSize = 26,
    this.isItalic = true,
    this.showSecondaryIcon = true,
    this.mainColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.satisfy(
          fontSize: fontSize,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: 'Dryclean',
            style: TextStyle(
              color: mainColor ?? const Color(0xFF1B5E20), // Dark Green
            ),
          ),
          TextSpan(
            text: 'Plus',
            style: TextStyle(
              color: secondaryColor ?? Colors.red, // Red
            ),
          ),
          if (showSecondaryIcon)
            TextSpan(
              text: '+',
              style: TextStyle(
                color: secondaryColor ?? Colors.red,
                fontWeight: FontWeight.w900,
                fontSize: fontSize * 1.05, // Optimized alignment
              ),
            ),
        ],
      ),
    );
  }
}
