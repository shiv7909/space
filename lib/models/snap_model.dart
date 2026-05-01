/// Allowed reaction types for snaps.
enum SnapReaction { fire, strong, laugh, eyes, heart }

extension SnapReactionExt on SnapReaction {
  String get value {
    switch (this) {
      case SnapReaction.fire:
        return 'fire';
      case SnapReaction.strong:
        return 'strong';
      case SnapReaction.laugh:
        return 'laugh';
      case SnapReaction.eyes:
        return 'eyes';
      case SnapReaction.heart:
        return 'heart';
    }
  }

  String get emoji {
    switch (this) {
      case SnapReaction.fire:
        return '🔥';
      case SnapReaction.strong:
        return '💪';
      case SnapReaction.laugh:
        return '😂';
      case SnapReaction.eyes:
        return '👀';
      case SnapReaction.heart:
        return '❤️';
    }
  }

  static SnapReaction fromString(String value) {
    switch (value) {
      case 'fire':
        return SnapReaction.fire;
      case 'strong':
        return SnapReaction.strong;
      case 'flex':
        return SnapReaction.strong;
      case 'laugh':
        return SnapReaction.laugh;
      case 'eyes':
        return SnapReaction.eyes;
      case 'heart':
        return SnapReaction.heart;
      default:
        return SnapReaction.fire;
    }
  }
}

/// A single habit snap in the feed — metadata only (no image URL until viewed).
class SnapModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar; // avatar ID (legacy — kept for compat)
  final String? senderAvatarKey; // preset avatar storage key
  final String?
  senderPhotoKey; // real profile photo storage key (takes priority)
  final String? habitId;
  final String? habitName;
  final String? habitEmoji;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool iViewed;
  final bool isMine;
  final bool iReported;
  final String? storagePath;
  // Scalable interaction fields
  final int unseenCount;
  final Map<String, int> reactions;
  final int fireCount;
  final int strongCount;
  final int laughCount;
  final int eyesCount;
  final int heartCount;
  final String? myReaction;

  const SnapModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.senderAvatarKey,
    this.senderPhotoKey,
    this.habitId,
    this.habitName,
    this.habitEmoji,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.iViewed = false,
    this.isMine = false,
    this.iReported = false,
    this.storagePath,
    this.unseenCount = 0,
    this.reactions = const <String, int>{},
    this.fireCount = 0,
    this.strongCount = 0,
    this.laughCount = 0,
    this.eyesCount = 0,
    this.heartCount = 0,
    this.myReaction,
  });

  factory SnapModel.fromJson(Map<String, dynamic> json) {
    final sender =
        json['sender'] is Map
            ? Map<String, dynamic>.from(json['sender'] as Map)
            : const <String, dynamic>{};
    final rawReactions =
        json['reactions'] is Map
            ? Map<String, dynamic>.from(json['reactions'] as Map)
            : const <String, dynamic>{};
    final reactions = <String, int>{
      'fire':
          (rawReactions['fire'] as num?)?.toInt() ??
          (json['fire_count'] as num?)?.toInt() ??
          0,
      'strong':
          (rawReactions['strong'] as num?)?.toInt() ??
          (json['strong_count'] as num?)?.toInt() ??
          0,
      'laugh':
          (rawReactions['laugh'] as num?)?.toInt() ??
          (json['laugh_count'] as num?)?.toInt() ??
          0,
      'eyes':
          (rawReactions['eyes'] as num?)?.toInt() ??
          (json['eyes_count'] as num?)?.toInt() ??
          0,
      'heart':
          (rawReactions['heart'] as num?)?.toInt() ??
          (json['heart_count'] as num?)?.toInt() ??
          0,
    };

    return SnapModel(
      id: json['id'] as String,
      senderId: (sender['id'] ?? json['sender_id'] ?? '').toString(),
      senderName:
          (sender['display_name'] as String?) ??
          (json['sender_name'] as String?) ??
          (json['display_name'] as String?) ??
          'User',
      senderAvatar:
          (sender['avatar_id'] as String?) ??
          (json['sender_avatar_id'] as String?) ??
          (json['sender_avatar'] as String?) ??
          (json['avatar_id'] as String?),
      senderAvatarKey:
          (sender['avatar_key'] as String?) ??
          (json['sender_avatar_key'] as String?) ??
          (json['avatar_key'] as String?),
      senderPhotoKey:
          (sender['photo_key'] as String?) ??
          (json['sender_photo_key'] as String?) ??
          (json['photo_key'] as String?),
      habitId: json['habit_id'] as String?,
      habitName: json['habit_name'] as String?,
      habitEmoji: json['habit_emoji'] as String?,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewCount: json['view_count'] as int? ?? 0,
      iViewed: json['i_viewed'] as bool? ?? false,
      isMine: json['is_mine'] as bool? ?? false,
      iReported: json['i_reported'] as bool? ?? false,
      storagePath: json['storage_path'] as String?,
      unseenCount: (json['unseen_count'] as num?)?.toInt() ?? 0,
      reactions: reactions,
      fireCount: reactions['fire'] ?? 0,
      strongCount: reactions['strong'] ?? 0,
      laughCount: reactions['laugh'] ?? 0,
      eyesCount: reactions['eyes'] ?? 0,
      heartCount: reactions['heart'] ?? 0,
      myReaction: json['my_reaction'] as String?,
    );
  }

  /// Total reaction count across all types.
  int get totalReactionCount =>
      reactions.values.fold(0, (sum, count) => sum + count);

  /// Get count for a specific reaction type based on enum value.
  int reactionCount(String type) {
    return reactions[type] ?? 0;
  }

  /// Whether the user has reacted.
  bool get hasReacted => myReaction != null;

  /// Time remaining before expiry.
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  /// Whether this snap has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  SnapModel copyWith({
    bool? iViewed,
    int? viewCount,
    bool? iReported,
    String? storagePath,
    int? unseenCount,
    Map<String, int>? reactions,
    int? fireCount,
    int? strongCount,
    int? laughCount,
    int? eyesCount,
    int? heartCount,
    String? myReaction,
  }) {
    final updatedReactions = Map<String, int>.from(this.reactions);
    if (reactions != null) {
      updatedReactions
        ..clear()
        ..addAll(reactions);
    } else {
      if (fireCount != null) updatedReactions['fire'] = fireCount;
      if (strongCount != null) updatedReactions['strong'] = strongCount;
      if (laughCount != null) updatedReactions['laugh'] = laughCount;
      if (eyesCount != null) updatedReactions['eyes'] = eyesCount;
      if (heartCount != null) updatedReactions['heart'] = heartCount;
    }

    return SnapModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderAvatarKey: senderAvatarKey,
      senderPhotoKey: senderPhotoKey,
      habitId: habitId,
      habitName: habitName,
      habitEmoji: habitEmoji,
      caption: caption,
      createdAt: createdAt,
      expiresAt: expiresAt,
      viewCount: viewCount ?? this.viewCount,
      iViewed: iViewed ?? this.iViewed,
      isMine: isMine,
      iReported: iReported ?? this.iReported,
      storagePath: storagePath ?? this.storagePath,
      unseenCount: unseenCount ?? this.unseenCount,
      reactions: updatedReactions,
      fireCount: updatedReactions['fire'] ?? 0,
      strongCount: updatedReactions['strong'] ?? 0,
      laughCount: updatedReactions['laugh'] ?? 0,
      eyesCount: updatedReactions['eyes'] ?? 0,
      heartCount: updatedReactions['heart'] ?? 0,
      myReaction: myReaction ?? this.myReaction,
    );
  }
}
