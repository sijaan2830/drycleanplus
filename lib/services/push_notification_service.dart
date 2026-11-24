import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter/material.dart';
import '../screens/track_driver_screen.dart';
import '../utils/order_status.dart';
import '../utils/route_helpers.dart'; // To access global navigatorKey
import '../models/booking_models.dart' as models;
import '../screens/track_order_screen.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inboxSub;
  static StreamSubscription<String>? _tokenRefreshSub;
  static final Set<String> _seenDocIds = {};
  static bool _initialInboxLoaded = false;

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
          if (details.payload != null && details.payload!.isNotEmpty) {
            try {
              final decoded = jsonDecode(details.payload!);
              if (decoded is Map) {
                _handleNotificationClick(Map<String, dynamic>.from(decoded));
                return;
              }
            } catch (e) {
              print('Error parsing notification payload: $e');
            }
          }
          _handleNotificationClick({});
        },
      );

      // Setup FCM token, token refresh, topics, and realtime Firestore inbox alerts
      _setupFCMTokenAndTopics();

      // Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('PUSH: Received foreground message');
        _showLocalNotification(message);
      });

      // Handle Background & Terminated Messages (when notification is clicked)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('PUSH: App opened from notification');
        _handleNotificationClick(message.data);
      });
    } catch (e) {
      print('PushNotificationService initialization error: $e');
    }
  }

  static void _setupFCMTokenAndTopics() {
    // Always sync auth + real-time Firestore notification listener (works even if APNS/Blaze isn't active)
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _listenToInAppNotifications(user);
      if (user != null) {
        await updateUserToken(user.uid);
      }
    });

    // Keep FCM token synced when refreshed (critical on iOS when APNS arrives late)
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': newToken,
          'lastTokenSync': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    Future.microtask(() async {
      try {
        if (Platform.isIOS) {
          String? apns;
          try {
            apns = await _fcm.getAPNSToken();
          } catch (e) {
            print('APNS Token fetch notice: $e');
          }
          if (apns == null) {
            print('APNS Token not yet available — waiting for onTokenRefresh');
            return;
          }
        }

        String? token = await _fcm.getToken();
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && token != null) {
          await updateUserToken(currentUser.uid);
        }

        try {
          await _fcm.subscribeToTopic('offers');
          await _fcm.subscribeToTopic('prepaid_packs');
        } catch (e) {
          print('Topic subscription notice: $e');
        }
      } catch (e) {
        print('FCM Token / Topics setup notice: $e');
      }
    });
  }

  /// Watches `users/{uid}/notifications` in real-time so status changes written
  /// by Admin Panel or Driver App immediately alert the user in foreground.
  static void _listenToInAppNotifications(User? user) {
    _inboxSub?.cancel();
    _seenDocIds.clear();
    _initialInboxLoaded = false;

    if (user == null || user.uid.isEmpty) return;

    _inboxSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(15)
        .snapshots()
        .listen((snap) {
      if (!_initialInboxLoaded) {
        for (final doc in snap.docs) {
          _seenDocIds.add(doc.id);
        }
        _initialInboxLoaded = true;
        return;
      }

      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added && !_seenDocIds.contains(change.doc.id)) {
          _seenDocIds.add(change.doc.id);
          final data = change.doc.data();
          if (data != null && data['read'] != true) {
            _showLocalNotificationDirect(
              id: change.doc.id.hashCode,
              title: '${data['title'] ?? 'DryClean Plus'}',
              body: '${data['body'] ?? ''}',
              data: {
                'type': 'order',
                if (data['orderId'] != null) 'orderId': '${data['orderId']}',
              },
            );
          }
        }
      }
    }, onError: (e) {
      print('PUSH: In-app inbox listener notice: $e');
    });
  }

  static Future<void> updateUserToken(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastTokenSync': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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

  /// Opens an order's tracking page (used by the in-app notification inbox).
  static void openOrder(String orderDocId) => _navigateToOrderTracking(orderDocId);

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
            // driver on the way / outside → straight to the live map
            builder: (context) => isLiveOrderStatus(order.status) ? TrackDriverScreen(order: order) : TrackOrderScreen(order: order),
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
    await _showLocalNotificationDirect(
      id: message.hashCode,
      title: message.notification?.title ?? 'DryClean Plus',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  static Future<void> _showLocalNotificationDirect({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // Must match AndroidManifest.xml
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: data.isNotEmpty ? jsonEncode(data) : null,
    );
  }

  // Mandatory top-level background handler
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
  }
}
