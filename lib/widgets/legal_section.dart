import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'app_ui.dart';

/// One numbered section of a legal / help page (Terms, Privacy, ...).
/// Titles like "3. Orders and Payments" get a number badge; lines starting with
/// "• " become bullet rows; blank lines become small gaps.
class LegalSection extends StatelessWidget {
  final String title;
  final String content;
  final int index;

  const LegalSection({super.key, required this.title, required this.content, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^(\d+)\.\s*(.*)$').firstMatch(title);
    final number = match?.group(1);
    final heading = match?.group(2) ?? title;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index.clamp(0, 6)) * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.ctaGradient),
                  child: number != null
                      ? Text(
                          number,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlueDark,
                          ),
                        )
                      : const Icon(Icons.article_rounded, size: 18, color: AppColors.primaryBlueDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    heading,
                    style: GoogleFonts.inter(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.white.withOpacity(0.16)),
            const SizedBox(height: 12),
            FormattedBody(content: content),
          ],
        ),
      ),
    );
  }
}

/// Renders plain text with "• " bullets and blank-line gaps (used by Terms, Privacy and FAQ).
class FormattedBody extends StatelessWidget {
  final String content;
  final double fontSize;
  const FormattedBody({super.key, required this.content, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: _lines());
  }

  List<Widget> _lines() {
    final out = <Widget>[];
    for (final raw in content.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        out.add(const SizedBox(height: 8));
      } else if (line.startsWith('•')) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.goldLight),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line.substring(1).trim(),
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      height: 1.55,
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: GoogleFonts.inter(fontSize: fontSize, height: 1.6, color: Colors.white.withOpacity(0.88)),
            ),
          ),
        );
      }
    }
    return out;
  }
}
