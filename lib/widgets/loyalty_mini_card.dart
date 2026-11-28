import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/loyalty_provider.dart';
import '../screens/loyalty_screen.dart';
import '../widgets/app_ui.dart';

/// Subtle one-line frosted hint pill on HomeScreen pointing to the full Loyalty Card in More.
class LoyaltyMiniCard extends StatelessWidget {
  const LoyaltyMiniCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoyaltyProvider>(
      builder: (context, lp, _) {
        if (!lp.isSignedIn) return const SizedBox.shrink();

        final bool hasCredit = lp.availableCredit > 0;
        final String headline = hasCredit
            ? '£${lp.availableCredit.toStringAsFixed(2)} free loyalty credit ready'
            : 'Loyalty Card · ${lp.currentCount} of 5 paid orders';
        final String subline = hasCredit
            ? '${lp.currentCount}/5 in Round ${lp.activeRound} · Tap to view rewards'
            : (lp.currentCount > 0
                ? '£${lp.nextRewardBuilding.toStringAsFixed(2)} credit building · Every 5th earns avg free'
                : 'Complete 5 orders, get the average FREE');

        return GestureDetector(
          onTap: () => Navigator.of(context).push(smoothRoute(const LoyaltyScreen(), name: '/loyalty')),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasCredit
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: hasCredit ? const Color(0xFF22C55E) : const Color(0xFFFFC73A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 18,
                    color: hasCredit ? Colors.white : const Color(0xFF0B1F5B),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasCredit ? 'Use' : '${lp.currentCount}/5',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 15, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
