// ============================================================
// snap_sender_response.dart
// Models for sender-snap RPCs:
//   - get_space_sender_snaps  → SpaceSenderSnapsResponse
//   - get_sender_snaps        → ChallengeSenderSnapsResponse
// ============================================================

// ─────────────────────────────────────────────────────────────
// SHARED — Sender info
// ─────────────────────────────────────────────────────────────

class SnapSenderInfo {
  final String  id;
  final String  displayName;
  final String? avatarId;
  final String? avatarKey;
  final String? photoId;
  final String? photoKey;

  const SnapSenderInfo({
    required this.id,
    required this.displayName,
    this.avatarId,
    this.avatarKey,
    this.photoId,
    this.photoKey,
  });

  factory SnapSenderInfo.fromJson(Map<String, dynamic> j) => SnapSenderInfo(
    id:          (j['id'] ?? j['sender_id'] ?? '').toString(),
    displayName:
      (j['display_name'] as String?) ??
      (j['sender_name'] as String?) ??
      (j['name'] as String?) ??
      'User',
    avatarId:
      (j['avatar_id'] as String?) ??
      (j['sender_avatar_id'] as String?),
    avatarKey:
      (j['avatar_key'] as String?) ??
      (j['sender_avatar_key'] as String?),
    photoId:
      (j['photo_id'] as String?) ??
      (j['sender_photo_id'] as String?),
    photoKey:
      (j['photo_key'] as String?) ??
      (j['sender_photo_key'] as String?),
  );

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────
// SPACE — Individual snap from get_space_sender_snaps
// ─────────────────────────────────────────────────────────────

class SpaceSenderSnap {
  final String   id;
  final String   storagePath;
  final String?  caption;
  final String?  habitId;
  final String?  habitName;
  final String?  habitEmoji;
  final DateTime snapDate;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool     isMine;
  final bool     iViewed;
  final int      viewCount;
  // Reactions as a map: { fire: 2, strong: 1, ... }
  final int      fireCount;
  final int      strongCount;
  final int      laughCount;
  final int      eyesCount;
  final int      heartCount;
  final String?  myReaction;

  const SpaceSenderSnap({
    required this.id,
    required this.storagePath,
    this.caption,
    this.habitId,
    this.habitName,
    this.habitEmoji,
    required this.snapDate,
    required this.createdAt,
    required this.expiresAt,
    required this.isMine,
    required this.iViewed,
    required this.viewCount,
    required this.fireCount,
    required this.strongCount,
    required this.laughCount,
    required this.eyesCount,
    required this.heartCount,
    this.myReaction,
  });

  factory SpaceSenderSnap.fromJson(Map<String, dynamic> j) {
    // Parse reactions — may be a nested map or flat columns
    final reactions = j['reactions'] is Map
        ? Map<String, dynamic>.from(j['reactions'] as Map)
        : <String, dynamic>{};

    return SpaceSenderSnap(
      id:          j['id']           as String,
      storagePath: j['storage_path'] as String,
      caption:     j['caption']      as String?,
      habitId:     j['habit_id']     as String?,
      habitName:   j['habit_name']   as String?,
      habitEmoji:  j['habit_emoji']  as String?,
      snapDate:    DateTime.parse(j['snap_date']  as String),
      createdAt:   DateTime.parse(j['created_at'] as String),
      expiresAt:   DateTime.parse(j['expires_at'] as String),
      isMine:      j['is_mine']      as bool? ?? false,
      iViewed:     j['i_viewed']     as bool? ?? false,
      viewCount:   (j['view_count']  as num?)?.toInt() ?? 0,
      // Try nested reactions map first, then flat columns
      fireCount:   (reactions['fire']   as num?)?.toInt()
                       ?? (j['fire_count']   as num?)?.toInt() ?? 0,
      strongCount: (reactions['strong'] as num?)?.toInt()
                       ?? (j['strong_count'] as num?)?.toInt() ?? 0,
      laughCount:  (reactions['laugh']  as num?)?.toInt()
                       ?? (j['laugh_count']  as num?)?.toInt() ?? 0,
      eyesCount:   (reactions['eyes']   as num?)?.toInt()
                       ?? (j['eyes_count']   as num?)?.toInt() ?? 0,
      heartCount:  (reactions['heart']  as num?)?.toInt()
                       ?? (j['heart_count']  as num?)?.toInt() ?? 0,
      myReaction:  j['my_reaction']  as String?,
    );
  }

  /// Total reaction count across all types.
  int get totalReactionCount =>
      fireCount + strongCount + laughCount + eyesCount + heartCount;

  /// Get count for a specific reaction type.
  int reactionCount(String type) {
    switch (type) {
      case 'fire':   return fireCount;
      case 'strong': return strongCount;
      case 'laugh':  return laughCount;
      case 'eyes':   return eyesCount;
      case 'heart':  return heartCount;
      default: return 0;
    }
  }

  bool get hasReacted => myReaction != null;
  bool get isExpired  => DateTime.now().isAfter(expiresAt);

  SpaceSenderSnap copyWith({
    bool?   iViewed,
    int?    viewCount,
    int?    fireCount,
    int?    strongCount,
    int?    laughCount,
    int?    eyesCount,
    int?    heartCount,
    String? myReaction,
    bool    clearReaction = false,
  }) {
    return SpaceSenderSnap(
      id:          id,
      storagePath: storagePath,
      caption:     caption,
      habitId:     habitId,
      habitName:   habitName,
      habitEmoji:  habitEmoji,
      snapDate:    snapDate,
      createdAt:   createdAt,
      expiresAt:   expiresAt,
      isMine:      isMine,
      iViewed:     iViewed   ?? this.iViewed,
      viewCount:   viewCount ?? this.viewCount,
      fireCount:   fireCount ?? this.fireCount,
      strongCount: strongCount ?? this.strongCount,
      laughCount:  laughCount ?? this.laughCount,
      eyesCount:   eyesCount ?? this.eyesCount,
      heartCount:  heartCount ?? this.heartCount,
      myReaction:  clearReaction ? null : (myReaction ?? this.myReaction),
    );
  }
}

/// Full response from get_space_sender_snaps.
class SpaceSenderSnapsResponse {
  final SnapSenderInfo         sender;
  final List<SpaceSenderSnap>  snaps;

  const SpaceSenderSnapsResponse({
    required this.sender,
    required this.snaps,
  });

  factory SpaceSenderSnapsResponse.fromJson(Map<String, dynamic> j) {
    if (j['sender'] == null) {
       throw Exception('Sender cannot be null');
    }
    return SpaceSenderSnapsResponse(
      sender: SnapSenderInfo.fromJson(
                Map<String, dynamic>.from(j['sender'] as Map)),
      snaps: (j['snaps'] as List? ?? [])
               .map((e) => SpaceSenderSnap.fromJson(
                   Map<String, dynamic>.from(e as Map)))
               .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHALLENGE — Individual snap from get_sender_snaps
// ─────────────────────────────────────────────────────────────

class ChallengeSenderSnap {
  final String   id;
  final String   storagePath;
  final String?  caption;
  final DateTime snapDate;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool     isMine;
  final bool     iViewed;
  final int      viewCount;
  final int      dayNumber;
  // Challenge reactions: fire, flex, heart
  final int      fireCount;
  final int      flexCount;
  final int      heartCount;
  final String?  myReaction;

  const ChallengeSenderSnap({
    required this.id,
    required this.storagePath,
    this.caption,
    required this.snapDate,
    required this.createdAt,
    required this.expiresAt,
    required this.isMine,
    required this.iViewed,
    required this.viewCount,
    required this.dayNumber,
    required this.fireCount,
    required this.flexCount,
    required this.heartCount,
    this.myReaction,
  });

  factory ChallengeSenderSnap.fromJson(Map<String, dynamic> j) {
    final reactions = j['reactions'] is Map
        ? Map<String, dynamic>.from(j['reactions'] as Map)
        : <String, dynamic>{};

    return ChallengeSenderSnap(
      id:          j['id']           as String,
      storagePath: j['storage_path'] as String,
      caption:     j['caption']      as String?,
      snapDate:    DateTime.parse(j['snap_date']  as String),
      createdAt:   DateTime.parse(j['created_at'] as String),
      expiresAt:   DateTime.parse(j['expires_at'] as String),
      isMine:      j['is_mine']      as bool? ?? false,
      iViewed:     j['i_viewed']     as bool? ?? false,
      viewCount:   (j['view_count']  as num?)?.toInt() ?? 0,
      dayNumber:   (j['day_number']  as num?)?.toInt() ?? 0,
      fireCount:   (reactions['fire']  as num?)?.toInt()
                       ?? (j['fire_count']  as num?)?.toInt() ?? 0,
      flexCount:   (reactions['flex']  as num?)?.toInt()
                       ?? (j['flex_count']  as num?)?.toInt() ?? 0,
      heartCount:  (reactions['heart'] as num?)?.toInt()
                       ?? (j['heart_count'] as num?)?.toInt() ?? 0,
      myReaction:  j['my_reaction']  as String?,
    );
  }

  int get totalReactionCount => fireCount + flexCount + heartCount;
  bool get hasReacted => myReaction != null;
  bool get isExpired  => DateTime.now().isAfter(expiresAt);

  ChallengeSenderSnap copyWith({
    bool?   iViewed,
    int?    viewCount,
    int?    fireCount,
    int?    flexCount,
    int?    heartCount,
    String? myReaction,
    bool    clearReaction = false,
  }) {
    return ChallengeSenderSnap(
      id:          id,
      storagePath: storagePath,
      caption:     caption,
      snapDate:    snapDate,
      createdAt:   createdAt,
      expiresAt:   expiresAt,
      isMine:      isMine,
      iViewed:     iViewed   ?? this.iViewed,
      viewCount:   viewCount ?? this.viewCount,
      dayNumber:   dayNumber,
      fireCount:   fireCount ?? this.fireCount,
      flexCount:   flexCount ?? this.flexCount,
      heartCount:  heartCount ?? this.heartCount,
      myReaction:  clearReaction ? null : (myReaction ?? this.myReaction),
    );
  }
}

/// Full response from get_sender_snaps (challenge context).
class ChallengeSenderSnapsResponse {
  final SnapSenderInfo             sender;
  final List<ChallengeSenderSnap>  snaps;

  const ChallengeSenderSnapsResponse({
    required this.sender,
    required this.snaps,
  });

  factory ChallengeSenderSnapsResponse.fromJson(Map<String, dynamic> j) {
    if (j['sender'] == null) {
       throw Exception('Sender cannot be null');
    }
    return ChallengeSenderSnapsResponse(
      sender: SnapSenderInfo.fromJson(
                Map<String, dynamic>.from(j['sender'] as Map)),
      snaps: (j['snaps'] as List? ?? [])
               .map((e) => ChallengeSenderSnap.fromJson(
                   Map<String, dynamic>.from(e as Map)))
               .toList(),
    );
  }
}

/// Unified result for both snap contexts.
class SenderSnapsResult {
  final SnapSenderInfo sender;
  // This will be either List<SpaceSenderSnap> or List<ChallengeSenderSnap>
  final List<dynamic> snaps;

  const SenderSnapsResult({
    required this.sender,
    required this.snaps,
  });

  factory SenderSnapsResult.fromChallenge(Map<String, dynamic> j) {
    final parsed = ChallengeSenderSnapsResponse.fromJson(j);
    return SenderSnapsResult(sender: parsed.sender, snaps: parsed.snaps);
  }

  factory SenderSnapsResult.fromSpace(Map<String, dynamic> j) {
    final parsed = SpaceSenderSnapsResponse.fromJson(j);
    return SenderSnapsResult(sender: parsed.sender, snaps: parsed.snaps);
  }
}
