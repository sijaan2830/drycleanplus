import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  void updateRoute(String? newValue) {
    if (value == newValue) return;

    // If we are in the middle of a frame (build/layout/paint), defer to
    // the post-frame callback. Otherwise update synchronously so the
    // footer reacts immediately on the very next paint.
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (value != newValue) {
          super.value = newValue;
        }
      });
    } else {
      super.value = newValue;
    }
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
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  void _updateRoute(Route route) {
    currentRoute = route.settings.name;
    _routeNotifier.updateRoute(route.settings.name);
  }
}