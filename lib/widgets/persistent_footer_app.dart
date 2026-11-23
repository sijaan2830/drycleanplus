import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home_screen.dart';
import '../screens/prices_screen.dart';
import '../screens/guest_price_screen.dart';
import '../screens/prepaid_packs_screen.dart';
import '../screens/more_screen.dart';
import '../screens/service_overview_screen.dart';
import '../utils/route_helpers.dart';
import '../utils/guest_helper.dart';

/// Global ValueNotifier for instantaneous tab switching (0: Home, 1: Prices, 2: Prepaid, 3: More)
final ValueNotifier<int> mainTabNotifier = ValueNotifier<int>(0);

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
  /// Standard bar height without safe area inset (from Home.html: 64px)
  static const double _baseBarHeight = 64.0;

  double _footerHeight(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return _baseBarHeight + safeBottom;
  }

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
    if (mainTabNotifier.value != index) {
      mainTabNotifier.value = index;
    }
  }

  /// Reset navigation state to Home tab (index 0).
  /// Call this after logout or account deletion.
  void resetToHomeTab() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
    if (mainTabNotifier.value != 0) {
      mainTabNotifier.value = 0;
    }
  }

  void _handleRouteChanged() {
    final routeName = RouteNotifier().value;
    if (routeName == null || !mounted) return;

    int? nextIndex;
    if (routeName == '/home') {
      nextIndex = 0;
    } else if (routeName == '/prices' || routeName == '/guest_prices') {
      nextIndex = 1;
    } else if (routeName == '/prepaid') {
      nextIndex = 2;
    } else if (routeName == '/more') {
      nextIndex = 3;
    }

    if (nextIndex != null) {
      final int target = nextIndex;
      if (_currentIndex != target) {
        setState(() => _currentIndex = target);
      }
      if (mainTabNotifier.value != target) {
        mainTabNotifier.value = target;
      }
    }
  }

  void _navigateToTab(int index) {
    final nav = navigatorKey.currentState;

    // If already on this tab, but subroutes are pushed on top, pop back to tab root!
    if (_currentIndex == index && mainTabNotifier.value == index) {
      if (nav != null && nav.mounted && nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
        final routes = [
          '/home',
          GuestHelper.getPriceRoute(),
          '/prepaid',
          '/more',
        ];
        RouteNotifier().forceRoute(routes[index]);
      }
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    mainTabNotifier.value = index;

    final routes = [
      '/home',
      GuestHelper.getPriceRoute(),
      '/prepaid',
      '/more',
    ];

    final targetRoute = routes[index];
    RouteNotifier().forceRoute(targetRoute);

    if (nav == null || !nav.mounted) return;

    // If any pushed subroute is currently over the main tab shell, pop back to the shell
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
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
    if (RouteNotifier().isLoggingOut) return false;

    const hiddenRoutes = {
      '/onboarding',
      '/loader',
      '/service_overview',
      '/service_items',
      '/select_services',
      '/address_selection',
      '/add_address',
      '/time_slots',
      '/contact_info',
      '/booking_overview',
      '/payment_options',
      '/payment',
      '/track_order',
      '/track_driver',
      '/booking_confirmation',
      '/guest_service_overview',
      '/notifications',
      '/notification',
    };

    if (routeName != null && hiddenRoutes.contains(routeName)) {
      return false;
    }

    return true; // Default to showing footer on tabs and sub-screens
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: RouteNotifier(),
      builder: (context, routeName, _) {
        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        final isLoggingOut = RouteNotifier().isLoggingOut;
        final showFooter = _shouldShowFooter(routeName) && !keyboardOpen && !isLoggingOut;
        final footerH = _footerHeight(context);
        final safeBottom = MediaQuery.of(context).padding.bottom;

        return ColoredBox(
          color: const Color(0xFF0C2B7A), // App's background color: prevents any black window background from bleeding through
          child: Stack(
            children: [
              // ── Main content ──────────────────────────────────────────────
              // Allow child to extend slightly behind the footer (26px) so that the
              // footer's top-left and top-right 22px curved corners are completely backed
              // by the page's vibrant background instead of unpainted transparent/black gaps!
              Positioned.fill(
                bottom: showFooter ? (footerH - 26).clamp(0.0, double.infinity) : 0,
                child: widget.child,
              ),

              // ── Footer bar matching Home.html exactly ─────────────────────
              if (showFooter)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _HomeHtmlFooter(
                    baseHeight: _baseBarHeight,
                    safeBottom: safeBottom,
                    currentIndex: _currentIndex,
                    onTabSelected: _navigateToTab,
                    onBookNowTap: _navigateToServiceSelection,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Footer Bar Matching Home.html Specification ──────────────────────────────
class _HomeHtmlFooter extends StatelessWidget {
  final double baseHeight;
  final double safeBottom;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onBookNowTap;

  const _HomeHtmlFooter({
    required this.baseHeight,
    required this.safeBottom,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onBookNowTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide > 600;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ── Full-Width Bar Background Container (No black gaps on left/right!) ──
            Container(
              width: double.infinity,
              height: baseHeight + safeBottom,
              decoration: BoxDecoration(
                color: const Color(0xF20A2468), // rgba(10,36,104,.95)
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.0,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5902104C), // rgba(2,16,76,.35)
                    blurRadius: 28,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: safeBottom),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SizedBox(
                      height: baseHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab 0: Home
                          Expanded(
                            child: _HomeHtmlNavItem(
                              icon: Icons.home_rounded,
                              label: 'Home',
                              index: 0,
                              isSelected: currentIndex == 0,
                              onTap: onTabSelected,
                            ),
                          ),
                          // Tab 1: Prices
                          Expanded(
                            child: _HomeHtmlNavItem(
                              icon: Icons.sell_rounded,
                              label: 'Prices',
                              index: 1,
                              isSelected: currentIndex == 1,
                              onTap: onTabSelected,
                            ),
                          ),
                          // Center Slot: Book now (takes ~80px width)
                          SizedBox(
                            width: isTablet ? 90 : 80,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onBookNowTap,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: Text(
                                      'Book now',
                                      style: TextStyle(
                                        fontSize: isTablet ? 12.0 : 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.1,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Tab 2: Prepaid
                          Expanded(
                            child: _HomeHtmlNavItem(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Prepaid',
                              index: 2,
                              isSelected: currentIndex == 2,
                              onTap: onTabSelected,
                            ),
                          ),
                          // Tab 3: More
                          Expanded(
                            child: _HomeHtmlNavItem(
                              icon: Icons.grid_view_rounded,
                              label: 'More',
                              index: 3,
                              isSelected: currentIndex == 3,
                              onTap: onTabSelected,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Floating Book Now Pill Button (Centered) ──
            Positioned(
              bottom: safeBottom + baseHeight - 34, // Exactly 22px sticking above top of bar
              child: GestureDetector(
                onTap: onBookNowTap,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFE08A), Color(0xFFF5B82E)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0A2468),
                      width: 5.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF02104C).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Color(0xFF0B1F5B),
                      size: 28,
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

// ── Single Nav Item matching Home.html .t ─────────────────────────────────────
class _HomeHtmlNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final ValueChanged<int> onTap;

  const _HomeHtmlNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.62);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Top Active Indicator Bar (.t::before in Home.html) ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 28 : 0,
              height: 3,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD25E),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),

            // ── Centered Icon & Label ──
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.1,
                      decoration: TextDecoration.none,
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
}

// ── MainTabScreen ─────────────────────────────────────────────────────────────

/// High-performance IndexedStack tab shell for instant 0ms tab transitions.
class MainTabScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainTabScreen({super.key, int? tabIndex, int? initialTabIndex})
      : initialTabIndex = initialTabIndex ?? tabIndex ?? 0;

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != mainTabNotifier.value) {
      mainTabNotifier.value = widget.initialTabIndex;
    }
  }

  @override
  void didUpdateWidget(covariant MainTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex != mainTabNotifier.value) {
      mainTabNotifier.value = widget.initialTabIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (mainTabNotifier.value != 0) {
          persistentFooterKey.currentState?.setTab(0);
          mainTabNotifier.value = 0;
          RouteNotifier().forceRoute('/home');
        } else {
          SystemNavigator.pop();
        }
      },
      child: ValueListenableBuilder<int>(
        valueListenable: mainTabNotifier,
        builder: (context, activeIndex, _) {
          return IndexedStack(
            index: activeIndex.clamp(0, 3),
            children: [
              const HomeScreen(showBottomNav: false),
              GuestHelper.isGuest()
                  ? const GuestPriceScreen()
                  : const PricesScreen(showBottomNav: false),
              const PrepaidPacksScreen(showBottomNav: false),
              const MoreScreen(showBottomNav: false),
            ],
          );
        },
      ),
    );
  }
}
