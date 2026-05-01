// filepath: d:\habitz\lib\Features\discover\models\discover_models.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/space_visibility.dart';

// ─── HabitPreview ─────────────────────────────────────────────────────────
class HabitPreview {
  final String name;
  final String? emoji;
  final String? mode; // 'infinite' | 'challenge'

  bool get isChallenge => mode == 'challenge';

  const HabitPreview({required this.name, this.emoji, this.mode});

  factory HabitPreview.fromJson(Map<String, dynamic> j) => HabitPreview(
    name: j['name'] as String,
    emoji: j['emoji'] as String?,
    mode: j['mode'] as String?,
  );
}

// ─── DiscoverSpace ────────────────────────────────────────────────────────
class DiscoverSpace {
  final String spaceId;
  final String spaceName;
  final String spaceType;
  final String? description;
  final SpaceVisibility visibility;
  final int memberLimit;
  final int memberCount;
  final int habitCount;
  final int challengeCount;
  final List<HabitPreview> habitPreviews;
  final double avgStreak;
  final double trendingScore;
  final double velocity;
  final bool iRequested;
  final double? distanceKm;
  // Owner
  final String ownerName;
  final String? ownerAvatarKey;
  final String? ownerPhotoKey;
  // ── NEW fields ────────────────────────────────────────────────────────
  final String? categoryName;
  final String? categoryEmoji;
  final int spotsLeft;
  final double logs7d;
  final double activeMembers7d;
  final double velocity7d;


  // ── Computed helpers ─────────────────────────────────────────────────
  bool get isNearby => visibility == SpaceVisibility.nearby;
  bool get isPublic => visibility == SpaceVisibility.public;
  bool get hasChallenge => challengeCount > 0;
  bool get isFull => memberCount >= memberLimit;

  /// Trending if velocity7d is meaningfully high
  bool get isTrending => velocity7d >= 1.0 || trendingScore >= 10;

  /// Human-readable category tag e.g. "💪 Fitness"
  String? get categoryTag {
    if (categoryName == null) return null;
    final emoji = categoryEmoji != null ? '$categoryEmoji ' : '';
    return '$emoji$categoryName';
  }

  /// Get owner image URL: Profile photo > Avatar (with full Supabase CDN URLs)
  String? get ownerProfilePhotoUrl {
    const base = 'https://xsclsoatsdadwtmjbffb.supabase.co/storage/v1/object/public';

    // ✅ Prefer real profile photo first
    if (ownerPhotoKey != null && ownerPhotoKey!.isNotEmpty) {
      return '$base/profile-photos/$ownerPhotoKey';
    }

    // ✅ Fall back to avatar
    if (ownerAvatarKey != null && ownerAvatarKey!.isNotEmpty) {
      return '$base/Avatars/$ownerAvatarKey';
    }

    return null;
  }

  /// "47 completions this week"
  String? get activityLabel {
    if (logs7d <= 0) return null;
    final n = logs7d.toInt();
    return '$n completion${n == 1 ? '' : 's'} this week';
  }

  /// Active member count as int
  int get activeMembers7dInt => activeMembers7d.toInt();

  String? get distanceBadge {
    if (distanceKm == null) return null;
    if (distanceKm! < 1) return '< 1 km';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get memberCountLabel => '$memberCount/$memberLimit members';
  String get avgStreakLabel => '${avgStreak.toStringAsFixed(0)} day avg streak';

  String? avatarUrl(SupabaseClient supabase) {
    if (ownerPhotoKey != null) {
      return supabase.storage.from('profile-photos').getPublicUrl(ownerPhotoKey!);
    }
    return null;
  }

  const DiscoverSpace({
    required this.spaceId,
    required this.spaceName,
    required this.spaceType,
    this.description,
    required this.visibility,
    required this.memberLimit,
    required this.memberCount,
    required this.habitCount,
    required this.challengeCount,
    required this.habitPreviews,
    required this.avgStreak,
    required this.trendingScore,
    required this.velocity,
    required this.iRequested,
    this.distanceKm,
    required this.ownerName,
    this.ownerAvatarKey,
    this.ownerPhotoKey,
    // NEW
    this.categoryName,
    this.categoryEmoji,
    this.spotsLeft = 0,
    this.logs7d = 0,
    this.activeMembers7d = 0,
    this.velocity7d = 0,

  });

  factory DiscoverSpace.fromJson(Map<String, dynamic> j) => DiscoverSpace(
    spaceId:       j['id'] as String,
    spaceName:     j['space_name'] as String,
    spaceType:     j['space_type'] as String,
    description:   j['description'] as String?,
    visibility:    SpaceVisibility.fromString(j['visibility'] as String? ?? 'private'),
    memberLimit:   j['member_limit'] as int? ?? 10,
    memberCount:   j['member_count'] as int? ?? 0,
    habitCount:    j['habit_count'] as int? ?? 0,
    challengeCount: j['challenge_count'] as int? ?? 0,
    habitPreviews: (j['habit_previews'] as List? ?? [])
        .map((h) => HabitPreview.fromJson(h as Map<String, dynamic>))
        .toList(),
    avgStreak:     (j['avg_streak'] as num? ?? 0).toDouble(),
    trendingScore: (j['sort_score'] as num? ?? 0).toDouble(),
    velocity:      (j['velocity_7d'] as num? ?? 0).toDouble(), // Mapped velocity7d
    iRequested:    j['i_requested'] as bool? ?? false,
    distanceKm:    (j['distance_km'] as num?)?.toDouble(),
    ownerName:     j['owner_name'] as String? ?? 'Unknown Host',
    ownerAvatarKey: j['owner_avatar_key'] as String?,
    ownerPhotoKey:  j['owner_photo_key'] as String?,
    // NEW
    categoryName:    j['category_name'] as String?,
    categoryEmoji:   j['category_emoji'] as String?,
    spotsLeft:       j['spots_left'] as int? ?? 0,
    logs7d:          (j['logs_7d'] as num? ?? 0).toDouble(),
    activeMembers7d: (j['active_members_7d'] as num? ?? 0).toDouble(),
    velocity7d:      (j['velocity_7d'] as num? ?? 0).toDouble(),

  );

  DiscoverSpace copyWith({bool? iRequested}) => DiscoverSpace(
    spaceId: spaceId,
    spaceName: spaceName,
    spaceType: spaceType,
    description: description,
    visibility: visibility,
    memberLimit: memberLimit,
    memberCount: memberCount,
    habitCount: habitCount,
    challengeCount: challengeCount,
    habitPreviews: habitPreviews,
    avgStreak: avgStreak,
    trendingScore: trendingScore,
    velocity: velocity,
    iRequested: iRequested ?? this.iRequested,
    distanceKm: distanceKm,
    ownerName: ownerName,
    ownerAvatarKey: ownerAvatarKey,
    ownerPhotoKey: ownerPhotoKey,
    categoryName: categoryName,
    categoryEmoji: categoryEmoji,
    spotsLeft: spotsLeft,
    logs7d: logs7d,
    activeMembers7d: activeMembers7d,
    velocity7d: velocity7d,

  );
}

// ─── ActivePerson ─────────────────────────────────────────────────────────
class ActivePerson {
  final String userId;
  final String displayName;
  final String? avatarKey;
  final String? photoKey;
  final int completedCount;
  final String? sampleHabitName;
  final String? sampleHabitEmoji;
  final double? distanceKm;

  String get firstName => displayName.split(' ').first;

  String get subtitle {
    if (sampleHabitName == null) return 'Active today';
    final emoji = sampleHabitEmoji ?? '';
    return '$emoji $sampleHabitName'.trim();
  }

  String? get distanceBadge {
    if (distanceKm == null) return null;
    if (distanceKm! < 1) return '< 1 km';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  const ActivePerson({
    required this.userId,
    required this.displayName,
    this.avatarKey,
    this.photoKey,
    required this.completedCount,
    this.sampleHabitName,
    this.sampleHabitEmoji,
    this.distanceKm,
  });

  factory ActivePerson.fromJson(Map<String, dynamic> j) => ActivePerson(
    userId: j['user_id'] as String,
    displayName: j['display_name'] as String? ?? 'User',
    avatarKey: j['avatar_key'] as String?,
    photoKey: j['photo_key'] as String?,
    completedCount: j['completed_count'] as int? ?? 1,
    sampleHabitName: j['sample_habit_name'] as String?,
    sampleHabitEmoji: j['sample_habit_emoji'] as String?,
    distanceKm: j['distance_km'] != null
        ? (j['distance_km'] as num).toDouble()
        : null,
  );
}

// ─── JoinRequest (for owner's request management screen) ──────────────────
class JoinRequest {
  final String requestId;
  final String requesterId;
  final String? message;
  final DateTime requestedAt;
  final String requesterName;
  final String? requesterAvatarKey;
  final String? requesterPhotoKey;

  const JoinRequest({
    required this.requestId,
    required this.requesterId,
    this.message,
    required this.requestedAt,
    required this.requesterName,
    this.requesterAvatarKey,
    this.requesterPhotoKey,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> j) => JoinRequest(
    requestId: j['request_id'] as String,
    requesterId: j['requester_id'] as String,
    message: j['message'] as String?,
    requestedAt: DateTime.parse(j['requested_at'] as String),
    requesterName: j['requester_name'] as String? ?? 'User',
    requesterAvatarKey: j['requester_avatar_key'] as String?,
    requesterPhotoKey: j['requester_photo_key'] as String?,
  );
}

// ─── DiscoverPerson (for Active People tab with full detail) ──────────────
class DiscoverPerson {
  final String userId;
  final String displayName;
  final String? avatarId;
  final String? avatarKey;
  final String? photoId;
  final String? photoKey;
  final String? spaceType;              // smart tag — most apt space
  final String? spaceCategory;
  final String? spaceCategoryEmoji;
  final int? bestCurrentStreak;         // streak from the smart-tagged space only
  final int? daysOnApp;                 // only sent when streak is null/0
  final bool iRequested;
  final int proximityBucket;
  final List<String> availableSpaceTypes; // ALL spaces they're in e.g. ['couple','group']


  const DiscoverPerson({
    required this.userId,
    required this.displayName,
    this.avatarId,
    this.avatarKey,
    this.photoId,
    this.photoKey,
    this.spaceType,
    this.spaceCategory,
    this.spaceCategoryEmoji,
    this.bestCurrentStreak,
    this.daysOnApp,
    required this.iRequested,
    required this.proximityBucket,
    required this.availableSpaceTypes,

  });

  String get firstName => displayName.split(' ').first;

  /// Has a joinable public space
  bool get hasPublicSpace => availableSpaceTypes.isNotEmpty;

  /// Show streak or days on app
  bool get hasStreak => bestCurrentStreak != null && bestCurrentStreak! > 0;

  /// Person is in more than one joinable space type
  bool get hasMultipleSpaces => availableSpaceTypes.length > 1;

  Map<String, dynamic> toJson() => {
    'user_id':               userId,
    'display_name':          displayName,
    'avatar_id':             avatarId,
    'avatar_key':            avatarKey,
    'photo_id':              photoId,
    'photo_key':             photoKey,
    'space_type':            spaceType,
    'space_category':        spaceCategory,
    'space_category_emoji':  spaceCategoryEmoji,
    'best_current_streak':   bestCurrentStreak,
    'days_on_app':           daysOnApp,
    'i_requested':           iRequested,
    'proximity_bucket':      proximityBucket,
    'available_space_types': availableSpaceTypes,

  };

  DiscoverPerson copyWith({bool? iRequested}) => DiscoverPerson(
    userId: userId,
    displayName: displayName,
    avatarId: avatarId,
    avatarKey: avatarKey,
    photoId: photoId,
    photoKey: photoKey,
    spaceType: spaceType,
    spaceCategory: spaceCategory,
    spaceCategoryEmoji: spaceCategoryEmoji,
    bestCurrentStreak: bestCurrentStreak,
    daysOnApp: daysOnApp,
    iRequested: iRequested ?? this.iRequested,
    proximityBucket: proximityBucket,
    availableSpaceTypes: availableSpaceTypes,

  );

  factory DiscoverPerson.fromJson(Map<String, dynamic> j) => DiscoverPerson(
    userId:               j['user_id'] as String,
    displayName:          j['display_name'] as String? ?? 'User',
    avatarId:             j['avatar_id'] as String?,
    avatarKey:            j['avatar_key'] as String?,
    photoId:              j['photo_id'] as String?,
    photoKey:             j['photo_key'] as String?,
    spaceType:            j['space_type'] as String?,
    spaceCategory:        j['space_category'] as String?,
    spaceCategoryEmoji:   j['space_category_emoji'] as String?,
    bestCurrentStreak:    j['best_current_streak'] as int?,
    daysOnApp:            j['days_on_app'] as int?,
    iRequested:           j['i_requested'] as bool? ?? false,
    proximityBucket:      j['proximity_bucket'] as int? ?? 5,
    availableSpaceTypes:  j['available_space_types'] != null
        ? List<String>.from(j['available_space_types'] as List)
        : [],

  );
}

// ─── InvitableSpace (for invite picker bottom sheet) ──────────────────────
class InvitableSpace {
  final String spaceId;
  final String spaceName;
  final String spaceType;
  final int memberLimit;
  final int memberCount;
  final String? categoryName;
  final String? categoryEmoji;

  const InvitableSpace({
    required this.spaceId,
    required this.spaceName,
    required this.spaceType,
    required this.memberLimit,
    required this.memberCount,
    this.categoryName,
    this.categoryEmoji,
  });

  String get spotsLeft => '$memberCount/$memberLimit';

  factory InvitableSpace.fromJson(Map<String, dynamic> j) => InvitableSpace(
    spaceId:       j['space_id'] as String,
    spaceName:     j['space_name'] as String,
    spaceType:     j['space_type'] as String,
    memberLimit:   j['member_limit'] as int,
    memberCount:   j['member_count'] as int,
    categoryName:  j['category_name'] as String?,
    categoryEmoji: j['category_emoji'] as String?,
  );
}
