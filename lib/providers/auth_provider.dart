import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Stub AuthProvider for development without Firebase
/// Firebase authentication is temporarily disabled
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  dynamic _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  dynamic get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String? get displayName => null;
  String? get email => null;
  String? get photoURL => null;
  String? get uid => null;

  AuthProvider() {
    _init();
  }

  /// Initialize auth state listener (stub)
  void _init() {
    // Firebase temporarily disabled - no auth state listener
  }

  /// Sign in with Google (stub - returns false)
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Firebase temporarily disabled
      await Future.delayed(const Duration(seconds: 1));
      
      _isLoading = false;
      _error = 'Google Sign-In is temporarily disabled for development';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _user = null;
      _error = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
