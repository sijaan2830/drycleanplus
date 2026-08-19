import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import '../utils/route_helpers.dart'; // To access global navigatorKey
import '../models/booking_models.dart' as models;
import '../screens/track_order_screen.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Request permissions for iOS and Android 13+
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize Local Notifications for Foreground display
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          if (details.payload != null) {
            try {
              _handleNotificationClick({});
            } catch (e) {
              print('Error parsing notification payload: $e');
            }
          }
        },
      );

      // Setup FCM token and topics safely in background without blocking launch
      _setupFCMTokenAndTopics();

      // Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('PUSH: Received foreground message');
        print('PUSH: Title: ${message.notification?.title}');
        print('PUSH: Body: ${message.notification?.body}');
        print('PUSH: Data: ${message.data}');
        _showLocalNotification(message);
      });

      // Handle Background & Terminated Messages (when notification is clicked)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('PUSH: App opened from notification');
        print('PUSH: Title: ${message.notification?.title}');
        print('PUSH: Data: ${message.data}');
        _handleNotificationClick(message.data);
      });
    } catch (e) {
      print('PushNotificationService initialization error: $e');
    }
  }

  static void _setupFCMTokenAndTopics() {
    Future.microtask(() async {
      try {
        if (Platform.isIOS) {
          // On iOS, APNS token is generated asynchronously by Apple
          try {
            final apns = await _fcm.getAPNSToken();
            print('APNS Token: $apns');
          } catch (e) {
            print('APNS Token fetch notice: $e');
          }
        }

        String? token = await _fcm.getToken();
        print('FCM Token: $token');

        // Subscribe to auth state changes to sync token whenever user logs in
        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null && token != null) {
            print('PUSH: Auth state change - user detected: ${user.uid}. Syncing token.');
            await updateUserToken(user.uid);
          }
        });

        // Sync token if user is logged in
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && token != null) {
          await updateUserToken(currentUser.uid);
        }

        // Subscribe to topics
        await _fcm.subscribeToTopic('offers');
        await _fcm.subscribeToTopic('prepaid_packs');
        print('Subscribed to "offers" and "prepaid_packs" topics');
      } catch (e) {
        print('FCM Token / Topics setup notice: $e');
      }
    });
  }

  static Future<void> updateUserToken(String userId) async {
    print('PUSH: updateUserToken called for $userId');
    try {
      String? token = await _fcm.getToken();
      if (token != null && userId.isNotEmpty) {
        print('PUSH: Syncing token to Firestore: $token');
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenSync': FieldValue.serverTimestamp(),
        });
        print('PUSH: FCM Token updated in Firestore successfully');
      } else {
        print('PUSH: Token or userId is null. Token: $token, UserId: $userId');
      }
    } catch (e) {
      print('PUSH: Error updating FCM token in Firestore: $e');
    }
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    print('Handling notification click with data: $data');
    final String? type = data['type'];
    if (type == 'order') {
      final String? orderId = data['orderId'];
      if (orderId != null) {
        _navigateToOrderTracking(orderId);
      } else {
        navigatorKey.currentState?.pushNamed('/orders');
      }
    } else if (type == 'offer') {
      navigatorKey.currentState?.pushNamed('/offers');
    } else if (type == 'prepaid_pack') {
      navigatorKey.currentState?.pushNamed('/prepaid');
    } else {
      navigatorKey.currentState?.pushNamed('/home');
    }
  }

  static void _navigateToOrderTracking(String orderId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      
      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      if (doc.exists) {
        final order = models.Order.fromJson({...doc.data()!, 'id': doc.id});
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => TrackOrderScreen(order: order),
          ),
        );
      } else {
        navigatorKey.currentState?.pushNamed('/orders');
      }
    } catch (e) {
      print('Error navigating to order tracking: $e');
      if (context.mounted) Navigator.pop(context);
      navigatorKey.currentState?.pushNamed('/orders');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // Must match AndroidManifest.xml
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  // Mandatory top-level background handler
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
  }
}
