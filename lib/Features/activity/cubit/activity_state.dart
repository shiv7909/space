import 'package:equatable/equatable.dart';

enum ActivityStatus { initial, loading, success, failure }

class ActivityState extends Equatable {
  final ActivityStatus status;
  final List<Map<String, dynamic>> forYouItems;
  final List<Map<String, dynamic>> sentRequests;
  final List<Map<String, dynamic>> sentInvites;
  final int badgeCount;
  final String? errorMessage;

  // One-off event data for conflicts
  final Map<String, dynamic>? conflictItem;
  final String? conflictMessage;
  final bool? conflictIsOwner;
  final String? conflictType; // 'join_request' or 'invite'

  // Navigation Trigger
  final String? joinedSpaceId;
  final String? joinedSpaceType;

  const ActivityState({
    this.status = ActivityStatus.initial,
    this.forYouItems = const [],
    this.sentRequests = const [],
    this.sentInvites = const [],
    this.badgeCount = 0,
    this.errorMessage,
    this.conflictItem,
    this.conflictMessage,
    this.conflictIsOwner,
    this.conflictType,
    this.joinedSpaceId,
    this.joinedSpaceType,
  });

  ActivityState copyWith({
    ActivityStatus? status,
    List<Map<String, dynamic>>? forYouItems,
    List<Map<String, dynamic>>? sentRequests,
    List<Map<String, dynamic>>? sentInvites,
    int? badgeCount,
    String? errorMessage,
    Map<String, dynamic>? conflictItem,
    String? conflictMessage,
    bool? conflictIsOwner,
    String? conflictType,
    String? joinedSpaceId,
    String? joinedSpaceType,
  }) {
    return ActivityState(
      status: status ?? this.status,
      forYouItems: forYouItems ?? this.forYouItems,
      sentRequests: sentRequests ?? this.sentRequests,
      sentInvites: sentInvites ?? this.sentInvites,
      badgeCount: badgeCount ?? this.badgeCount,
      errorMessage: errorMessage,
      conflictItem: conflictItem, // intent: pass null to clear
      conflictMessage: conflictMessage,
      conflictIsOwner: conflictIsOwner,
      conflictType: conflictType,
      joinedSpaceId: joinedSpaceId, // intent: pass null to clear
      joinedSpaceType: joinedSpaceType,
    );
  }

  // Helper to clear conflict state
  ActivityState clearConflict() {
    return ActivityState(
      status: status,
      forYouItems: forYouItems,
      sentRequests: sentRequests,
      sentInvites: sentInvites,
      badgeCount: badgeCount,
      errorMessage: errorMessage,
      conflictItem: null,
      conflictMessage: null,
      conflictIsOwner: null,
      conflictType: null,
      joinedSpaceId: joinedSpaceId,
      joinedSpaceType: joinedSpaceType,
    );
  }

  // Helper to clear navigation
  ActivityState clearNavigation() {
     return ActivityState(
      status: status,
      forYouItems: forYouItems,
      sentRequests: sentRequests,
      sentInvites: sentInvites,
      badgeCount: badgeCount,
      errorMessage: errorMessage,
      conflictItem: conflictItem,
      conflictMessage: conflictMessage,
      conflictIsOwner: conflictIsOwner,
      conflictType: conflictType,
      joinedSpaceId: null,
      joinedSpaceType: null,
    );
  }

  @override
  List<Object?> get props => [
        status,
        forYouItems,
        sentRequests,
        sentInvites,
        badgeCount,
        errorMessage,
        conflictItem,
        conflictMessage,
        conflictIsOwner,
        conflictType,
        joinedSpaceId,
        joinedSpaceType,
      ];
}
