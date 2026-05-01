// ============================================================
// brand_snap_model.dart
// Brand snap models matching the brand RPC response shape.
// ============================================================

enum BrandSnapReaction { fire, flex, heart }

extension BrandSnapReactionExt on BrandSnapReaction {
  String get value {
    switch (this) {
      case BrandSnapReaction.fire:
        return 'fire';
      case BrandSnapReaction.flex:
        return 'flex';
      case BrandSnapReaction.heart:
        return 'heart';
    }
  }

  String get emoji {
    switch (this) {
      case BrandSnapReaction.fire:
        return '🔥';
      case BrandSnapReaction.flex:
        return '💪';
      case BrandSnapReaction.heart:
        return '❤️';
    }
  }

  static BrandSnapReaction fromString(String value) {
    switch (value) {
      case 'fire':
        return BrandSnapReaction.fire;
      case 'flex':
        return BrandSnapReaction.flex;
      case 'heart':
        return BrandSnapReaction.heart;
      default:
        return BrandSnapReaction.fire;
    }
  }
}

class BrandSnapModel {
  final String id;
  final String challengeId;
  final String senderId;
  final String senderName;
  final String? senderAvatarKey;
  final String? senderPhotoKey;
  final String storagePath;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool didIView;
  final bool isMine;
  final int fireCount;
  final int flexCount;
  final int heartCount;
  final String? myReaction;
  final String? signedUrl;

  const BrandSnapModel({
    required this.id,
    required this.challengeId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarKey,
    this.senderPhotoKey,
    required this.storagePath,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewCount,
    required this.didIView,
    required this.isMine,
    required this.fireCount,
    required this.flexCount,
    required this.heartCount,
    this.myReaction,
    this.signedUrl,
  });

  factory BrandSnapModel.fromJson(Map<String, dynamic> json) {
    final sender =
        json['sender'] is Map
            ? Map<String, dynamic>.from(json['sender'] as Map)
            : const <String, dynamic>{};
    final reactions =
        json['reactions'] is Map
            ? Map<String, dynamic>.from(json['reactions'] as Map)
            : const <String, dynamic>{};

    return BrandSnapModel(
      id: (json['id'] ?? '').toString(),
      challengeId: (json['challenge_id'] ?? '').toString(),
      senderId: (sender['id'] ?? json['sender_id'] ?? '').toString(),
      senderName:
          (sender['display_name'] as String?) ??
          (json['sender_name'] as String?) ??
          (json['display_name'] as String?) ??
          'User',
      senderAvatarKey:
          (sender['avatar_key'] as String?) ??
          (json['sender_avatar_key'] as String?) ??
          (json['avatar_key'] as String?),
      senderPhotoKey:
          (sender['photo_key'] as String?) ??
          (json['sender_photo_key'] as String?) ??
          (json['photo_key'] as String?),
      storagePath: (json['storage_path'] as String?) ?? '',
      caption: json['caption'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : DateTime.now(),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      didIView:
          json['did_i_view'] as bool? ?? json['i_viewed'] as bool? ?? false,
      isMine: json['is_mine'] as bool? ?? false,
      fireCount:
          (reactions['fire'] as num?)?.toInt() ??
          (json['fire_count'] as num?)?.toInt() ??
          0,
      flexCount:
          (reactions['flex'] as num?)?.toInt() ??
          (json['flex_count'] as num?)?.toInt() ??
          0,
      heartCount:
          (reactions['heart'] as num?)?.toInt() ??
          (json['heart_count'] as num?)?.toInt() ??
          0,
      myReaction: json['my_reaction'] as String?,
    );
  }

  int get totalReactionCount => fireCount + flexCount + heartCount;
  bool get hasReacted => myReaction != null;
  bool get reactedFire => myReaction == 'fire';
  bool get reactedFlex => myReaction == 'flex';
  bool get reactedHeart => myReaction == 'heart';

  BrandSnapModel copyWith({String? signedUrl}) {
    return BrandSnapModel(
      id: id,
      challengeId: challengeId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarKey: senderAvatarKey,
      senderPhotoKey: senderPhotoKey,
      storagePath: storagePath,
      caption: caption,
      createdAt: createdAt,
      expiresAt: expiresAt,
      viewCount: viewCount,
      didIView: didIView,
      isMine: isMine,
      fireCount: fireCount,
      flexCount: flexCount,
      heartCount: heartCount,
      myReaction: myReaction,
      signedUrl: signedUrl ?? this.signedUrl,
    );
  }
}

class BrandSnapPageResult {
  final List<BrandSnapModel> snaps;
  final bool hasMore;
  final String? nextCursor;
  final bool postedToday;
  final int totalToday;

  const BrandSnapPageResult({
    required this.snaps,
    required this.hasMore,
    required this.postedToday,
    required this.totalToday,
    this.nextCursor,
  });

  factory BrandSnapPageResult.fromJson(Map<String, dynamic> json) {
    final rawSnaps = json['snaps'] as List? ?? const [];
    return BrandSnapPageResult(
      snaps:
          rawSnaps
              .map(
                (item) => BrandSnapModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      hasMore: json['has_more'] as bool? ?? false,
      nextCursor: json['next_cursor'] as String?,
      postedToday: json['posted_today'] as bool? ?? false,
      totalToday: (json['total_today'] as num?)?.toInt() ?? 0,
    );
  }
}

class BrandSnapViewResponse {
  final String snapId;
  final String storagePath;
  final String signedUrl;
  final String? caption;
  final String senderId;
  final String senderName;
  final String? senderAvatarKey;
  final String? senderPhotoKey;
  final DateTime? expiresAt;
  final Map<String, int> reactions;
  final String? myReaction;

  const BrandSnapViewResponse({
    required this.snapId,
    required this.storagePath,
    required this.signedUrl,
    required this.senderId,
    required this.senderName,
    this.caption,
    this.senderAvatarKey,
    this.senderPhotoKey,
    this.expiresAt,
    this.reactions = const <String, int>{},
    this.myReaction,
  });

  factory BrandSnapViewResponse.fromJson(Map<String, dynamic> json) {
    final sender =
        json['sender'] is Map
            ? Map<String, dynamic>.from(json['sender'] as Map)
            : const <String, dynamic>{};
    final reactions =
        json['reactions'] is Map
            ? Map<String, dynamic>.from(json['reactions'] as Map)
            : const <String, dynamic>{};

    return BrandSnapViewResponse(
      snapId: (json['snap_id'] ?? json['id'] ?? '').toString(),
      storagePath: (json['storage_path'] ?? '').toString(),
      signedUrl: (json['signed_url'] ?? '').toString(),
      caption: json['caption'] as String?,
      senderId: (sender['id'] ?? json['sender_id'] ?? '').toString(),
      senderName:
          (sender['display_name'] as String?) ??
          (json['sender_display_name'] as String?) ??
          (json['sender_name'] as String?) ??
          'User',
      senderAvatarKey:
          (sender['avatar_key'] as String?) ??
          (json['sender_avatar_key'] as String?) ??
          (json['avatar_key'] as String?),
      senderPhotoKey:
          (sender['photo_key'] as String?) ??
          (json['sender_photo_key'] as String?) ??
          (json['photo_key'] as String?),
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : null,
      reactions: reactions.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
      myReaction: json['my_reaction'] as String?,
    );
  }
}
