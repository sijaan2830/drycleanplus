import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/push_notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/booking/service_items_screen.dart';
import 'screens/booking/address_selection_screen.dart';
import 'screens/booking/add_address_screen.dart';
import 'screens/booking/time_slots_screen.dart';
import 'screens/booking/booking_overview_screen.dart';
import 'screens/booking/contact_info_screen.dart';
import 'screens/booking/payment_screen.dart';
import 'screens/booking/booking_confirmation_screen.dart';
import 'screens/account_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/guest_price_screen.dart';
import 'screens/guest_service_overview_screen.dart';
import 'screens/membership_screen.dart';
import 'providers/booking_provider.dart';
import 'providers/user_provider.dart';
import 'providers/prepaid_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/time_slot_provider.dart';
import 'providers/service_provider.dart';
import 'widgets/persistent_footer_app.dart';
import 'utils/route_helpers.dart';
import 'utils/guest_helper.dart';
import 'screens/offers_screen.dart';

/// Global navigator observer for tracking route changes.
final FooterNavigatorObserver footerNavigatorObserver =
    FooterNavigatorObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(
        PushNotificationService.firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase core initialization error: $e');
  }

  try {
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('PushNotificationService initialization error: $e');
  }

  try {
    final firestoreService = FirestoreService();
    await firestoreService.initializeUserData();
    await firestoreService.getAllServices();
  } catch (e) {
    debugPrint('Firestore services preload notice: $e');
  }

  try {
    await GuestHelper.initialize();
  } catch (e) {
    debugPrint('GuestHelper initialization error: $e');
  }

  runApp(const DrycleanPlusApp());
}

class DrycleanPlusApp extends StatelessWidget {
  const DrycleanPlusApp({super.key});

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
      ],
      child: MaterialApp(
        title: 'DrycleanPlus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: navigatorKey,
        navigatorObservers: [footerNavigatorObserver],
        initialRoute: '/onboarding',
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
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/home': (_) => const MainTabScreen(tabIndex: 0),
          '/prices': (_) => const MainTabScreen(tabIndex: 1),
          '/prepaid': (_) => const MainTabScreen(tabIndex: 2),
          '/more': (_) => const MainTabScreen(tabIndex: 3),
          '/service_items': (_) => const ServiceItemsScreen(),
          '/address_selection': (_) =>
              const AddressSelectionScreen(isEditMode: false),
          '/add_address': (_) => const AddAddressScreen(),
          '/time_slots': (_) => const TimeSlotsScreen(isEditMode: false),
          '/booking_overview': (_) => const BookingOverviewScreen(),
          '/contact_info': (_) =>
              const ContactInfoScreen(isEditMode: false),
          '/booking_confirmation': (_) => const BookingConfirmationScreen(),
          '/account': (_) => const AccountScreen(),
          '/orders': (_) => const OrdersScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/faq': (_) => const FAQScreen(),
          '/terms': (_) => const TermsConditionsScreen(),
          '/privacy': (_) => const PrivacyPolicyScreen(),
          '/guest_prices': (_) => const GuestPriceScreen(),
          '/guest_service_overview': (_) => const GuestServiceOverviewScreen(
              serviceType: 'Dry Clean'),
          '/membership': (_) => const MembershipScreen(),
          '/service_selection': (_) => const MainTabScreen(tabIndex: 1),
          '/offers': (_) => const OffersScreen(),
        },
      ),
    );
  }
}