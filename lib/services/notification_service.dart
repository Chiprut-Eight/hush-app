import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Top-level background handler — must be a top-level function (not a method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  Future<void> _log(String uid, String message) async {
    debugPrint('[FCM] $message');
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmDebugLogs': FieldValue.arrayUnion(['${DateTime.now().toIso8601String()}: $message'])
      });
    } catch (_) {}
  }

  /// Initialize FCM, request permissions, save token, and set up listeners
  Future<void> init(String uid) async {
    if (_initialized) return;

    // 1. Request permissions (critical for iOS, Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] User denied notification permissions');
      return;
    }

    debugPrint('[FCM] Permission granted: ${settings.authorizationStatus}');

    // 1.5 iOS Foreground Presentation: Tell iOS to show notifications even when app is open
    // (This was missing — eightgame has it and it's critical for iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isIOS) {
      String? apnsToken;
      try {
        await _log(uid, 'Checking APNs token...');
        apnsToken = await _messaging.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 4) {
          await _log(uid, 'APNs token null, retrying ($retries/4)...');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
          retries++;
        }
      } catch (e) {
        await _log(uid, 'Error checking APNs token: $e');
      }
      await _log(uid, 'Final APNs token: $apnsToken');
    }

    // 3. Get FCM token and save to Firestore
    try {
      await _log(uid, 'Calling getToken()...');
      final token = await _messaging.getToken();
      if (token != null) {
        await _log(uid, 'Success! Saving FCM token');
        await _saveToken(uid, token);
      } else {
        await _log(uid, 'WARNING: FCM token is null');
      }
    } catch (e) {
      await _log(uid, 'Error fetching FCM token: $e');
      // If failed initially on iOS, schedule a retry
      if (Platform.isIOS) {
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            final retryToken = await _messaging.getToken();
            if (retryToken != null) {
              await _saveToken(uid, retryToken);
            }
          } catch (retryErr) {
            debugPrint('[FCM] Retry token fetch error: $retryErr');
          }
        });
      }
    }

    // 4. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(uid, newToken);
    });

    // 5. Initialize local notifications for foreground display
    await _initLocalNotifications();

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _initialized = true;
    debugPrint('[FCM] NotificationService initialized for user: $uid');
  }

  /// Save FCM token to user's Firestore document
  Future<void> _saveToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      debugPrint('[FCM] Token saved to Firestore for $uid');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// Remove FCM token on logout
  Future<void> clearToken(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
      await _messaging.deleteToken();
      _initialized = false;
      debugPrint('[FCM] Token cleared');
    } catch (e) {
      debugPrint('[FCM] Failed to clear token: $e');
    }
  }

  /// Initialize flutter_local_notifications plugin
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[LOCAL] Notification tapped: ${response.payload}');
        // Future: Navigate to relevant screen based on payload
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'hush_notifications',
      'Hushhh Notifications',
      description: 'Notifications from the Hushhh app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Display a local notification when a message arrives while app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hush_notifications',
          'Hushhh Notifications',
          channelDescription: 'Notifications from the Hushhh app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  /// Handle notification tap (background/terminated state)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    // Future: Deep link to specific screen based on message.data
  }
}
