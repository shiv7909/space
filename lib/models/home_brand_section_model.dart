import 'brand_theme_data.dart';

class HomeBrandSectionModel {
  final HomeBrandCardModel? card;
  final int snapLimit;

  const HomeBrandSectionModel({
    required this.card,
    required this.snapLimit,
  });

  factory HomeBrandSectionModel.fromJson(Map<String, dynamic> json) {
    final enrolledCard = _parseCard(json['enrolled']);
    final discoverCard = _parseCard(json['discover']);
    return HomeBrandSectionModel(
      // New API returns only `card`. Keep fallback for older payloads.
      card: _parseCard(json['card']) ?? enrolledCard ?? discoverCard,
      snapLimit: (json['snap_limit'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasAnyCard => card != null;

  static HomeBrandCardModel? _parseCard(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map.isEmpty) return null;
    return HomeBrandCardModel.fromJson(map);
  }
}

class HomeBrandCardStats {
  final int activeToday;
  final int totalEnrolled;

  const HomeBrandCardStats({
    required this.activeToday,
    required this.totalEnrolled,
  });

  factory HomeBrandCardStats.fromJson(Map<String, dynamic> json) {
    return HomeBrandCardStats(
      activeToday: (json['active_today'] as num?)?.toInt() ?? 0,
      totalEnrolled: (json['total_enrolled'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeBrandMilestoneReward {
  final String title;
  final String rewardType;
  final String? imageUrl;
  final bool isPhysical;

  const HomeBrandMilestoneReward({
    required this.title,
    required this.rewardType,
    required this.imageUrl,
    required this.isPhysical,
  });

  factory HomeBrandMilestoneReward.fromJson(Map<String, dynamic> json) {
    return HomeBrandMilestoneReward(
      title: (json['title'] ?? '').toString(),
      rewardType: (json['reward_type'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      isPhysical: json['is_physical'] == true,
    );
  }
}

class HomeBrandNextMilestone {
  final int dayTarget;
  final String label;
  final String? iconUrl;
  final int daysToUnlock;
  final HomeBrandMilestoneReward? reward;

  const HomeBrandNextMilestone({
    required this.dayTarget,
    required this.label,
    required this.iconUrl,
    required this.daysToUnlock,
    required this.reward,
  });

  factory HomeBrandNextMilestone.fromJson(Map<String, dynamic> json) {
    return HomeBrandNextMilestone(
      dayTarget: (json['day_target'] as num?)?.toInt() ?? 0,
      label: (json['label'] ?? '').toString(),
      iconUrl: json['icon_url']?.toString(),
      daysToUnlock: (json['days_to_unlock'] as num?)?.toInt() ?? 0,
      reward: json['reward'] != null ? HomeBrandMilestoneReward.fromJson(json['reward']) : null,
    );
  }
}

class HomeBrandEarnedReward {
  final String title;
  final String rewardType;
  final String? imageUrl;
  final DateTime? earnedAt;
  final String status;

  const HomeBrandEarnedReward({
    required this.title,
    required this.rewardType,
    required this.imageUrl,
    required this.earnedAt,
    required this.status,
  });

  factory HomeBrandEarnedReward.fromJson(Map<String, dynamic> json) {
    return HomeBrandEarnedReward(
      title: (json['title'] ?? '').toString(),
      rewardType: (json['reward_type'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      earnedAt: json['earned_at'] != null ? DateTime.tryParse(json['earned_at'].toString()) : null,
      status: (json['status'] ?? 'pending').toString(),
    );
  }
}

class HomeBrandCardModel {
  final String cardType;
  final String challengeId;
  final String brandName;
  final String challengeTitle;
  final String rewardPoolText;
  final String? bannerUrl;
  final String? logoUrl;
  final bool isVerified;
  final int currentStreak;
  final int snapsToday;
  final int snapsRemainingToday;
  final int daysLeft;
  final String? matchReason;
  final HomeBrandCardStats stats;
  final BrandThemeData theme;
  final int daysCompleted;
  final HomeBrandNextMilestone? nextMilestone;
  final List<HomeBrandEarnedReward> earnedRewards;
  // Home card returns a count only; detail screen returns the full list.
  final int earnedRewardsCount;

  const HomeBrandCardModel({
    required this.cardType,
    required this.challengeId,
    required this.brandName,
    required this.challengeTitle,
    required this.rewardPoolText,
    required this.bannerUrl,
    required this.logoUrl,
    required this.isVerified,
    required this.currentStreak,
    required this.snapsToday,
    required this.snapsRemainingToday,
    required this.daysLeft,
    required this.matchReason,
    required this.stats,
    required this.theme,
    this.daysCompleted = 0,
    this.nextMilestone,
    this.earnedRewards = const [],
    this.earnedRewardsCount = 0,
  });

  factory HomeBrandCardModel.fromJson(Map<String, dynamic> json) {
    final brand =
        json['brand'] is Map
            ? Map<String, dynamic>.from(json['brand'] as Map)
            : const <String, dynamic>{};

    final statsJson =
        json['stats'] is Map
            ? Map<String, dynamic>.from(json['stats'] as Map)
            : const <String, dynamic>{};

    final themeJson =
        json['brand_theme'] is Map
            ? Map<String, dynamic>.from(json['brand_theme'] as Map)
            : brand['brand_theme'] is Map
            ? Map<String, dynamic>.from(brand['brand_theme'] as Map)
            : null;

    return HomeBrandCardModel(
      cardType: (json['card_type'] ?? '').toString(),
      challengeId:
          (json['challenge_id'] ?? json['id'] ?? '').toString(),
      brandName:
          (json['brand_name'] ?? brand['name'] ?? '').toString(),
      challengeTitle:
          (json['challenge_title'] ?? json['title'] ?? '').toString(),
      rewardPoolText: (json['reward_pool_text'] ?? '').toString(),
      bannerUrl: (json['banner_url'] ?? brand['banner_url'])?.toString(),
      logoUrl: (json['logo_url'] ?? brand['logo_url'])?.toString(),
      isVerified:
          (json['is_verified'] ?? brand['is_verified']) == true,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      snapsToday: (json['snaps_today'] as num?)?.toInt() ?? 0,
      snapsRemainingToday:
          (json['snaps_remaining_today'] as num?)?.toInt() ?? 0,
      daysLeft: (json['days_left'] as num?)?.toInt() ?? 0,
      matchReason: json['match_reason']?.toString(),
      stats: HomeBrandCardStats.fromJson(statsJson),
      theme: BrandThemeData.fromJson(themeJson),
      daysCompleted: (json['days_completed'] as num?)?.toInt() ?? 0,
      nextMilestone: json['next_milestone'] != null
          ? HomeBrandNextMilestone.fromJson(
              Map<String, dynamic>.from(json['next_milestone'] as Map))
          : null,
      earnedRewards: (json['earned_rewards'] as List?)
              ?.map((e) => HomeBrandEarnedReward.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      // Prefer explicit count field; fall back to length of full list if present.
      earnedRewardsCount:
          (json['earned_rewards_count'] as num?)?.toInt() ??
          ((json['earned_rewards'] as List?)?.length ?? 0),
    );
  }

  bool get isActiveCard => cardType.toLowerCase() == 'active';
}
