import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../screens/home_screen.dart';
import '../screens/prices_screen.dart';
import '../screens/guest_price_screen.dart';
import '../screens/prepaid_packs_screen.dart';
import '../screens/more_screen.dart';
import '../screens/service_overview_screen.dart';
import '../widgets/persistent_footer_app.dart';
import '../utils/guest_helper.dart';

/// Centralized navigation helper for footer menu items
class NavigationHelper {
  /// Handle footer navigation with standard MaterialPageRoute
  static void handleFooterNavigation(BuildContext context, int index) {
    // Reset footer tab state when navigating
    final footerAppState = context.findAncestorStateOfType<PersistentFooterAppState>();
    footerAppState?.setTab(index);
    
    switch (index) {
      case 0: // Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1: // Prices
        if (GuestHelper.isGuest()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GuestPriceScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PricesScreen()),
          );
        }
        break;
      case 2: // Prepaid Packs
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PrepaidPacksScreen()),
        );
        break;
      case 3: // More
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MoreScreen()),
        );
        break;
    }
  }
}

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final totalHeight = kBottomNavigationBarHeight + safeBottom + 20;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark,
        border: Border(
          top: BorderSide(color: AppColors.gold.withOpacity(0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Main Navigation Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(Icons.home_filled, "Home", 0),
                _buildNavItem(Icons.local_offer_rounded, "Prices", 1),
                const SizedBox(width: 64), // Spacer for the FAB
                _buildNavItem(Icons.account_balance_wallet_rounded, "Prepaid", 2),
                _buildNavItem(Icons.more_horiz_rounded, "More", 3),
              ],
            ),

            // The Floating "Book now" Button & Label — raised higher
            Positioned(
              top: -14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: '/service_overview'),
                          builder: (context) => ServiceOverviewScreen(serviceType: 'Dry Clean'),
                        ),
                      );
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 34,
                            weight: 700,
                          ),
                        ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Material(
                    type: MaterialType.transparency,
                    child: Text(
                      "Book now",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.gold
                    : AppColors.white.withOpacity(0.5),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
