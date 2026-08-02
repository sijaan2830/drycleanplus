import 'package:shared_preferences/shared_preferences.dart';

class GuestHelper {
  static bool _isGuest = false;
  static bool _isInitialized = false;

  /// Initialize guest status from SharedPreferences
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('is_guest') ?? false;
      _isInitialized = true;
    } catch (e) {
      _isGuest = false;
      _isInitialized = true;
    }
  }

  /// Check if current user is a guest
  static bool isGuest() {
    if (!_isInitialized) {
      // Return false by default if not initialized yet
      return false;
    }
    return _isGuest;
  }

  /// Check if guest helper is initialized
  static bool isInitialized() {
    return _isInitialized;
  }

  /// Set guest status
  static Future<void> setGuestStatus(bool isGuest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', isGuest);
      _isGuest = isGuest;
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get guest price screen route based on user status
  static String getPriceRoute() {
    return isGuest() ? '/guest_prices' : '/prices';
  }

  /// Get guest service overview route based on user status
  static String getServiceOverviewRoute() {
    return isGuest() ? '/guest_service_overview' : '/service_overview';
  }
}
