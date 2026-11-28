import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/theme.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/booking/address_selection_screen.dart';
import 'screens/booking/add_address_screen.dart';
import 'screens/booking/time_slots_screen.dart';
import 'screens/booking/review_order_screen.dart';
import 'screens/booking/select_services_screen.dart';
import 'screens/booking/contact_info_screen.dart';
import 'screens/booking/booking_confirmation_screen.dart';
import 'screens/account_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/guest_service_overview_screen.dart';
import 'screens/membership_screen.dart';
import 'providers/booking_provider.dart';
import 'providers/user_provider.dart';
import 'providers/prepaid_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/time_slot_provider.dart';
import 'providers/service_provider.dart';
import 'providers/loyalty_provider.dart';
import 'screens/loyalty_screen.dart';
import 'widgets/persistent_footer_app.dart';
import 'utils/route_helpers.dart';
import 'utils/guest_helper.dart';
import 'screens/offers_screen.dart';

/// Global navigator observer for tracking route changes.
final FooterNavigatorObserver footerNavigatorObserver = FooterNavigatorObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isLoggedIn = false;
  bool isGuest = false;

  // Ultra-fast parallel initialization to drop native splash in ~0.3s
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) {
      FirebaseMessaging.onBackgroundMessage(
          PushNotificationService.firebaseMessagingBackgroundHandler);
    }).catchError((e) {
      debugPrint('Firebase core initialization error: $e');
      return null;
    }),
    SharedPreferences.getInstance().then((prefs) {
      isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      isGuest = prefs.getBool('is_guest') ?? false;
    }).catchError((e) {
      debugPrint('Prefs initialization error: $e');
    }),
    GuestHelper.initialize().catchError((e) {
      debugPrint('GuestHelper initialization error: $e');
    }),
  ]);

  final String startRoute = (isLoggedIn && !isGuest) ? '/home' : '/onboarding';

  // Immediately launch Flutter UI
  runApp(DrycleanPlusApp(initialRoute: startRoute));

  // Secondary push notification init in background
  PushNotificationService.initialize().catchError((e) {
    debugPrint('PushNotificationService background init error: $e');
  });
}

class DrycleanPlusApp extends StatelessWidget {
  final String initialRoute;
  const DrycleanPlusApp({super.key, this.initialRoute = '/onboarding'});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
            create: (_) => BookingProvider()..initializeListeners()),
        ChangeNotifierProvider(
            create: (_) => UserProvider()..loadUserData()),
        ChangeNotifierProvider(
            create: (_) => PrepaidProvider()..loadPacks()),
        ChangeNotifierProvider(
            create: (_) =>
                TimeSlotProvider()..initializeTimeSlotsListener()),
        ChangeNotifierProvider(
            create: (_) =>
                ServiceProvider()..initializeServicesListener()),
        ChangeNotifierProvider(
            create: (_) => LoyaltyProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'DrycleanPlus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: navigatorKey,
        navigatorObservers: [footerNavigatorObserver],
        initialRoute: initialRoute,
        builder: (context, child) {
          // PersistentFooterApp wraps all routes.
          // persistentFooterKey is now correctly typed as
          // GlobalKey<PersistentFooterAppState>, so .currentState
          // exposes PersistentFooterAppState methods (setTab, resetToHomeTab).
          return PersistentFooterApp(
            key: persistentFooterKey,
            child: child ?? const OnboardingScreen(),
          );
        },
        onGenerateRoute: (settings) {
          final name = settings.name;
          if (name == '/home') {
            return noTransitionRoute(const MainTabScreen(tabIndex: 0), routeName: '/home');
          } else if (name == '/prices' || name == '/guest_prices') {
            return noTransitionRoute(const MainTabScreen(tabIndex: 1), routeName: name);
          } else if (name == '/prepaid') {
            return noTransitionRoute(const MainTabScreen(tabIndex: 2), routeName: '/prepaid');
          } else if (name == '/more') {
            return noTransitionRoute(const MainTabScreen(tabIndex: 3), routeName: '/more');
          }
          return null;
        },
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/home': (_) => const MainTabScreen(tabIndex: 0),
          '/prices': (_) => const MainTabScreen(tabIndex: 1),
          '/prepaid': (_) => const MainTabScreen(tabIndex: 2),
          '/more': (_) => const MainTabScreen(tabIndex: 3),
          '/service_items': (_) => const SelectServicesScreen(), // item counting retired
          '/address_selection': (_) =>
              const AddressSelectionScreen(isEditMode: false),
          '/add_address': (_) => const AddAddressScreen(),
          '/time_slots': (_) => const TimeSlotsScreen(isEditMode: false),
          '/booking_overview': (_) => const ReviewOrderScreen(), // Laundryheap-style one-page review
          '/select_services': (_) => const SelectServicesScreen(),
          '/contact_info': (_) =>
              const ContactInfoScreen(isEditMode: false),
          '/booking_confirmation': (_) => const BookingConfirmationScreen(),
          '/account': (_) => const AccountScreen(),
          '/orders': (_) => const OrdersScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/faq': (_) => const FAQScreen(),
          '/terms': (_) => const TermsConditionsScreen(),
          '/privacy': (_) => const PrivacyPolicyScreen(),
          '/guest_prices': (_) => const MainTabScreen(tabIndex: 1),
          '/guest_service_overview': (_) => const GuestServiceOverviewScreen(
              serviceType: 'Dry Clean'),
          '/membership': (_) => const MembershipScreen(),
          '/service_selection': (_) => const MainTabScreen(tabIndex: 1),
          '/offers': (_) => const OffersScreen(),
          '/notifications': (_) => const NotificationScreen(),
          '/loyalty': (_) => const LoyaltyScreen(),
        },
      ),
    );
  }
}
