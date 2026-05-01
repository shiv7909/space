/// Model for home screen analytics pulled from get_my_full_analytics()
class HomeAnalytics {
  final int bestActiveStreak;
  final int totalCompletions;
  final int doneTodayCount;
  final int totalSpaces;
  final int totalActiveHabits;
  final double thisWeekPercentage;
  final List<HabitAnalytic> habits;
  final List<SpaceTypeAnalytic> spaceTypes;
  final List<DayCompletionCount> weeklyData;

  const HomeAnalytics({
    required this.bestActiveStreak,
    required this.totalCompletions,
    required this.doneTodayCount,
    required this.totalSpaces,
    required this.totalActiveHabits,
    required this.thisWeekPercentage,
    required this.habits,
    required this.spaceTypes,
    required this.weeklyData,
  });

  factory HomeAnalytics.fromJson(Map<String, dynamic> j) => HomeAnalytics(
    bestActiveStreak:    (j['totals']?['current_best_streak'] as num?)?.toInt() ?? 0,
    totalCompletions:    (j['totals']?['total_completions'] as num?)?.toInt() ?? 0,
    doneTodayCount:      (j['totals']?['done_today_count'] as num?)?.toInt() ?? 0,
    totalSpaces:         (j['totals']?['total_spaces'] as num?)?.toInt() ?? 0,
    totalActiveHabits:   (j['totals']?['total_active_habits'] as num?)?.toInt() ?? 0,
    thisWeekPercentage:  ((j['totals']?['this_week_percentage'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 100.0),
    habits: (j['habits'] as List? ?? [])
      .map((e) => HabitAnalytic.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
    spaceTypes: (j['space_types'] as List? ?? [])
      .map((e) => SpaceTypeAnalytic.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
    weeklyData: (j['weekly_data'] as List? ?? [])
      .map((e) => DayCompletionCount.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  );

  static const empty = HomeAnalytics(
    bestActiveStreak: 0,
    totalCompletions: 0,
    doneTodayCount: 0,
    totalSpaces: 0,
    totalActiveHabits: 0,
    thisWeekPercentage: 0.0,
    habits: [],
    spaceTypes: [],
    weeklyData: [],
  );
}

class HabitAnalytic {
  final String id;
  final String name;
  final String emoji;
  final double? consistency; // 0-100
  final int currentStreak;
  final bool doneTodayRaw;

  const HabitAnalytic({
    required this.id,
    required this.name,
    required this.emoji,
    this.consistency,
    required this.currentStreak,
    required this.doneTodayRaw,
  });

  factory HabitAnalytic.fromJson(Map<String, dynamic> j) => HabitAnalytic(
    id:           j['id'] as String? ?? '',
    name:         j['name'] as String? ?? 'Habit',
    emoji:        j['emoji'] as String? ?? '✨',
    consistency:  (j['consistency'] as num?)?.toDouble(),
    currentStreak: (j['current_streak'] as num?)?.toInt() ?? 0,
    doneTodayRaw: j['done_today'] == true || j['done_today'] == 1,
  );

  String get consistencyLabel {
    final c = consistency ?? 0;
    if (c >= 70) return 'green';
    if (c >= 40) return 'amber';
    return 'red';
  }
}

class SpaceTypeAnalytic {
  final String type; // "solo", "couple", "group"
  final double avgConsistency;

  const SpaceTypeAnalytic({
    required this.type,
    required this.avgConsistency,
  });

  factory SpaceTypeAnalytic.fromJson(Map<String, dynamic> j) => SpaceTypeAnalytic(
    type:              (j['type'] as String? ?? 'solo').toLowerCase(),
    avgConsistency:    ((j['avg_consistency'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 100.0),
  );

  String get displayLabel {
    switch (type) {
      case 'couple': return 'Couple';
      case 'group':  return 'Squad';
      default:       return 'Solo';
    }
  }

  String get displayEmoji {
    switch (type) {
      case 'couple': return '💕';
      case 'group':  return '👥';
      default:       return '✨';
    }
  }
}

class DayCompletionCount {
  final String dayOfWeek; // "Mon", "Tue", etc.
  final int completionCount;

  const DayCompletionCount({
    required this.dayOfWeek,
    required this.completionCount,
  });

  factory DayCompletionCount.fromJson(Map<String, dynamic> j) => DayCompletionCount(
    dayOfWeek:       j['day_of_week'] as String? ?? 'Mon',
    completionCount: (j['completion_count'] as num?)?.toInt() ?? 0,
  );
}

class SenderSnapsResult {
  final SnapSenderInfo sender;
  // This will be either List<SpaceSenderSnap> or List<ChallengeSenderSnap>
  final List<dynamic> snaps;

  const SenderSnapsResult({
    required this.sender,
    required this.snaps,
  });

  factory SenderSnapsResult.fromChallenge(Map<String, dynamic> j) {
    // Placeholder - will be filled when used with challenges
    return SenderSnapsResult(sender: SnapSenderInfo.empty(), snaps: []);
  }

  factory SenderSnapsResult.fromSpace(Map<String, dynamic> j) {
    // Placeholder - will be filled when used with spaces
    return SenderSnapsResult(sender: SnapSenderInfo.empty(), snaps: []);
  }
}

class SnapSenderInfo {
  final String id;
  final String displayName;

  const SnapSenderInfo({
    required this.id,
    required this.displayName,
  });

  factory SnapSenderInfo.empty() => const SnapSenderInfo(id: '', displayName: 'User');
}
