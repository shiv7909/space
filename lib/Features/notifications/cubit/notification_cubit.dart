import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/notification_utils.dart';
import '../../../services/firebase_notification_service.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNotifications extends NotificationEvent {
  final String userId;

  const InitializeNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GetFCMToken extends NotificationEvent {
  const GetFCMToken();
}

class SubscribeToSpace extends NotificationEvent {
  final String spaceId;

  const SubscribeToSpace(this.spaceId);

  @override
  List<Object?> get props => [spaceId];
}

class UnsubscribeFromSpace extends NotificationEvent {
  final String spaceId;

  const UnsubscribeFromSpace(this.spaceId);

  @override
  List<Object?> get props => [spaceId];
}

class CleanupOnLogout extends NotificationEvent {
  final String userId;

  const CleanupOnLogout(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationReady extends NotificationState {
  final String fcmToken;

  const NotificationReady(this.fcmToken);

  @override
  List<Object?> get props => [fcmToken];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationUtils _notificationUtils = NotificationUtils();
  final FirebaseNotificationService _fcmService =
      FirebaseNotificationService();

  String? _currentUserId;
  String? _currentToken;

  NotificationCubit() : super(const NotificationInitial());

  /// Initialize notifications for a user
  Future<void> initializeNotifications(String userId) async {
    try {
      emit(const NotificationLoading());
      _currentUserId = userId;

      // Initialize FCM for the user
      await _notificationUtils.onLogin(userId);

      // Get and store FCM token
      final token = await _fcmService.getFCMToken();
      _currentToken = token;

      if (token != null) {
        emit(NotificationReady(token));
      } else {
        emit(const NotificationError('Failed to get FCM token'));
      }
    } catch (e) {
      emit(NotificationError('Failed to initialize notifications: $e'));
    }
  }

  /// Get current FCM token
  Future<void> getFCMToken() async {
    try {
      emit(const NotificationLoading());
      final token = await _fcmService.getFCMToken();
      _currentToken = token;

      if (token != null) {
        emit(NotificationReady(token));
      } else {
        emit(const NotificationError('Failed to get FCM token'));
      }
    } catch (e) {
      emit(NotificationError('Failed to get FCM token: $e'));
    }
  }

  /// Subscribe to space notifications
  Future<void> subscribeToSpace(String spaceId) async {
    try {
      await _notificationUtils.subscribeToSpaceNotifications(spaceId);
      // Emit ready state with current token
      if (_currentToken != null) {
        emit(NotificationReady(_currentToken!));
      }
    } catch (e) {
      emit(NotificationError('Failed to subscribe to space: $e'));
    }
  }

  /// Unsubscribe from space notifications
  Future<void> unsubscribeFromSpace(String spaceId) async {
    try {
      await _notificationUtils.unsubscribeFromSpaceNotifications(spaceId);
      // Emit ready state with current token
      if (_currentToken != null) {
        emit(NotificationReady(_currentToken!));
      }
    } catch (e) {
      emit(NotificationError('Failed to unsubscribe from space: $e'));
    }
  }

  /// Cleanup on logout
  Future<void> cleanupOnLogout(String userId) async {
    try {
      emit(const NotificationLoading());
      await _notificationUtils.onLogout(userId);
      _currentUserId = null;
      _currentToken = null;
      emit(const NotificationInitial());
    } catch (e) {
      emit(NotificationError('Failed to cleanup notifications: $e'));
    }
  }

  /// Get current token
  String? getCurrentToken() => _currentToken;
}
