// ============================================================
// brand_challenge_models.dart
// Complete models matching exact RPC response shapes
// ============================================================

import 'brand_theme_data.dart';

// ─────────────────────────────────────────────────────────
// REWARD MODEL (for milestones)
// ─────────────────────────────────────────────────────────

class RewardModel {
  final String id;
  final String title;
  final String rewardType; // 'coupon' or 'physical'
  final String? imageUrl;
  final bool isFeatured;
  final bool isPhysical;
  final int? couponValidityDays;
  final bool earned;

  const RewardModel({
    required this.id,
    required this.title,
    required this.rewardType,
    this.imageUrl,
    required this.isFeatured,
    required this.isPhysical,
    this.couponValidityDays,
    this.earned = false,
  });

  factory RewardModel.fromJson(Map<String, dynamic> j) => RewardModel(
    id: (j['id'] ?? '').toString(),
    title: (j['title'] ?? 'Reward').toString(),
    rewardType: j['reward_type'] as String? ?? 'coupon',
    imageUrl: j['image_url'] as String?,
    isFeatured: j['is_featured'] as bool? ?? false,
    isPhysical: j['is_physical'] as bool? ?? false,
    couponValidityDays: (j['coupon_validity_days'] as num?)?.toInt(),
    earned: j['earned'] as bool? ?? false,
  );
}

// ─────────────────────────────────────────────────────────
// HERO CONFIG (for title highlighting)
// ─────────────────────────────────────────────────────────

class HeroConfig {
  final List<String> lines;
  final int highlightLine;
  final String highlightWord;

  const HeroConfig({
    required this.lines,
    required this.highlightLine,
    required this.highlightWord,
  });

  factory HeroConfig.fromJson(Map<String, dynamic> j) => HeroConfig(
    lines: (j['lines'] as List? ?? []).cast<String>().toList(),
    highlightLine: (j['highlightLine'] as num?)?.toInt() ?? 0,
    highlightWord: j['highlightWord'] as String? ?? '',
  );
}

// ─────────────────────────────────────────────────────────
// BRAND THEME
// ─────────────────────────────────────────────────────────

class BrandThemeColors {
  final String primary;
  final String accent;
  final String textPrimary;
  final String textSecondary;
  final String snapBorderColor;

  const BrandThemeColors({
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.snapBorderColor,
  });

  factory BrandThemeColors.fromJson(Map<String, dynamic> j) => BrandThemeColors(
    primary: j['primary'] as String? ?? '#000000',
    accent: j['accent'] as String? ?? '#FF0000',
    textPrimary: j['textPrimary'] as String? ?? '#000000',
    textSecondary: j['textSecondary'] as String? ?? '#888888',
    snapBorderColor: j['snapBorderColor'] as String? ?? '#000000',
  );

  static int _hex(String h) => int.parse(h.replaceFirst('#', '0xFF'));
  int get primaryInt => _hex(primary);
  int get accentInt => _hex(accent);
  int get textPrimaryInt => _hex(textPrimary);
  int get textSecondaryInt => _hex(textSecondary);
  int get snapBorderInt => _hex(snapBorderColor);
}

class BrandThemeComponents {
  final double cardRadius;
  final String buttonStyle;
  final String badgeStyle;
  final String snapBorderStyle;
  final double snapBorderWidth;

  const BrandThemeComponents({
    required this.cardRadius,
    required this.buttonStyle,
    required this.badgeStyle,
    required this.snapBorderStyle,
    required this.snapBorderWidth,
  });

  factory BrandThemeComponents.fromJson(Map<String, dynamic> j) =>
      BrandThemeComponents(
        cardRadius: (j['cardRadius'] as num?)?.toDouble() ?? 8.0,
        buttonStyle: j['buttonStyle'] as String? ?? 'rounded',
        badgeStyle: j['badgeStyle'] as String? ?? 'soft',
        snapBorderStyle: j['snapBorderStyle'] as String? ?? 'solid',
        snapBorderWidth: (j['snapBorderWidth'] as num?)?.toDouble() ?? 2.0,
      );

  double get cardRadiusDouble => cardRadius.toDouble();
}

class BrandThemeTypography {
  final String fontFamily;
  final String headingWeight;
  final String bodyWeight;
  final double letterSpacing;
  final String textTransform;

  const BrandThemeTypography({
    required this.fontFamily,
    required this.headingWeight,
    required this.bodyWeight,
    required this.letterSpacing,
    required this.textTransform,
  });

  factory BrandThemeTypography.fromJson(Map<String, dynamic> j) =>
      BrandThemeTypography(
        fontFamily: j['fontFamily'] as String? ?? 'Inter',
        headingWeight: j['headingWeight']?.toString() ?? '700',
        bodyWeight: j['bodyWeight']?.toString() ?? '400',
        letterSpacing: (j['letterSpacing'] as num?)?.toDouble() ?? 0.0,
        textTransform: j['textTransform'] as String? ?? 'none',
      );

  bool get isUppercase => textTransform == 'uppercase';
}

class BrandTheme {
  final BrandThemeColors colors;
  final BrandThemeComponents components;
  final BrandThemeTypography typography;

  const BrandTheme({
    required this.colors,
    required this.components,
    required this.typography,
  });

  factory BrandTheme.fromJson(Map<String, dynamic> j) => BrandTheme(
    colors:
        j['colors'] is Map
            ? BrandThemeColors.fromJson(
              Map<String, dynamic>.from(j['colors'] as Map),
            )
            : BrandThemeColors.fromJson(const {}),
    components:
        j['components'] is Map
            ? BrandThemeComponents.fromJson(
              Map<String, dynamic>.from(j['components'] as Map),
            )
            : BrandThemeComponents.fromJson(const {}),
    typography:
        j['typography'] is Map
            ? BrandThemeTypography.fromJson(
              Map<String, dynamic>.from(j['typography'] as Map),
            )
            : BrandThemeTypography.fromJson(const {}),
  );
}

class BrandModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? bannerUrl;
  final String? description;
  final String? websiteUrl;
  final String? contactEmail;
  final bool isVerified;
  final BrandTheme? brandTheme;
  final Map<String, dynamic>
  rawTheme; // Provided for backwards compat parsedTheme

  const BrandModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.bannerUrl,
    this.description,
    this.websiteUrl,
    this.contactEmail,
    required this.isVerified,
    this.brandTheme,
    this.rawTheme = const {},
  });

  factory BrandModel.fromJson(Map<String, dynamic> j) => BrandModel(
    id: j['id'] as String,
    name: j['name'] as String,
    logoUrl: j['logo_url'] as String?,
    bannerUrl: j['banner_url'] as String?,
    description: j['description'] as String?,
    websiteUrl: j['website_url'] as String?,
    contactEmail: j['contact_email'] as String?,
    isVerified: j['is_verified'] as bool? ?? false,
    brandTheme:
        j['brand_theme'] != null
            ? BrandTheme.fromJson(
              Map<String, dynamic>.from(j['brand_theme'] as Map),
            )
            : null,
    rawTheme:
        j['brand_theme'] is Map
            ? Map<String, dynamic>.from(j['brand_theme'] as Map)
            : {},
  );

  BrandThemeData get parsedTheme => BrandThemeData.fromJson(rawTheme);
}

// ─────────────────────────────────────────────────────────
// HABIT
// ─────────────────────────────────────────────────────────

class HabitModel {
  final String id;
  final String name;
  final String? emoji;
  final List<int> scheduledDays;

  const HabitModel({
    required this.id,
    required this.name,
    this.emoji,
    required this.scheduledDays,
  });

  factory HabitModel.fromJson(Map<String, dynamic> j) => HabitModel(
    id: j['id'] as String,
    name: j['name'] as String,
    emoji: j['emoji'] as String?,
    scheduledDays:
        (j['scheduled_days'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
  );
}

// ─────────────────────────────────────────────────────────
// USER CHALLENGE STATS (for past challenges)
// ──────────────────────────────────────���──────────────────

class UserChallengeStats {
  final int totalLogs;
  final int bestStreak;
  final int completionPct;

  const UserChallengeStats({
    required this.totalLogs,
    required this.bestStreak,
    required this.completionPct,
  });

  factory UserChallengeStats.fromJson(Map<String, dynamic> j) =>
      UserChallengeStats(
        totalLogs: (j['total_logs'] as num?)?.toInt() ?? 0,
        bestStreak: (j['best_streak'] as num?)?.toInt() ?? 0,
        completionPct: (j['completion_pct'] as num?)?.toInt() ?? 0,
      );

  String get formattedCompletion => '$completionPct%';
}

// ─────────────────────────────────────────────────────────
// HEADER (sections ① + ②)
// ─────────────────────────────────────────────────────────

class ChallengeStats {
  final int daysLeft;
  final int enrolledCount;
  final double completionPct;
  final int completionsToday;
  final int activeUsersToday;

  const ChallengeStats({
    required this.daysLeft,
    required this.enrolledCount,
    required this.completionPct,
    required this.completionsToday,
    required this.activeUsersToday,
  });

  factory ChallengeStats.fromJson(Map<String, dynamic> j) => ChallengeStats(
    daysLeft: (j['days_left'] as num?)?.toInt() ?? 0,
    enrolledCount: (j['enrolled_count'] as num?)?.toInt() ?? 0,
    completionPct: (j['completion_pct'] as num?)?.toDouble() ?? 0.0,
    completionsToday: (j['completions_today'] as num?)?.toInt() ?? 0,
    activeUsersToday: (j['active_users_today'] as num?)?.toInt() ?? 0,
  );

  String get formattedEnrolled {
    if (enrolledCount >= 1000)
      return '${(enrolledCount / 1000).toStringAsFixed(1)}K';
    return enrolledCount.toString();
  }

  String get formattedCompletion => '${completionPct.round()}%';
}

class MyEnrollment {
  final String status;
  final DateTime enrolledAt;

  const MyEnrollment({required this.status, required this.enrolledAt});

  factory MyEnrollment.fromJson(Map<String, dynamic> j) => MyEnrollment(
    status: j['status'] as String,
    enrolledAt: DateTime.parse(j['enrolled_at'] as String),
  );

  bool get isActive => status == 'active';
}

class ChallengeHeaderModel {
  final String id;
  final String title;
  final int durationDays;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final String? bannerUrl;
  final BrandModel brand;
  final HabitModel habit;
  final ChallengeStats stats;
  final MyEnrollment? myEnrollment;
  final int? daysLeft;
  final UserChallengeStats? myStats;
  final HeroConfig? heroConfig;
  final List<MilestoneModel> milestones;
  final String rewardPoolText;
  final List<TextSegment> titleSegments;
  final List<TextSegment> descriptionSegments;
  final String? challengeDescription;

  const ChallengeHeaderModel({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    this.bannerUrl,
    required this.brand,
    required this.habit,
    required this.stats,
    this.myEnrollment,
    this.daysLeft,
    this.myStats,
    this.heroConfig,
    required this.milestones,
    required this.rewardPoolText,
    required this.titleSegments,
    required this.descriptionSegments,
    this.challengeDescription,
  });

  /// Handles two response shapes:
  ///   1. **Header RPC**: `brand`, `habit`, `stats` as nested objects
  ///   2. **Discovery RPC**: `brands` (Supabase join), `enrolled_count` top-level, no `habit`/`stats`
  factory ChallengeHeaderModel.fromJson(Map<String, dynamic> j) {
    // ── Brand: header RPC uses 'brand', discovery uses 'brands' ──
    final rawBrand = j['brand'] ?? j['brands'];
    final brand =
        rawBrand != null
            ? BrandModel.fromJson(Map<String, dynamic>.from(rawBrand as Map))
            : BrandModel(id: '', name: 'Brand', isVerified: false);

    // ── Habit: may be absent in discovery response ──
    final rawHabit = j['habit'] ?? j['habits'];
    final habit =
        rawHabit != null
            ? HabitModel.fromJson(Map<String, dynamic>.from(rawHabit as Map))
            : HabitModel(
              id: '',
              name: 'Daily Challenge',
              scheduledDays: [1, 2, 3, 4, 5, 6, 7],
            );

    // ── Stats: may be absent — build from top-level fields if needed ──
    final rawStats = j['stats'];
    final stats =
        rawStats != null
            ? ChallengeStats.fromJson(
              Map<String, dynamic>.from(rawStats as Map),
            )
            : ChallengeStats(
              daysLeft: (j['days_left'] as num?)?.toInt() ?? 0,
              enrolledCount: (j['enrolled_count'] as num?)?.toInt() ?? 0,
              completionPct: (j['completion_pct'] as num?)?.toDouble() ?? 0.0,
              completionsToday: (j['completions_today'] as num?)?.toInt() ?? 0,
              activeUsersToday: (j['active_users_today'] as num?)?.toInt() ?? 0,
            );

    // ── Enrollment ──
    final rawEnroll = j['my_enrollment'] ?? j['myEnrollment'];
    MyEnrollment? myEnrollment;
    if (rawEnroll != null) {
      myEnrollment = MyEnrollment.fromJson(
        Map<String, dynamic>.from(rawEnroll as Map),
      );
    } else {
      final hasEnrollmentFlag =
          j['is_enrolled'] == true ||
          j['already_enrolled'] == true ||
          j['enrolled'] == true;
      final memberStatus = (j['member_status'] as String?)?.toLowerCase();
      if (hasEnrollmentFlag && memberStatus != 'left') {
        final enrolledAtRaw = j['enrolled_at'] as String?;
        final enrolledAt =
            enrolledAtRaw != null
                ? DateTime.tryParse(enrolledAtRaw)
                : null;
        myEnrollment = MyEnrollment(
          status: 'active',
          enrolledAt: enrolledAt ?? DateTime.now(),
        );
      }
    }

    // ── Days Left (for active challenges) ──
    final daysLeft = (j['days_left'] as num?)?.toInt();

    // ── My Stats (for past challenges) ──
    final rawMyStats = j['my_stats'];
    final myStats =
        rawMyStats != null
            ? UserChallengeStats.fromJson(
              Map<String, dynamic>.from(rawMyStats as Map),
            )
            : null;

    // ── Hero Config (for title highlighting) ──
    final rawHeroConfig = j['hero_config'];
    final heroConfig =
        rawHeroConfig != null
            ? HeroConfig.fromJson(
              Map<String, dynamic>.from(rawHeroConfig as Map),
            )
            : null;

    // ── Milestones (NEW) ──
    final milestones =
        (j['milestones'] as List? ?? [])
            .map(
              (m) =>
                  MilestoneModel.fromJson(Map<String, dynamic>.from(m as Map)),
            )
            .toList();

    // ── Reward Pool Text (NEW) ──
    final rewardPoolText = j['reward_pool_text'] as String? ?? '';

    // ── Segments (Title + Description) ──
    final titleSegments =
        (j['title_segments'] as List<dynamic>? ?? [])
            .map(
              (e) => TextSegment.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();

    final descriptionSegments =
        (j['description_segments'] as List<dynamic>? ?? [])
            .map(
              (e) => TextSegment.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();

    final challengeDescription = j['description'] as String?;

    return ChallengeHeaderModel(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      durationDays: (j['duration_days'] as num?)?.toInt() ?? 30,
      startsAt:
          j['starts_at'] != null
              ? DateTime.parse(j['starts_at'] as String)
              : DateTime.now(),
      endsAt:
          j['ends_at'] != null
              ? DateTime.parse(j['ends_at'] as String)
              : DateTime.now().add(const Duration(days: 30)),
      isActive: j['is_active'] as bool? ?? true,
      bannerUrl: j['banner_url'] as String?,
      brand: brand,
      habit: habit,
      stats: stats,
      myEnrollment: myEnrollment,
      daysLeft: daysLeft,
      myStats: myStats,
      heroConfig: heroConfig,
      milestones: milestones,
      rewardPoolText: rewardPoolText,
      titleSegments: titleSegments,
      descriptionSegments: descriptionSegments,
      challengeDescription: challengeDescription,
    );
  }

  bool get isEnrolled => myEnrollment != null;
  bool get isExpired => DateTime.now().isAfter(endsAt);
  String get formattedEnrolledCount => stats.formattedEnrolled;
  String get daysLeftLabel => daysLeft != null ? '$daysLeft days left' : '';
}

typedef BrandChallengeModel =
    ChallengeHeaderModel; // For backward compatibility with existing UI

// ─────────────────────────────────────────────────────────
// DISCOVERY (Clean Feed Model)
// ─────────────────────────────────────────────────────────

class DiscoveryFeaturedReward {
  final String title;
  final String rewardType;
  final String milestoneLabel;
  final String? imageUrl;

  const DiscoveryFeaturedReward({
    required this.title,
    required this.rewardType,
    required this.milestoneLabel,
    this.imageUrl,
  });

  factory DiscoveryFeaturedReward.fromJson(Map<String, dynamic> json) {
    return DiscoveryFeaturedReward(
      title: json['title'] as String? ?? 'Reward',
      rewardType: json['reward_type'] as String? ?? 'coupon',
      milestoneLabel: json['milestone_label'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }
}

class TextSegment {
  final String text;
  final bool highlight;

  const TextSegment({required this.text, required this.highlight});

  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      text: json['text']?.toString() ?? '',
      highlight: json['highlight'] == true,
    );
  }
}

class DiscoveryChallengeModel {
  final String id;
  final String title;
  final String? bannerUrl;
  final List<TextSegment> titleSegments;
  final int durationDays;
  final DateTime endsAt;
  final int enrolledCount;
  final bool isActive;
  final String rewardPoolText;
  final List<String> tags;
  final BrandModel brand;
  final List<TextSegment> descriptionSegments;
  final List<DiscoveryFeaturedReward> featuredRewards;

  const DiscoveryChallengeModel({
    required this.id,
    required this.title,
    this.bannerUrl,
    required this.titleSegments,
    required this.durationDays,
    required this.endsAt,
    required this.enrolledCount,
    required this.isActive,
    required this.rewardPoolText,
    required this.tags,
    required this.brand,
    required this.descriptionSegments,
    required this.featuredRewards,
  });

  factory DiscoveryChallengeModel.fromJson(Map<String, dynamic> j) {
    // ── Brand ──
    final rawBrand = j['brand'];
    final brand =
        rawBrand != null
            ? BrandModel.fromJson(Map<String, dynamic>.from(rawBrand as Map))
            : BrandModel(id: '', name: 'Brand', isVerified: false);

    // ── Featured Rewards ──
    final rewardsList =
        (j['featured_rewards'] as List? ?? [])
            .map(
              (m) => DiscoveryFeaturedReward.fromJson(
                Map<String, dynamic>.from(m as Map),
              ),
            )
            .toList();

    // ── Tags ──
    final tagsList =
        (j['tags'] as List? ?? []).map((t) => t.toString()).toList();

    // ── Title Segments ──
    final titleSegmentsList =
        (j['title_segments'] as List<dynamic>? ?? [])
            .map(
              (e) => TextSegment.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();

    // ── Description Segments ──
    final descriptionSegments =
        (j['description_segments'] as List<dynamic>? ?? [])
            .map(
              (e) => TextSegment.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();

    return DiscoveryChallengeModel(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      bannerUrl: j['banner_url'] as String?,
      titleSegments: titleSegmentsList,
      descriptionSegments: descriptionSegments,
      durationDays: (j['duration_days'] as num?)?.toInt() ?? 30,
      endsAt:
          j['ends_at'] != null
              ? DateTime.tryParse(j['ends_at'] as String) ?? DateTime.now()
              : DateTime.now().add(const Duration(days: 30)),
      enrolledCount: (j['enrolled_count'] as num?)?.toInt() ?? 0,
      isActive: j['is_active'] as bool? ?? true,
      rewardPoolText: j['reward_pool_text'] as String? ?? '',
      tags: tagsList,
      brand: brand,
      featuredRewards: rewardsList,
    );
  }

  bool get isExpired => DateTime.now().isAfter(endsAt);
  String get formattedEnrolledCount =>
      enrolledCount > 999
          ? '${(enrolledCount / 1000).toStringAsFixed(1)}K'
          : enrolledCount.toString();
}

// ─────────────────────────────────────────────────────────
// PULSE (section ③)
// ─────────────────────────────────────────────────────────

class PulseReactions {
  final int fire;
  final int flex;
  final int heart;

  const PulseReactions({
    required this.fire,
    required this.flex,
    required this.heart,
  });

  factory PulseReactions.fromJson(Map<String, dynamic> j) => PulseReactions(
    fire: (j['fire'] as num?)?.toInt() ?? 0,
    flex: (j['flex'] as num?)?.toInt() ?? 0,
    heart: (j['heart'] as num?)?.toInt() ?? 0,
  );
}

class PulsePostModel {
  final String id;
  final String? mediaUrl;
  final String mediaType;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? caption;
  final DateTime postDate;
  final String? productUrl;
  final PulseReactions reactions;
  final String? myReaction;

  const PulsePostModel({
    required this.id,
    this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
    this.durationSeconds,
    this.caption,
    required this.postDate,
    this.productUrl,
    required this.reactions,
    this.myReaction,
  });

  factory PulsePostModel.fromJson(Map<String, dynamic> j) => PulsePostModel(
    id: j['id'] as String,
    mediaUrl: j['media_url'] as String?,
    mediaType: j['media_type'] as String? ?? 'image',
    thumbnailUrl: j['thumbnail_url'] as String?,
    durationSeconds: (j['duration_seconds'] as num?)?.toInt(),
    caption: j['caption'] as String?,
    postDate:
        j['post_date'] != null
            ? DateTime.parse(j['post_date'] as String)
            : DateTime.now(),
    productUrl: j['product_url'] as String?,
    reactions:
        j['reactions'] is Map
            ? PulseReactions.fromJson(
              Map<String, dynamic>.from(j['reactions'] as Map),
            )
            : const PulseReactions(fire: 0, flex: 0, heart: 0),
    myReaction: j['my_reaction'] as String?,
  );

  bool get hasReacted => myReaction != null;
  bool get reactedFire => myReaction == 'fire';
  bool get reactedFlex => myReaction == 'flex';
  bool get reactedHeart => myReaction == 'heart';
  bool get isVideo => mediaType == 'video';
  bool get isReel => mediaType == 'reel';
}

// ─────────────────────────────────────────────────────────
// STORIES (challenge context — get_challenge_stories)
// ─────────────────────────────────────────────────────────

class ChallengeStorySnap {
  final String id;
  final String storagePath;
  final String storageBucket;
  final String? caption;
  final String snapDate;
  final int dayNumber;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isMine;
  final bool iViewed;
  final int viewCount;
  final Map<String, int> reactions;
  final String? myReaction;

  const ChallengeStorySnap({
    required this.id,
    required this.storagePath,
    required this.storageBucket,
    this.caption,
    required this.snapDate,
    required this.dayNumber,
    required this.createdAt,
    required this.expiresAt,
    required this.isMine,
    required this.iViewed,
    required this.viewCount,
    required this.reactions,
    this.myReaction,
  });

  factory ChallengeStorySnap.fromJson(Map<String, dynamic> j) {
    final rawReactions =
        j['reactions'] is Map
            ? Map<String, dynamic>.from(j['reactions'] as Map)
            : <String, dynamic>{};
    final reactions = rawReactions.map(
      (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
    );

    return ChallengeStorySnap(
      id: j['id'] as String,
      storagePath: j['storage_path'] as String,
      storageBucket: j['storage_bucket'] as String? ?? 'brand-snaps',
      caption: j['caption'] as String?,
      snapDate: j['snap_date'] as String? ?? '',
      dayNumber: (j['day_number'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(j['created_at'] as String),
      expiresAt: DateTime.parse(j['expires_at'] as String),
      isMine: j['is_mine'] as bool? ?? false,
      iViewed: j['i_viewed'] as bool? ?? false,
      viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
      reactions: reactions,
      myReaction: j['my_reaction'] as String?,
    );
  }

  bool get hasReacted => myReaction != null;
}

class ChallengeStorySender {
  final String id;
  final String displayName;
  final String? avatarId;
  final String? avatarKey;
  final String? photoId;
  final String? photoKey;

  const ChallengeStorySender({
    required this.id,
    required this.displayName,
    this.avatarId,
    this.avatarKey,
    this.photoId,
    this.photoKey,
  });

  factory ChallengeStorySender.fromJson(Map<String, dynamic> j) =>
      ChallengeStorySender(
        id: j['id'] as String,
        displayName: j['display_name'] as String? ?? 'User',
        avatarId: j['avatar_id'] as String?,
        avatarKey: j['avatar_key'] as String?,
        photoId: j['photo_id'] as String?,
        photoKey: j['photo_key'] as String?,
      );
}

class ChallengeStory {
  final String senderId;
  final String senderName;
  final String? avatarId;
  final String? avatarKey;
  final String? photoId;
  final String? photoKey;
  final int snapCount;
  final int unseenCount;
  final bool hasUnseen;
  final DateTime latestSnapAt;
  final bool isMine;
  final String? previewStoragePath;
  final String storageBucket;
  final ChallengeStorySender sender;
  const ChallengeStory({
    required this.senderId,
    required this.senderName,
    this.avatarId,
    this.avatarKey,
    this.photoId,
    this.photoKey,
    required this.snapCount,
    required this.unseenCount,
    required this.hasUnseen,
    required this.latestSnapAt,
    required this.isMine,
    this.previewStoragePath,
    this.storageBucket = 'brand-snaps',
    required this.sender,
  });

  factory ChallengeStory.fromJson(Map<String, dynamic> j) {
    final rawSender =
        j['sender'] is Map
            ? ChallengeStorySender.fromJson(
              Map<String, dynamic>.from(j['sender'] as Map),
            )
            : ChallengeStorySender(
              id: j['sender_id'] as String? ?? '',
              displayName: j['sender_name'] as String? ?? 'User',
            );

    return ChallengeStory(
      senderId: (j['sender_id'] as String?) ?? rawSender.id,
      senderName: (j['sender_name'] as String?) ?? rawSender.displayName,
      avatarId: (j['avatar_id'] as String?) ?? rawSender.avatarId,
      avatarKey: (j['avatar_key'] as String?) ?? rawSender.avatarKey,
      photoId: (j['photo_id'] as String?) ?? rawSender.photoId,
      photoKey: (j['photo_key'] as String?) ?? rawSender.photoKey,
      snapCount: (j['snap_count'] as num?)?.toInt() ?? 0,
      unseenCount: (j['unseen_count'] as num?)?.toInt() ?? 0,
      hasUnseen: j['has_unseen'] as bool? ?? false,
      latestSnapAt:
          j['latest_snap_at'] != null
              ? DateTime.parse(j['latest_snap_at'] as String)
              : DateTime.now(),
      isMine: j['is_mine'] as bool? ?? false,
      previewStoragePath: j['preview_storage_path'] as String?,
      storageBucket: j['storage_bucket'] as String? ?? 'brand-snaps',
      sender: rawSender,
    );
  }
}

class ChallengeStoriesResponse {
  final bool success;

  /// Total senders with stories (from pagination metadata)
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool postedToday;
  final List<ChallengeStory> stories;

  const ChallengeStoriesResponse({
    required this.success,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.postedToday,
    required this.stories,
  });

  /// Legacy compat: old call-sites using totalStories
  int get totalStories => total;

  factory ChallengeStoriesResponse.fromJson(Map<String, dynamic> j) =>
      ChallengeStoriesResponse(
        success: j['success'] as bool? ?? true,
        total: (j['total'] as num?)?.toInt() ?? 0,
        page: (j['page'] as num?)?.toInt() ?? 1,
        limit: (j['limit'] as num?)?.toInt() ?? 10,
        hasMore: j['has_more'] as bool? ?? false,
        postedToday: j['posted_today'] as bool? ?? false,
        stories:
            (j['stories'] as List? ?? [])
                .map(
                  (e) => ChallengeStory.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList(),
      );

  /// Appends stories from [next] page (for scroll-right tray pagination)
  ChallengeStoriesResponse appendPage(ChallengeStoriesResponse next) {
    return ChallengeStoriesResponse(
      success: next.success,
      total: next.total,
      page: next.page,
      limit: next.limit,
      hasMore: next.hasMore,
      postedToday: next.postedToday,
      stories: [...stories, ...next.stories],
    );
  }

  bool get isEmpty => stories.isEmpty;
  bool get isNotEmpty => stories.isNotEmpty;

  static const empty = ChallengeStoriesResponse(
    success: true,
    total: 0,
    page: 1,
    limit: 10,
    hasMore: false,
    postedToday: false,
    stories: [],
  );
}

// ─────────────────────────────────────────────────────────
// SENDER SNAPS (get_challenge_story_snaps)
// Fetched when user taps a story ring — contains all snaps
// for that one sender, oldest→newest (auto-advance order).
// ─────────────────────────────────────────────────────────

class ChallengeSenderSnapsResponse {
  final bool success;
  final String senderId;
  final int count;
  final List<ChallengeStorySnap> snaps;

  const ChallengeSenderSnapsResponse({
    required this.success,
    required this.senderId,
    required this.count,
    required this.snaps,
  });

  factory ChallengeSenderSnapsResponse.fromJson(Map<String, dynamic> j) =>
      ChallengeSenderSnapsResponse(
        success: j['success'] as bool? ?? true,
        senderId: j['sender_id'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
        snaps:
            (j['snaps'] as List? ?? [])
                .map(
                  (e) => ChallengeStorySnap.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList(),
      );

  bool get isEmpty => snaps.isEmpty;
  bool get isNotEmpty => snaps.isNotEmpty;
}

// ─────────────────────────────────────────────────────────
// SNAPS + PAGINATION (section ④)
// ─────────────────────────────────────────────────────────

class SnapSender {
  final String id;
  final String displayName;
  final String? avatarId;
  final String? avatarKey;
  final String? photoId;
  final String? photoKey;

  const SnapSender({
    required this.id,
    required this.displayName,
    this.avatarId,
    this.avatarKey,
    this.photoId,
    this.photoKey,
  });

  factory SnapSender.fromJson(Map<String, dynamic> j) => SnapSender(
    id: (j['id'] ?? j['sender_id'] ?? '').toString(),
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

class SnapModel {
  final String id;
  final String storagePath;
  final String? caption;
  final DateTime snapDate;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int fireCount;
  final int flexCount;
  final int heartCount;
  final String? myReaction;
  final bool isMine;
  final int dayNumber;
  final SnapSender sender;
  String? signedUrl; // filled after storage fetch

  SnapModel({
    required this.id,
    required this.storagePath,
    this.caption,
    required this.snapDate,
    required this.createdAt,
    required this.expiresAt,
    required this.fireCount,
    required this.flexCount,
    required this.heartCount,
    this.myReaction,
    required this.isMine,
    required this.dayNumber,
    required this.sender,
    this.signedUrl,
  });

  factory SnapModel.fromJson(Map<String, dynamic> j) {
    // Parse reactions — may be a nested map or flat columns
    final reactions =
        j['reactions'] is Map
            ? Map<String, dynamic>.from(j['reactions'] as Map)
            : <String, dynamic>{};

    final senderMap =
        j['sender'] is Map
            ? Map<String, dynamic>.from(j['sender'] as Map)
            : <String, dynamic>{
              'id': j['sender_id'],
              'display_name': j['sender_name'] ?? j['display_name'],
              'avatar_id': j['sender_avatar_id'] ?? j['avatar_id'],
              'avatar_key': j['sender_avatar_key'] ?? j['avatar_key'],
              'photo_id': j['sender_photo_id'] ?? j['photo_id'],
              'photo_key': j['sender_photo_key'] ?? j['photo_key'],
            };

    return SnapModel(
      id: j['id'] as String,
      storagePath: j['storage_path'] as String,
      caption: j['caption'] as String?,
      snapDate: DateTime.parse(j['snap_date'] as String),
      createdAt: DateTime.parse(j['created_at'] as String),
      expiresAt: DateTime.parse(j['expires_at'] as String),
      isMine: j['is_mine'] as bool? ?? false,
      dayNumber: (j['day_number'] as num?)?.toInt() ?? 0,
      sender: SnapSender.fromJson(senderMap),
      fireCount:
          (reactions['fire'] as num?)?.toInt() ??
          (j['fire_count'] as num?)?.toInt() ??
          0,
      flexCount:
          (reactions['flex'] as num?)?.toInt() ??
          (j['flex_count'] as num?)?.toInt() ??
          0,
      heartCount:
          (reactions['heart'] as num?)?.toInt() ??
          (j['heart_count'] as num?)?.toInt() ??
          0,
      myReaction: j['my_reaction'] as String?,
    );
  }

  bool get hasReacted => myReaction != null;
  bool get reactedFire => myReaction == 'fire';
  bool get reactedFlex => myReaction == 'flex';
  bool get reactedHeart => myReaction == 'heart';
}

class SnapPageResult {
  final List<SnapModel> snaps;
  final bool hasMore;
  final String? nextCursor; // ISO timestamp — pass back on next load
  final bool postedToday;
  final int totalToday;
  final int? snapsToday; // NEW: snaps sent today
  final int? snapsRemaining; // NEW: snaps remaining in daily limit

  const SnapPageResult({
    required this.snaps,
    required this.hasMore,
    this.nextCursor,
    required this.postedToday,
    required this.totalToday,
    this.snapsToday,
    this.snapsRemaining,
  });

  factory SnapPageResult.fromJson(Map<String, dynamic> j) => SnapPageResult(
    snaps:
        (j['snaps'] as List? ?? [])
            .map((e) => SnapModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
    hasMore: j['has_more'] as bool? ?? false,
    nextCursor: j['next_cursor'] as String?,
    postedToday: j['posted_today'] as bool? ?? false,
    totalToday: (j['total_today'] as num?)?.toInt() ?? 0,
    snapsToday: (j['snaps_today'] as num?)?.toInt(),
    snapsRemaining: (j['snaps_remaining'] as num?)?.toInt(),
  );
}

// ─────────────────────────────────────────────────────────
// PRODUCTS (section ⑤)
// ─────────────────────────────────────────────────────────

class BrandProductModel {
  final String id;
  final String name;
  final String? imageUrl;
  final double originalPrice;
  final double challengePrice;
  final bool isExclusive;
  final String? storeUrl;
  final int sortOrder;
  final int? stockCount;
  final int redeemedCount;
  final bool isActive;
  final int? stockRemaining;
  final bool inStock;
  final int discountPct;

  const BrandProductModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.originalPrice,
    required this.challengePrice,
    required this.isExclusive,
    this.storeUrl,
    required this.sortOrder,
    this.stockCount,
    required this.redeemedCount,
    required this.isActive,
    this.stockRemaining,
    required this.inStock,
    required this.discountPct,
  });

  factory BrandProductModel.fromJson(Map<String, dynamic> j) =>
      BrandProductModel(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        imageUrl: j['image_url'] as String?,
        originalPrice: (j['original_price'] as num?)?.toDouble() ?? 0.0,
        challengePrice: (j['challenge_price'] as num?)?.toDouble() ?? 0.0,
        isExclusive: j['is_exclusive'] as bool? ?? false,
        storeUrl: j['store_url'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        stockCount: (j['stock_count'] as num?)?.toInt(),
        redeemedCount: (j['redeemed_count'] as num?)?.toInt() ?? 0,
        isActive: j['is_active'] as bool? ?? true,
        stockRemaining: (j['stock_remaining'] as num?)?.toInt(),
        inStock: j['in_stock'] as bool? ?? true,
        discountPct: (j['discount_pct'] as num?)?.toInt() ?? 0,
      );

  String get formattedPrice => '₹${challengePrice.toInt()}';
  String get formattedOriginal => '₹${originalPrice.toInt()}';
  String get discountLabel => '-$discountPct%';
  String get stockLabel {
    if (!inStock) return 'Sold Out';
    if (stockRemaining == null) return 'In Stock';
    return '$stockRemaining left';
  }
}

// ─────────────────────────────────────────────────────────
// JOURNEY — MILESTONES + CREW + ENERGY (sections ⑥ ⑦ ⑧)
// ─────────────────────────────────────────────────────────

class MilestoneReward {
  final String id;
  final String title;
  final String rewardType;
  final String? imageUrl;
  final int? couponValidityDays;
  final DateTime? couponExpiresAt;
  final bool isPhysical;
  final bool earned;

  const MilestoneReward({
    required this.id,
    required this.title,
    required this.rewardType,
    this.imageUrl,
    this.couponValidityDays,
    this.couponExpiresAt,
    required this.isPhysical,
    required this.earned,
  });

  factory MilestoneReward.fromJson(Map<String, dynamic> j) => MilestoneReward(
    id: (j['id'] ?? '').toString(),
    title: (j['title'] ?? 'Reward').toString(),
    rewardType: (j['reward_type'] ?? 'coupon').toString(),
    imageUrl: j['image_url'] as String?,
    couponValidityDays: (j['coupon_validity_days'] as num?)?.toInt(),
    couponExpiresAt: DateTime.tryParse(j['coupon_expires_at']?.toString() ?? ''),
    isPhysical: j['is_physical'] as bool? ?? false,
    earned: j['earned'] as bool? ?? false,
  );
}

enum MilestoneState { done, active, locked }

class MilestoneModel {
  final String id;
  final int dayTarget;
  final String label;
  final String? iconUrl;
  final int sortOrder;
  final MilestoneState state;
  final int daysAway;
  final List<MilestoneReward> rewards;

  const MilestoneModel({
    required this.id,
    required this.dayTarget,
    required this.label,
    this.iconUrl,
    required this.sortOrder,
    required this.state,
    required this.daysAway,
    required this.rewards,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> j) => MilestoneModel(
    id: (j['id'] ?? '').toString(),
    dayTarget: (j['day_target'] as num?)?.toInt() ?? 0,
    label: (j['label'] ?? 'Milestone').toString(),
    iconUrl: j['icon_url'] as String?,
    sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
    daysAway: (j['days_away'] as num?)?.toInt() ?? 0,
    state: switch (j['state'] as String? ?? 'locked') {
      'done' => MilestoneState.done,
      'active' => MilestoneState.active,
      _ => MilestoneState.locked,
    },
    rewards:
        (j['rewards'] as List? ?? [])
            .map(
              (e) =>
                  MilestoneReward.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
  );

  bool get isDone => state == MilestoneState.done;
  bool get isActive => state == MilestoneState.active;
  bool get isLocked => state == MilestoneState.locked;

  String get sublabel {
    if (isDone) return 'Unlocked';
    if (daysAway == 0) return '1 day away';
    return '$daysAway days away';
  }
}

class ChallengeProgress {
  final int currentStreak;
  final int totalLogs;
  final int userDay;
  final int durationDays;
  final bool doneToday;
  final String? lastCompleted;
  final int progressPct;

  const ChallengeProgress({
    required this.currentStreak,
    required this.totalLogs,
    required this.userDay,
    required this.durationDays,
    required this.doneToday,
    this.lastCompleted,
    required this.progressPct,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> j) =>
      ChallengeProgress(
        currentStreak: (j['current_streak'] as num?)?.toInt() ?? 0,
        totalLogs: (j['total_logs'] as num?)?.toInt() ?? 0,
        userDay: (j['user_day'] as num?)?.toInt() ?? 0,
        durationDays: (j['duration_days'] as num?)?.toInt() ?? 30,
        doneToday: j['done_today'] as bool? ?? false,
        lastCompleted: j['last_completed'] as String?,
        progressPct: (j['progress_pct'] as num?)?.toInt() ?? 0,
      );

  String get dayLabel => 'Day $userDay of $durationDays';
  double get progressFraction => (progressPct / 100.0).clamp(0.0, 1.0);
  String get markDoneLabel => 'Mark Day $userDay Done';
}

class ChallengeEnergy {
  final int completionsToday;
  final int activeUsersToday;
  final int enrolledCount;

  const ChallengeEnergy({
    required this.completionsToday,
    required this.activeUsersToday,
    required this.enrolledCount,
  });

  factory ChallengeEnergy.fromJson(Map<String, dynamic> j) => ChallengeEnergy(
    completionsToday: (j['completions_today'] as num?)?.toInt() ?? 0,
    activeUsersToday: (j['active_users_today'] as num?)?.toInt() ?? 0,
    enrolledCount: (j['enrolled_count'] as num?)?.toInt() ?? 0,
  );

  double get fraction =>
      enrolledCount > 0
          ? (completionsToday / enrolledCount).clamp(0.0, 1.0)
          : 0.0;
  String get label => '$completionsToday / $enrolledCount';
}

class ChallengeJourneyModel {
  final ChallengeProgress progress;
  final List<MilestoneModel> milestones;
  final ChallengeEnergy energy;

  const ChallengeJourneyModel({
    required this.progress,
    required this.milestones,
    required this.energy,
  });

  factory ChallengeJourneyModel.fromJson(Map<String, dynamic> j) =>
      ChallengeJourneyModel(
        progress: ChallengeProgress.fromJson(
          Map<String, dynamic>.from(j['progress'] as Map),
        ),
        milestones:
            (j['milestones'] as List? ?? [])
                .map(
                  (e) => MilestoneModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList(),
        energy: ChallengeEnergy.fromJson(
          Map<String, dynamic>.from(j['energy'] as Map),
        ),
      );
}

// ─────────────────────────────────────────────────────────
// COUPONS (section ⑧ Earned Rewards)
// ─────────────────────────────────────────────────────────

class CouponRewardData {
  final String title;
  final String rewardType;
  final String? imageUrl;
  final bool isPhysical;

  const CouponRewardData({
    required this.title,
    required this.rewardType,
    this.imageUrl,
    required this.isPhysical,
  });

  factory CouponRewardData.fromJson(Map<String, dynamic> j) => CouponRewardData(
    title: j['title'] as String? ?? 'Reward',
    rewardType: j['reward_type'] as String? ?? 'coupon',
    imageUrl: j['image_url'] as String?,
    isPhysical: j['is_physical'] as bool? ?? false,
  );
}

class CouponBrandData {
  final String name;
  final String? logoUrl;

  const CouponBrandData({required this.name, this.logoUrl});

  factory CouponBrandData.fromJson(Map<String, dynamic> j) => CouponBrandData(
    name: j['name'] as String? ?? 'Brand',
    logoUrl: j['logo_url'] as String?,
  );
}

class ChallengeCouponModel {
  final String id;
  final String? code;
  final bool isUsed;
  final bool isExpired;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final DateTime? assignedAt;
  final String? discountType;
  final double? discountValue;
  final double? minOrderAmount;
  final double? maxDiscountAmt;
  final String? description;
  final String? deepLink;
  final DateTime earnedAt;
  final CouponRewardData reward;
  final CouponBrandData brand;

  const ChallengeCouponModel({
    required this.id,
    this.code,
    required this.isUsed,
    required this.isExpired,
    this.expiresAt,
    this.usedAt,
    this.assignedAt,
    this.discountType,
    this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmt,
    this.description,
    this.deepLink,
    required this.earnedAt,
    required this.reward,
    required this.brand,
  });

  factory ChallengeCouponModel.fromJson(Map<String, dynamic> j) =>
      ChallengeCouponModel(
        id: (j['id'] ?? j['coupon_id'] ?? '').toString(),
        code: j['code']?.toString() ?? j['coupon_code']?.toString(),
        isUsed: j['is_used'] as bool? ?? false,
        isExpired: j['is_expired'] as bool? ?? false,
        expiresAt: DateTime.tryParse(
          j['expires_at']?.toString() ?? j['coupon_expires_at']?.toString() ?? '',
        ),
        usedAt: DateTime.tryParse(j['used_at']?.toString() ?? ''),
        assignedAt: DateTime.tryParse(j['assigned_at']?.toString() ?? ''),
        discountType: j['discount_type']?.toString(),
        discountValue: (j['discount_value'] as num?)?.toDouble(),
        minOrderAmount: (j['min_order_amount'] as num?)?.toDouble(),
        maxDiscountAmt: (j['max_discount_amt'] as num?)?.toDouble(),
        description: j['description']?.toString(),
        deepLink: j['deep_link']?.toString(),
        earnedAt:
            DateTime.tryParse(j['earned_at']?.toString() ?? '') ?? DateTime.now(),
        reward: CouponRewardData.fromJson(
          Map<String, dynamic>.from(j['reward'] as Map? ?? {}),
        ),
        brand: CouponBrandData.fromJson(
          Map<String, dynamic>.from(j['brand'] as Map? ?? {}),
        ),
      );
}

// ─────────────────────────────────────────────────────────
// REWARDS SCREEN MODELS
// ─────────────────────────────────────────────────────────

class ChallengeRewardsModel {
  final String challengeId;
  final String brandName;
  final String challengeTitle;
  final String? bannerUrl;
  final String? logoUrl;
  final BrandThemeData theme;
  final List<MilestoneModel> milestones;
  final int currentProgressDays;
  final int durationDays;

  const ChallengeRewardsModel({
    required this.challengeId,
    required this.brandName,
    required this.challengeTitle,
    this.bannerUrl,
    this.logoUrl,
    required this.theme,
    required this.milestones,
    required this.currentProgressDays,
    required this.durationDays,
  });

  factory ChallengeRewardsModel.fromJson(Map<String, dynamic> j) {
    final themeJson = j['brand_theme'] is Map
        ? Map<String, dynamic>.from(j['brand_theme'] as Map)
        : null;

    return ChallengeRewardsModel(
      challengeId: j['challenge_id'] as String? ?? j['id'] as String? ?? '',
      brandName: j['brand_name'] as String? ?? '',
      challengeTitle: j['challenge_title'] as String? ?? j['title'] as String? ?? '',
      bannerUrl: j['banner_url'] as String?,
      logoUrl: j['logo_url'] as String?,
      theme: BrandThemeData.fromJson(themeJson ?? {}),
      milestones: (j['milestones'] as List? ?? [])
          .map((e) => MilestoneModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentProgressDays: (j['current_progress_days'] as num?)?.toInt() ?? 0,
      durationDays: (j['duration_days'] as num?)?.toInt() ?? 30,
    );
  }

  double get progressFraction => durationDays > 0
      ? (currentProgressDays / durationDays).clamp(0.0, 1.0)
      : 0.0;

  int get earnedCount => milestones.where((m) => m.isDone).length;
  int get totalMilestones => milestones.length;
}

class UserRewardsListModel {
  final List<ChallengeRewardsModel> challenges;

  const UserRewardsListModel({required this.challenges});

  factory UserRewardsListModel.fromJson(List<dynamic> data) {
    return UserRewardsListModel(
      challenges: data
          .map((e) => ChallengeRewardsModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  int get totalChallenges => challenges.length;
  int get totalEarnedRewards =>
      challenges.fold(0, (sum, c) => sum + c.earnedCount);
}
