import 'package:flutter/material.dart';
import '../widgets/persistent_footer_app.dart';

/// Global navigator key for accessing the Navigator from outside the Navigator's context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global key for the persistent footer app state — typed correctly
final GlobalKey<PersistentFooterAppState> persistentFooterKey =
    GlobalKey<PersistentFooterAppState>();

/// Helper function to create a route with no transition animation
Route<dynamic> noTransitionRoute(Widget page, {String? routeName}) {
  return PageRouteBuilder(
    settings: RouteSettings(name: routeName ?? '/home'),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

/// Routes where the footer should be hidden
const Set<String> hiddenFooterRoutes = {
  '/onboarding',
  '/time_slots',
  '/booking_overview',
  '/payment',
  '/booking_confirmation',
};

/// A value notifier that tracks the current route for footer visibility.
/// Uses SchedulerBinding to safely update during or after build phase
/// — avoids the race condition caused by bare Future.delayed(Duration.zero).
class RouteNotifier extends ValueNotifier<String?> {
  static final RouteNotifier _instance = RouteNotifier._internal();
  factory RouteNotifier() => _instance;
  RouteNotifier._internal() : super(null);

  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  /// Call immediately when logout begins to prevent footer from flashing
  /// or staying visible during splash loader transitions.
  void startLogout() {
    _isLoggingOut = true;
    value = '/onboarding';
    notifyListeners();
  }

  /// Reset logout lock (called once user lands on Onboarding or logs in)
  void endLogout() {
    _isLoggingOut = false;
  }

  void forceRoute(String? newValue) {
    value = newValue;
    notifyListeners();
  }

  void updateRoute(String? newValue) {
    if (_isLoggingOut) {
      if (newValue == '/home') {
        _isLoggingOut = false;
      } else {
        return;
      }
    }
    if (value == newValue) return;

    // Always defer to post-frame callback to avoid setState/markNeedsBuild during widget tree build/mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (value != newValue && !_isLoggingOut) {
        super.value = newValue;
      }
    });
  }
}

/// Navigator observer to track the current route for footer visibility
class FooterNavigatorObserver extends NavigatorObserver {
  static String? currentRoute;
  final RouteNotifier _routeNotifier = RouteNotifier();

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    } else {
      _updateRoute(route);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateRoute(newRoute);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    // Only update to previousRoute if the removed route was the current active route
    // and we are not in the middle of a logout or pushAndRemoveUntil!
    if (currentRoute == route.settings.name && previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  void _updateRoute(Route route) {
    currentRoute = route.settings.name;
    _routeNotifier.updateRoute(route.settings.name);
  }
}
