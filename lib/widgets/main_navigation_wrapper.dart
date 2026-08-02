import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class MainNavigationWrapper extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const MainNavigationWrapper({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Home
        if (ModalRoute.of(context)?.settings.name != '/home') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (Route<dynamic> route) => false,
          );
        }
        break;
      case 1: // Services
        if (ModalRoute.of(context)?.settings.name != '/service_selection') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/service_selection',
            (Route<dynamic> route) => false,
          );
        }
        break;
      case 2: // Orders
        if (ModalRoute.of(context)?.settings.name != '/orders') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/orders',
            (Route<dynamic> route) => false,
          );
        }
        break;
      case 3: // Profile
        if (ModalRoute.of(context)?.settings.name != '/account') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/account',
            (Route<dynamic> route) => false,
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show bottom navigation on certain screens
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final hideBottomNav = [
      '/splash',
      '/onboarding',
      '/service_selection',
      '/service_items',
      '/address_selection',
      '/add_address',
      '/time_slots',
      '/booking_overview',
      '/contact_info',
      '/payment',
      '/booking_confirmation',
    ].contains(currentRoute);

    if (hideBottomNav) {
      return widget.child;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
