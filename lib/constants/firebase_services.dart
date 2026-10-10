import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:single_clik/constants/show_toast.dart';
import 'package:single_clik/utils/shar_preferences.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important push notifications.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🌙 Background Notification Received: ${message.messageId}");
  debugPrint("Title: ${message.notification?.title}");
  debugPrint("Body: ${message.notification?.body}");
}

class FirebaseService {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    try {
      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Setup Local Notifications for Android & iOS system banners
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

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("🔔 Notification Tapped: ${response.payload}");
        },
      );

      // Create High Importance Channel for Android
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }

      // 3. Request Notification Permission
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("❌ Notification permission denied.");
      } else {
        debugPrint("✅ Notification permission status: ${settings.authorizationStatus}");
      }

      // 4. Get Push Token (APNS Token on iOS, FCM Token on Android)
      String? token;
      if (Platform.isIOS) {
        token = await firebaseMessaging.getAPNSToken();
        debugPrint('APNS Token: $token');
        if (token == null) {
          await Future.delayed(const Duration(seconds: 1));
          token = await firebaseMessaging.getAPNSToken();
          debugPrint('APNS Token retry: $token');
        }
      } else {
        token = await firebaseMessaging.getToken();
      }

      if (token != null && token.isNotEmpty) {
        await SharPreferences.setString(SharPreferences.fcmToken, token);
        debugPrint("✅ Push Token Initialized (${Platform.isIOS ? 'APNS' : 'FCM'}): $token");
      } else {
        debugPrint("⚠️ Failed to retrieve Push Token during init");
      }

      // Listen for token refreshes and update storage
      if (Platform.isAndroid) {
        firebaseMessaging.onTokenRefresh.listen((String newToken) async {
          debugPrint("🔄 FCM Token Refreshed: $newToken");
          await SharPreferences.setString(SharPreferences.fcmToken, newToken);
        });
      }

      // Enable Auto Initialization
      await firebaseMessaging.setAutoInitEnabled(true);

      // Configure Foreground Notifications Presentation Options
      await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Handle Foreground Messages (Display System Banner + Toast)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📩 Foreground Message Received: ${message.notification?.title}");
        
        RemoteNotification? notification = message.notification;
        if (notification != null) {
          // Trigger local system banner
          _flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel.id,
                _androidChannel.name,
                channelDescription: _androidChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );

          // Show Toast as well
          ShowToast.showToast(
            "${notification.title ?? 'Notification'}: ${notification.body ?? ''}",
            showSuccess: true,
          );
        }
      });

      // Handle Notification Click / Open App from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("🔔 Notification Clicked from Background: ${message.notification?.title}");
      });

      debugPrint("✅ Firebase Notifications Initialized Successfully");
    } catch (e) {
      debugPrint("❌ Firebase Messaging Error: $e");
    }
  }

  /// Fetches the push token (APNS token on iOS, FCM token on Android)
  /// with cache check and device ID fallback.
  static Future<String> getFcmToken() async {
    try {
      // 1. Try to get direct fresh token from Firebase/APNS depending on platform
      String? token;
      if (Platform.isIOS) {
        token = await FirebaseMessaging.instance.getAPNSToken();
        if (token == null) {
          await Future.delayed(const Duration(seconds: 1));
          token = await FirebaseMessaging.instance.getAPNSToken();
        }
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null && token.trim().isNotEmpty) {
        await SharPreferences.setString(SharPreferences.fcmToken, token.trim());
        debugPrint("✅ Fetched direct ${Platform.isIOS ? 'APNS' : 'FCM'} Token: ${token.trim()}");
        return token.trim();
      }
    } catch (e) {
      debugPrint("⚠️ Direct Push Token fetch failed: $e");
    }

    // 2. Check SharedPreferences cached token
    try {
      String? cachedToken = await SharPreferences.getString(SharPreferences.fcmToken);
      if (cachedToken != null &&
          cachedToken.trim().isNotEmpty &&
          cachedToken != "Unknown_Device") {
        debugPrint("✅ Using cached Token: ${cachedToken.trim()}");
        return cachedToken.trim();
      }
    } catch (e) {
      debugPrint("⚠️ SharedPreferences Token read failed: $e");
    }

    // 3. Fallback to physical device ID if push token is unavailable (e.g. simulator without Play services/APNS)
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.id.isNotEmpty) {
          debugPrint("ℹ️ Using Android Device ID fallback: ${androidInfo.id}");
          return androidInfo.id;
        }
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        if (iosInfo.identifierForVendor != null && iosInfo.identifierForVendor!.isNotEmpty) {
          debugPrint("ℹ️ Using iOS Device ID fallback: ${iosInfo.identifierForVendor}");
          return iosInfo.identifierForVendor!;
        }
      }
    } catch (e) {
      debugPrint("⚠️ DeviceInfo fallback failed: $e");
    }

    return "Device_${DateTime.now().millisecondsSinceEpoch}";
  }
}
