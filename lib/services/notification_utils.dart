import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_notification_service.dart';

/// Notification utility for managing subscriptions and tokens
class NotificationUtils {
  static final NotificationUtils _instance = NotificationUtils._internal();

  factory NotificationUtils() {
    return _instance;
  }

  NotificationUtils._internal();

  final _fcmService = FirebaseNotificationService();

  /// Subscribe user to relevant topics based on their data
  Future<void> subscribeUserToTopics(String userId) async {
    try {
      // Subscribe to user-specific notifications
      await _fcmService.subscribeToTopic('user_$userId');

      // Subscribe to general topics
      await _fcmService.subscribeToTopic('all_users');
      await _fcmService.subscribeToTopic('invites');

      print('Subscribed user $userId to notification topics');
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }

  /// Unsubscribe user from all topics
  Future<void> unsubscribeUserFromTopics(String userId) async {
    try {
      await _fcmService.unsubscribeFromTopic('user_$userId');
      await _fcmService.unsubscribeFromTopic('all_users');
      await _fcmService.unsubscribeFromTopic('invites');

      print('Unsubscribed user $userId from notification topics');
    } catch (e) {
      print('Error unsubscribing from topics: $e');
    }
  }

  /// Subscribe to space-specific notifications
  Future<void> subscribeToSpaceNotifications(String spaceId) async {
    try {
      await _fcmService.subscribeToTopic('space_$spaceId');
      print('Subscribed to space $spaceId notifications');
    } catch (e) {
      print('Error subscribing to space notifications: $e');
    }
  }

  /// Unsubscribe from space-specific notifications
  Future<void> unsubscribeFromSpaceNotifications(String spaceId) async {
    try {
      await _fcmService.unsubscribeFromTopic('space_$spaceId');
      print('Unsubscribed from space $spaceId notifications');
    } catch (e) {
      print('Error unsubscribing from space notifications: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    return await _fcmService.getFCMToken();
  }

  /// Update FCM token in Supabase
  Future<void> updateFCMTokenInSupabase() async {
    try {
      final token = await _fcmService.getFCMToken();
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null && token != null) {
        await supabase.from('profiles').update({
          'fcm_token': token,
        }).eq('id', user.id);

        print('FCM token updated in Supabase');
      }
    } catch (e) {
      print('Error updating FCM token in Supabase: $e');
    }
  }

  /// Clear notifications on logout
  Future<void> onLogout(String userId) async {
    try {
      await unsubscribeUserFromTopics(userId);
      await _fcmService.deleteFCMToken();
      print('Notifications cleared on logout');
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Get FCM token and save to Supabase (call after login)
  Future<void> onLogin(String userId) async {
    try {
      await subscribeUserToTopics(userId);
      await updateFCMTokenInSupabase();
      print('Notifications initialized for user $userId');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
}

