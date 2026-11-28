import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/loyalty_provider.dart';
import '../screens/loyalty_screen.dart';
import '../widgets/app_ui.dart';

/// Compact live Digital Loyalty Card summary rendered on HomeScreen.
class LoyaltyMiniCard extends StatelessWidget {
  const LoyaltyMiniCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoyaltyProvider>(
      builder: (context, lp, _) {
        if (!lp.isSignedIn) return const SizedBox.shrink();

        final bool hasCredit = lp.availableCredit > 0;
        return GestureDetector(
          onTap: () => Navigator.of(context).push(smoothRoute(const LoyaltyScreen(), name: '/loyalty')),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CC3F4), Color(0xFF2AA7E1)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF061A5E).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF0E3E2C), borderRadius: BorderRadius.circular(8)),
                      child: Text('LOYALTY CARD', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${lp.currentCount} of 5 orders',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0A2433)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasCredit ? const Color(0xFF7FD13B) : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        hasCredit ? '£${lp.availableCredit.toStringAsFixed(2)} FREE' : '£${lp.nextRewardBuilding.toStringAsFixed(2)} building',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF0E3E2C)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    for (int i = 0; i < 5; i++) ...[
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: i < lp.currentCount ? Colors.white : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF0E3E2C).withValues(alpha: 0.35)),
                          ),
                          alignment: Alignment.center,
                          child: i < lp.currentCount
                              ? Text(
                                  '£${lp.currentRoundOrders[i].paidAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF0E3E2C)),
                                )
                              : Icon(Icons.local_laundry_service_outlined, size: 15, color: const Color(0xFF0A2433).withValues(alpha: 0.6)),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Container(
                      width: 34,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7FD13B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0E3E2C)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFF0E3E2C)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Complete 5 paid orders, get average FREE',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0A2433)),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF0A2433)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
