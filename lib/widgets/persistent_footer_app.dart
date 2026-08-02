import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../screens/home_screen.dart';
import '../screens/prices_screen.dart';
import '../screens/guest_price_screen.dart';
import '../screens/prepaid_packs_screen.dart';
import '../screens/more_screen.dart';
import '../screens/service_overview_screen.dart';
import '../utils/route_helpers.dart';
import '../utils/guest_helper.dart';

/// Global reference to PersistentFooterApp state for resetting navigation.
/// Prefer using [persistentFooterKey] (the typed GlobalKey) instead.
PersistentFooterAppState? persistentFooterAppState;

/// A widget that provides a persistent footer navigation that never animates.
/// The footer is rendered outside the Navigator's transition scope.
class PersistentFooterApp extends StatefulWidget {
  final Widget child;

  const PersistentFooterApp({super.key, required this.child});

  @override
  State<PersistentFooterApp> createState() => PersistentFooterAppState();
}

class PersistentFooterAppState extends State<PersistentFooterApp> {
  int _currentIndex = 0;

  // ── Responsive measurements ──────────────────────────────────────────────
  /// Minimum nav bar height. Grows on tall phones.
  static const double _minNavBarHeight = 66.0;

  /// Extra breathing room above system bottom inset.
  static const double _extraPadding = 8.0;

  /// FAB diameter.
  static const double _fabSize = 58.0;

  double _navBarHeight(BuildContext context) {
    // Scale slightly on larger screens (tablets) but cap at 80.
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide > 600 ? 76.0 : _minNavBarHeight).clamp(66.0, 80.0);
  }

  double _footerHeight(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return _navBarHeight(context) + safeBottom + _extraPadding;
  }

  double _fabBottomOffset(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // Position FAB so its centre aligns with the nav bar's icon row.
    return safeBottom + (_navBarHeight(context) / 2) - (_fabSize / 2);
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    persistentFooterAppState = this;
    RouteNotifier().addListener(_handleRouteChanged);
  }

  @override
  void dispose() {
    RouteNotifier().removeListener(_handleRouteChanged);
    persistentFooterAppState = null;
    super.dispose();
  }

  void setTab(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  /// Reset navigation state to Home tab (index 0).
  /// Call this after logout or account deletion.
  void resetToHomeTab() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
  }

  void _handleRouteChanged() {
    // We only update if the tab should actually change to prevent rebuild loops.
    final routeName = RouteNotifier().value;
    if (routeName == null || !mounted) return;

    int? nextIndex;
    if (routeName == '/home') nextIndex = 0;
    else if (routeName == '/prices' || routeName == '/guest_prices') nextIndex = 1;
    else if (routeName == '/prepaid') nextIndex = 2;
    else if (routeName == '/more') nextIndex = 3;

    if (nextIndex != null && _currentIndex != nextIndex) {
      if (mounted) {
        setState(() => _currentIndex = nextIndex!);
      }
    }
  }

  void _navigateToTab(int index) {
    if (_currentIndex == index) return;

    final routes = [
      '/home',
      GuestHelper.getPriceRoute(),
      '/prepaid',
      '/more',
    ];

    // Note: We don't call setState here immediately because _handleRouteChanged 
    // will catch it once the navigation occurs. This prevents circularity.
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null || !nav.mounted) return;

      final currentRoute = RouteNotifier().value;

      if (index == 0) {
        nav.pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (currentRoute != routes[index]) {
        nav.pushReplacementNamed(routes[index]);
      }
    });
  }

  void _navigateToServiceSelection() {
    final nav = navigatorKey.currentState;
    if (nav == null || !nav.mounted) return;

    nav.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/service_overview'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ServiceOverviewScreen(serviceType: 'Dry Clean'),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutCubic;
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: curve)),
            ),
            child: FadeTransition(
              opacity: animation.drive(CurveTween(curve: curve)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  bool _shouldShowFooter(String? routeName) {
    if (routeName == null) return false;

    const hiddenRoutes = {
      '/onboarding',
      '/service_overview',
      '/time_slots',
      '/booking_overview',
      '/payment',
      '/booking_confirmation',
      '/guest_prices',
      '/guest_service_overview',
    };

    return !hiddenRoutes.contains(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: RouteNotifier(),
      builder: (context, routeName, _) {
        final showFooter = _shouldShowFooter(routeName);
        final footerH = _footerHeight(context);
        final fabBottom = _fabBottomOffset(context);

        return Stack(
          children: [
            // ── Main content ──────────────────────────────────────────────
            Positioned.fill(
              bottom: showFooter ? footerH : 0,
              child: widget.child,
            ),

            // ── Footer bar ────────────────────────────────────────────────
            if (showFooter)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _FixedFooter(
                  height: footerH,
                  safeBottom: MediaQuery.of(context).padding.bottom,
                  currentIndex: _currentIndex,
                  onTabSelected: _navigateToTab,
                ),
              ),

            // ── FAB (Book now) ────────────────────────────────────────────
            if (showFooter)
              Positioned(
                bottom: fabBottom,
                left: 0,
                right: 0,
                child: Center(
                  child: _BookNowFab(
                    size: _fabSize,
                    onTap: _navigateToServiceSelection,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _FixedFooter extends StatelessWidget {
  final double height;
  final double safeBottom;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _FixedFooter({
    required this.height,
    required this.safeBottom,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const _items = [
    (Icons.home_filled, 'Home'),
    (Icons.local_offer_rounded, 'Prices'),
    (Icons.account_balance_wallet_rounded, 'Prepaid'),
    (Icons.more_horiz_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlueDark,
          border: Border(top: BorderSide(color: AppColors.gold, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 15,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: safeBottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left two items
                  _NavItem(
                    icon: _items[0].$1,
                    label: _items[0].$2,
                    index: 0,
                    isSelected: currentIndex == 0,
                    onTap: onTabSelected,
                  ),
                  _NavItem(
                    icon: _items[1].$1,
                    label: _items[1].$2,
                    index: 1,
                    isSelected: currentIndex == 1,
                    onTap: onTabSelected,
                  ),
                  // Centre gap for the FAB
                  const SizedBox(width: 64),
                  // Right two items
                  _NavItem(
                    icon: _items[2].$1,
                    label: _items[2].$2,
                    index: 2,
                    isSelected: currentIndex == 2,
                    onTap: onTabSelected,
                  ),
                  _NavItem(
                    icon: _items[3].$1,
                    label: _items[3].$2,
                    index: 3,
                    isSelected: currentIndex == 3,
                    onTap: onTabSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.gold : AppColors.white.withOpacity(0.5);

    // Responsive icon / font size
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final iconSize = shortestSide > 600 ? 30.0 : 26.0;
    final fontSize = shortestSide > 600 ? 13.0 : 12.0;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookNowFab extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _BookNowFab({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fontSize = MediaQuery.of(context).size.shortestSide > 600 ? 12.0 : 11.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Book now',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.white.withOpacity(0.5),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

// ── MainTabScreen ─────────────────────────────────────────────────────────────

/// A wrapper widget for main tab screens that works with the persistent footer.
class MainTabScreen extends StatelessWidget {
  final int tabIndex;

  const MainTabScreen({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(showBottomNav: false),
      GuestHelper.isGuest()
          ? const GuestPriceScreen()
          : PricesScreen(showBottomNav: false),
      PrepaidPacksScreen(showBottomNav: false),
      MoreScreen(showBottomNav: false),
    ];

    return pages[tabIndex];
  }
}