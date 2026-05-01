import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Navigation callback typedef ──
typedef NotificationNavigationCallback = void Function(Map<String, dynamic>);

/// Background message handler — must be a top-level function.
///
/// Runs in a **separate Dart isolate** when the app is in background or terminated.
/// Firebase MUST be initialized here because the isolate has a fresh context.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ── CRITICAL: Initialize Firebase in the background isolate ──
  await Firebase.initializeApp();

  print('🔵 Background message: ${message.messageId}');
  print('📦 Background data: ${message.data}');

  // If the message has a `notification` payload, Android already shows it
  // in the system tray automatically. Only show a local notification for
  // data-only messages (no `notification` block) — this prevents duplicates.
  if (message.notification == null && message.data.isNotEmpty) {
    await _showLocalNotification(message);
  }
}

/// Show local notification — works from both foreground and background isolate
Future<void> _showLocalNotification(RemoteMessage message) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize the plugin (required in the background isolate where the
  // singleton instance isn't carried over from the main isolate).
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'habitz_channel',
        'Habitz Notifications',
        channelDescription: 'Notifications for Habitz app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification',
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  // Encode the data map as JSON so it can be reliably parsed back
  final payload = jsonEncode(message.data);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'Habitz',
    message.notification?.body ?? 'You have a new notification',
    platformChannelSpecifics,
    payload: payload,
  );
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() {
    return _instance;
  }

  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Navigation callback - set by main_navigation.dart
  NotificationNavigationCallback? _navigationCallback;

  /// Cache for notification data if received before UI is ready
  Map<String, dynamic>? _pendingNavigationData;

  /// Set the navigation callback
  void setNavigationCallback(NotificationNavigationCallback callback) {
    _navigationCallback = callback;

    // If we received a notification tap before the callback was set (e.g. from terminated state), fire it now
    if (_pendingNavigationData != null) {
      print(
        '🚀 Firing pending notification navigation: $_pendingNavigationData',
      );
      _navigationCallback!(_pendingNavigationData!);
      _pendingNavigationData = null;
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    // Request notification permission for iOS and Android 13+
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      // Always show a local notification for foreground messages so the user
      // sees the heads-up banner, regardless of whether it has a notification
      // payload or only a data payload.
      _showLocalNotification(message);
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message);
    });

    // Get initial message if app was terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Get FCM token and save to Supabase
    await _getFCMTokenAndSave();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _saveFCMTokenToSupabase(newToken);
    });
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap from local notification
        print('🔔 Local notification tapped with payload: ${response.payload}');
        _handleLocalNotificationTap(response.payload);
      },
    );

    // Create notification channel for Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'habitz_channel',
            'Habitz Notifications',
            description: 'Notifications for Habitz app',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
          ),
        );
  }

  /// Get FCM token and save to Supabase
  Future<void> _getFCMTokenAndSave() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveFCMTokenToSupabase(token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Refresh and save FCM token - public method for manual refresh
  Future<void> refreshAndSaveFCMToken() async {
    await saveFcmToken();
  }

  /// Save FCM Token (Public requested method)
  Future<void> saveFcmToken() async {
    try {
      print('🔵 Saving FCM Token...');
      // 1. Request permission (important for iOS)
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Get the FCM token
      final token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token == null) {
        print('❌ FCM token is null — Firebase not configured correctly');
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in, skipping FCM save');
        return;
      }

      // 3. Save to Supabase
      await Supabase.instance.client.from('user_push_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');

      print('✅ FCM token saved successfully');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Save FCM token to Supabase
  Future<void> _saveFCMTokenToSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Save to user_push_tokens table with platform info
        await supabase.from('user_push_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, token');

        print('FCM token saved to user_push_tokens for user: ${user.id}');
      }
    } catch (e) {
      print('Error saving FCM token to Supabase: $e');
    }
  }

  /// Handle notification tap — routes based on notification type and data
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Handling notification tap: ${message.messageId}');
    print('📦 Notification data: ${message.data}');

    // Extract notification metadata
    final notificationType = message.data['type'] as String? ?? 'default';
    final spaceId = message.data['space_id'] as String?;
    final habitId = message.data['habit_id'] as String?;
    final snapId = message.data['snap_id'] as String?;
    final inviteId = message.data['invite_id'] as String?;

    // Build navigation payload
    final navigationData = {
      'type': notificationType,
      if (spaceId != null) 'space_id': spaceId,
      if (habitId != null) 'habit_id': habitId,
      if (snapId != null) 'snap_id': snapId,
      if (inviteId != null) 'invite_id': inviteId,
    };

    print('📍 Routing notification: type=$notificationType, spaceId=$spaceId');

    // Call the registered navigation callback if available
    if (_navigationCallback != null) {
      _navigationCallback!(navigationData);
    } else {
      print(
        '⚠️ Navigation callback not set — notification ignored, saving to pending',
      );
      _pendingNavigationData = navigationData;
    }
  }

  /// Handle notification tap from local notification payload
  void _handleLocalNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      print('⚠️ Local notification payload is null or empty');
      return;
    }

    print('📦 Parsing local notification payload: $payload');

    try {
      // Payload is now JSON-encoded (see _showLocalNotification)
      final Map<String, dynamic> navigationData = Map<String, dynamic>.from(
        jsonDecode(payload) as Map,
      );

      print('🔍 Parsed navigation data: $navigationData');

      if (navigationData.isNotEmpty) {
        _handleNotificationNavigation(navigationData);
      } else {
        print('⚠️ Empty data in payload');
      }
    } catch (e) {
      print('❌ Error parsing local notification payload: $e');
      print('Raw payload: $payload');

      // Fallback: try legacy Map.toString() format for any old cached notifications
      _parseLegacyPayload(payload);
    }
  }

  /// Fallback parser for old Map.toString() format payloads
  void _parseLegacyPayload(String payload) {
    try {
      final Map<String, dynamic> navigationData = {};
      var cleanPayload = payload.replaceAll('{', '').replaceAll('}', '').trim();
      final regex = RegExp(r'(\w+):\s*([^,]+)(?:,|$)');
      final matches = regex.allMatches(cleanPayload);

      for (final match in matches) {
        final key = match.group(1)?.trim() ?? '';
        final value = match.group(2)?.trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          navigationData[key] = value;
        }
      }

      if (navigationData.isNotEmpty) {
        print('🔄 Parsed via legacy format: $navigationData');
        _handleNotificationNavigation(navigationData);
      }
    } catch (e) {
      print('❌ Legacy parsing also failed: $e');
    }
  }

  /// Handle notification navigation based on data
  /// Simply forwards the parsed data map to the UI callback.
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'default';

    print('📍 Local notification navigation: type=$type, data=$data');

    // Call the registered navigation callback if available
    if (_navigationCallback != null) {
      _navigationCallback!(data);
    } else {
      print(
        '⚠️ Navigation callback not set for local notification, saving to pending',
      );
      _pendingNavigationData = data;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Delete FCM token from Supabase on logout
  Future<void> deleteTokenOnLogout() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Delete all tokens for this user
        await supabase.from('user_push_tokens').delete().eq('user_id', user.id);

        print('FCM tokens deleted for user: ${user.id}');
      }

      // Also delete the FCM token from Firebase
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}
