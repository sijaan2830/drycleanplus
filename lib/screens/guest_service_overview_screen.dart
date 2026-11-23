import 'package:flutter/material.dart';
import 'service_overview_screen.dart';

class GuestServiceOverviewScreen extends StatelessWidget {
  final String serviceType;

  const GuestServiceOverviewScreen({
    super.key,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return ServiceOverviewScreen(
      serviceType: serviceType,
      isGuest: true,
    );
  }
}
