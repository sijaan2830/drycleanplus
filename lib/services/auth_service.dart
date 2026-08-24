import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'push_notification_service.dart';

/// AuthService handles Firebase authentication with Google and Apple Sign-In
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
        ? '778802274663-19c8erp11o4kcvr2srscq91k24ngrdse.apps.googleusercontent.com'
        : null,
    serverClientId: '778802274663-adevakr0dpk4j5i3bsfn0bf260q9j7h6.apps.googleusercontent.com',
  );
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if Firebase is initialized
  bool _isFirebaseInitialized() {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      print('Firebase not initialized: $e');
      return false;
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user display name
  String? get displayName => _auth.currentUser?.displayName;

  // Get user email
  String? get email => _auth.currentUser?.email;

  // Get user photo URL
  String? get photoURL => _auth.currentUser?.photoURL;

  // Get user phone number
  String? get phoneNumber => _auth.currentUser?.phoneNumber;

  // Get user ID
  String? get uid => _auth.currentUser?.uid;

  /// Sign in with Apple (Mandatory for App Store Guideline 4.8)
  Future<UserCredential?> signInWithApple() async {
    if (!_isFirebaseInitialized()) {
      throw Exception('Firebase is not initialized. Please restart the app.');
    }

    try {
      print('Triggering Apple Sign-In...');
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final UserCredential userCredential =
          await _auth.signInWithProvider(appleProvider);

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
        await PushNotificationService.updateUserToken(userCredential.user!.uid);
        await _saveUserData({
          'uid': userCredential.user!.uid,
          'displayName': userCredential.user!.displayName ?? 'Apple User',
          'email': userCredential.user!.email ?? '',
          'photoURL': userCredential.user!.photoURL ?? '',
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'user-cancelled' ||
          e.code == 'account-exists-with-different-credential') {
        print('Apple sign-in cancelled or dismissed: ${e.message}');
        return null;
      }
      throw Exception('Apple auth error: ${e.message ?? e.code}');
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('canceled') || str.contains('cancelled')) {
        print('Apple sign-in cancelled');
        return null;
      }
      throw Exception('Apple sign-in error: $e');
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    // Check if Firebase is initialized
    if (!_isFirebaseInitialized()) {
      throw Exception('Firebase is not initialized. Please restart the app.');
    }

    try {
      print('Triggering Google Sign-In...');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google sign-in was cancelled by user');
        return null;
      }

      print('Google Sign-In result: ${googleUser.displayName}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Create user document in Firestore if new user
      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
        await PushNotificationService.updateUserToken(userCredential.user!.uid);
        await _saveUserData({
          'uid': userCredential.user!.uid,
          'displayName': userCredential.user!.displayName ?? 'Google User',
          'email': userCredential.user!.email ?? '',
          'photoURL': userCredential.user!.photoURL ?? '',
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'user-cancelled') {
        print('Google sign-in was cancelled');
        return null;
      }
      throw Exception('Firebase auth error: ${e.message ?? e.code}');
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('canceled') ||
          str.contains('cancelled') ||
          str.contains('sign_in_canceled')) {
        print('Google sign-in was cancelled');
        return null;
      }
      throw Exception('Google sign-in error: $e');
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      
      final rawName = user.displayName?.isNotEmpty == true
          ? user.displayName!
          : ((user.email != null && user.email!.contains('@'))
              ? user.email!.split('@').first
              : 'User');

      if (!docSnapshot.exists) {
        // Parse display name into first and last name
        final nameParts = rawName.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : rawName;
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        
        // Create new user document with all fields
        await userDoc.set({
          'uid': user.uid,
          'displayName': rawName,
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isGuest': false,
          'orderCount': 0,
          'prepaidBalance': 0,
        });
        print('User document created in Firestore');
      } else {
        // Update existing user document
        final updateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          updateData['displayName'] = user.displayName;
        }
        if (user.email != null && user.email!.isNotEmpty) {
          updateData['email'] = user.email;
        }
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          updateData['photoURL'] = user.photoURL;
        }
        await userDoc.update(updateData);
        print('User document updated in Firestore');
      }
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser == null) return null;
      
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    await _clearUserData();
  }

  /// Save user data to SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', user['uid'] ?? '');
    await prefs.setString('user_displayName', user['displayName'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setString('user_photoURL', user['photoURL'] ?? '');
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('is_guest', false);
  }

  /// Clear user data from SharedPreferences
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.remove('user_displayName');
    await prefs.remove('user_email');
    await prefs.remove('user_photoURL');
    await prefs.setBool('is_logged_in', false);
    await prefs.setBool('is_guest', false);
  }

  /// Get saved user data from SharedPreferences
  Future<Map<String, String?>> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString('user_uid'),
      'displayName': prefs.getString('user_displayName'),
      'email': prefs.getString('user_email'),
      'photoURL': prefs.getString('user_photoURL'),
    };
  }

  /// Check if user has saved session
  Future<bool> hasSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
}
