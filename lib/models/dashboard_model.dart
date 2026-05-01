/// Safely coerce any JSON value → bool.
/// Handles native bool, int (0/1), and String ("true"/"false"/"1"/"0").
bool _parseBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return fallback;
}

enum DashboardAlertType {
  breakStreak, // "break"
  warning,
  nudge,
  milestone,
  completion,
  recovery, // Added for elastic save scenarios
}

enum DashboardSpaceType { solo, couple, group }

enum DashboardStreakStatus {
  active,
  broken,
  frozen,
  inactive, // Added for habits that haven't started yet
}

/// Represents a single member in a group habit.
class GroupMember {
  final String userId;
  final String displayName;
  final String? avatarId;
  final String? photoKey; // real profile photo — takes priority over avatarId
  final int currentStreak;
  final int bestStreak;
  final int totalLogs;
  final String streakStatus;
  final DateTime? lastDone;
  final bool doneToday;
  final List<DateTime> calendar;
  final int rank;
  final bool isMe;


  const GroupMember({
    required this.userId,
    required this.displayName,
    this.avatarId,
    this.photoKey,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalLogs = 0,
    this.streakStatus = 'inactive',
    this.lastDone,
    this.doneToday = false,
    this.calendar = const [],
    this.rank = 0,
    this.isMe = false,

  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    List<DateTime> cal = [];
    if (json['calendar'] != null) {
      cal =
          (json['calendar'] as List)
              .map((e) => DateTime.parse(e.toString()))
              .toList();
    }
    return GroupMember(
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarId: json['avatar_id'],
      photoKey: json['photo_key'] as String?,
      currentStreak: json['current_streak'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      totalLogs: json['total_logs'] ?? 0,
      streakStatus: json['streak_status'] ?? 'inactive',
      lastDone:
          json['last_done'] != null
              ? DateTime.tryParse(json['last_done'].toString())
              : null,
      doneToday: _parseBool(json['done_today']),
      calendar: cal,
      rank: json['rank'] ?? 0,
      isMe: _parseBool(json['is_me']),

    );
  }
}

/// Represents a leaderboard entry in a group habit.
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarId;
  final String? photoKey; // real profile photo — takes priority over avatarId
  final int currentStreak;
  final bool isMe;


  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarId,
    this.photoKey,
    this.currentStreak = 0,
    this.isMe = false,

  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarId: json['avatar_id'],
      photoKey: json['photo_key'] as String?,
      currentStreak: json['current_streak'] ?? 0,
      isMe: _parseBool(json['is_me']),

    );
  }
}

class DashboardAlert {
  final String id;
  final DashboardAlertType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;

  DashboardAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    DashboardAlertType type;
    switch (json['type']) {
      case 'break':
        type = DashboardAlertType.breakStreak;
        break;
      case 'warning':
        type = DashboardAlertType.warning;
        break;
      case 'nudge':
        type = DashboardAlertType.nudge;
        break;
      case 'milestone':
        type = DashboardAlertType.milestone;
        break;
      case 'completion':
        type = DashboardAlertType.completion;
        break;
      case 'recovery':
        type = DashboardAlertType.recovery;
        break;
      default:
        type = DashboardAlertType.nudge;
    }

    return DashboardAlert(
      id: json['id'] ?? DateTime.now().toString(),
      type: type,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class DashboardHabit {
  final String id;
  final String name;
  final String emoji;
  final DashboardSpaceType spaceType;
  final int currentStreak;
  final int bestStreak;
  final DashboardStreakStatus streakStatus;
  final bool isDoneToday;
  final int doneCount;
  final int totalMembers;
  final String? whyReason;
  final List<DateTime> myCalendar;
  final Map<String, dynamic>? habitHeader;
  final List<int> scheduledDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? mode;
  final bool isScheduledToday;
  final DateTime? lastCompletedAt;
  final DateTime? createdAt;
  final int? targetDays;

  // ── Couple-specific fields ──
  final String? partnerId;
  final String? partnerAvatarKey; // preset avatar storage key
  final String? partnerPhotoId; // UUID → profile_photos table
  final String? partnerPhotoKey; // real profile photo storage key
  final int partnerCurrentStreak;
  final int partnerBestStreak;
  final int partnerTotalLogs;
  final DashboardStreakStatus partnerStreakStatus;
  final bool partnerDoneToday;
  final DateTime? partnerLastDone;
  final List<DateTime> partnerCalendar;
  final List<Map<String, dynamic>> combinedCalendar;
  final int groupStreak;

  // ── Challenge fields (me) ──
  final int? daysRemaining;
  final int? myDaysCompleted;
  final int? myDaysMissed;
  final int? myLogsNeeded;
  final double? myCompletionPct;

  // ── Challenge fields (partner) ──
  final int? partnerDaysCompleted;
  final int? partnerDaysMissed;
  final int? partnerLogsNeeded;
  final double? partnerCompletionPct;
  final bool? canStillComplete;

  // ── Group habit fields ──
  final List<GroupMember> members;
  final List<LeaderboardEntry> leaderboard;
  final int doneTodayCount;
  final int streakThreshold;
  final int myRank;
  final String? myDisplayName;
  final String? myAvatarId;
  final String? myAvatarKey; // preset avatar storage key (group)
  final String? myPhotoKey; // real profile photo storage key (group)
  final String? creatorId;

  DashboardHabit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.spaceType,
    required this.currentStreak,
    this.bestStreak = 0,
    required this.streakStatus,
    this.isDoneToday = false,
    this.doneCount = 0,
    this.totalMembers = 1,
    this.whyReason,
    this.myCalendar = const [],
    this.habitHeader,
    this.scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
    this.startDate,
    this.endDate,
    this.mode,
    this.isScheduledToday = false,
    this.lastCompletedAt,
    this.createdAt,
    this.targetDays,
    // Couple-specific
    this.partnerId,
    this.partnerAvatarKey,
    this.partnerPhotoId,
    this.partnerPhotoKey,
    this.partnerCurrentStreak = 0,
    this.partnerBestStreak = 0,
    this.partnerTotalLogs = 0,
    this.partnerStreakStatus = DashboardStreakStatus.inactive,
    this.partnerDoneToday = false,
    this.partnerLastDone,
    this.partnerCalendar = const [],
    this.combinedCalendar = const [],
    this.groupStreak = 0,
    // Challenge fields (me)
    this.daysRemaining,
    this.myDaysCompleted,
    this.myDaysMissed,
    this.myLogsNeeded,
    this.myCompletionPct,
    // Challenge fields (partner)
    this.partnerDaysCompleted,
    this.partnerDaysMissed,
    this.partnerLogsNeeded,
    this.partnerCompletionPct,
    this.canStillComplete,
    // Group habit fields
    this.members = const [],
    this.leaderboard = const [],
    this.doneTodayCount = 0,
    this.streakThreshold = 0,
    this.myRank = 0,
    this.myDisplayName,
    this.myAvatarId,
    this.myAvatarKey,
    this.myPhotoKey,
    this.creatorId,
  });

  DashboardHabit copyWith({
    String? id,
    String? name,
    String? emoji,
    DashboardSpaceType? spaceType,
    int? currentStreak,
    int? bestStreak,
    DashboardStreakStatus? streakStatus,
    bool? isDoneToday,
    int? doneCount,
    int? totalMembers,
    String? whyReason,
    List<DateTime>? myCalendar,
    Map<String, dynamic>? habitHeader,
    List<int>? scheduledDays,
    DateTime? startDate,
    DateTime? endDate,
    String? mode,
    bool? isScheduledToday,
    DateTime? lastCompletedAt,
    DateTime? createdAt,
    int? targetDays,
    // Couple-specific
    String? partnerId,
    String? partnerAvatarKey,
    String? partnerPhotoId,
    String? partnerPhotoKey,
    int? partnerCurrentStreak,
    int? partnerBestStreak,
    int? partnerTotalLogs,
    DashboardStreakStatus? partnerStreakStatus,
    bool? partnerDoneToday,
    DateTime? partnerLastDone,
    List<DateTime>? partnerCalendar,
    List<Map<String, dynamic>>? combinedCalendar,
    int? groupStreak,
    // Challenge fields (me)
    int? daysRemaining,
    int? myDaysCompleted,
    int? myDaysMissed,
    int? myLogsNeeded,
    double? myCompletionPct,
    // Challenge fields (partner)
    int? partnerDaysCompleted,
    int? partnerDaysMissed,
    int? partnerLogsNeeded,
    double? partnerCompletionPct,
    bool? canStillComplete,
    // Group habit fields
    List<GroupMember>? members,
    List<LeaderboardEntry>? leaderboard,
    int? doneTodayCount,
    int? streakThreshold,
    int? myRank,
    String? myDisplayName,
    String? myAvatarId,
    String? myAvatarKey,
    String? myPhotoKey,
    String? creatorId,
  }) {
    return DashboardHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      spaceType: spaceType ?? this.spaceType,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      streakStatus: streakStatus ?? this.streakStatus,
      isDoneToday: isDoneToday ?? this.isDoneToday,
      doneCount: doneCount ?? this.doneCount,
      totalMembers: totalMembers ?? this.totalMembers,
      whyReason: whyReason ?? this.whyReason,
      myCalendar: myCalendar ?? this.myCalendar,
      habitHeader: habitHeader ?? this.habitHeader,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mode: mode ?? this.mode,
      isScheduledToday: isScheduledToday ?? this.isScheduledToday,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      createdAt: createdAt ?? this.createdAt,
      targetDays: targetDays ?? this.targetDays,
      partnerId: partnerId ?? this.partnerId,
      partnerAvatarKey: partnerAvatarKey ?? this.partnerAvatarKey,
      partnerPhotoId: partnerPhotoId ?? this.partnerPhotoId,
      partnerPhotoKey: partnerPhotoKey ?? this.partnerPhotoKey,
      partnerCurrentStreak: partnerCurrentStreak ?? this.partnerCurrentStreak,
      partnerBestStreak: partnerBestStreak ?? this.partnerBestStreak,
      partnerTotalLogs: partnerTotalLogs ?? this.partnerTotalLogs,
      partnerStreakStatus: partnerStreakStatus ?? this.partnerStreakStatus,
      partnerDoneToday: partnerDoneToday ?? this.partnerDoneToday,
      partnerLastDone: partnerLastDone ?? this.partnerLastDone,
      partnerCalendar: partnerCalendar ?? this.partnerCalendar,
      combinedCalendar: combinedCalendar ?? this.combinedCalendar,
      groupStreak: groupStreak ?? this.groupStreak,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      myDaysCompleted: myDaysCompleted ?? this.myDaysCompleted,
      myDaysMissed: myDaysMissed ?? this.myDaysMissed,
      myLogsNeeded: myLogsNeeded ?? this.myLogsNeeded,
      myCompletionPct: myCompletionPct ?? this.myCompletionPct,
      partnerDaysCompleted: partnerDaysCompleted ?? this.partnerDaysCompleted,
      partnerDaysMissed: partnerDaysMissed ?? this.partnerDaysMissed,
      partnerLogsNeeded: partnerLogsNeeded ?? this.partnerLogsNeeded,
      partnerCompletionPct: partnerCompletionPct ?? this.partnerCompletionPct,
      canStillComplete: canStillComplete ?? this.canStillComplete,
      members: members ?? this.members,
      leaderboard: leaderboard ?? this.leaderboard,
      doneTodayCount: doneTodayCount ?? this.doneTodayCount,
      streakThreshold: streakThreshold ?? this.streakThreshold,
      myRank: myRank ?? this.myRank,
      myDisplayName: myDisplayName ?? this.myDisplayName,
      myAvatarId: myAvatarId ?? this.myAvatarId,
      myAvatarKey: myAvatarKey ?? this.myAvatarKey,
      myPhotoKey: myPhotoKey ?? this.myPhotoKey,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  factory DashboardHabit.fromJson(Map<String, dynamic> json) {
    DashboardSpaceType spaceType;
    switch (json['space_type'] ?? json['spaceType']) {
      case 'couple':
        spaceType = DashboardSpaceType.couple;
        break;
      case 'group':
        spaceType = DashboardSpaceType.group;
        break;
      default:
        spaceType = DashboardSpaceType.solo;
    }

    DashboardStreakStatus streakStatus;
    final status =
        json['my_streak_status'] ??
        json['streak_status'] ??
        json['streakStatus'] ??
        'active';
    if (status == 'broken') {
      streakStatus = DashboardStreakStatus.broken;
    } else if (status == 'frozen') {
      streakStatus = DashboardStreakStatus.frozen;
    } else if (status == 'inactive') {
      streakStatus = DashboardStreakStatus.inactive;
    } else {
      streakStatus = DashboardStreakStatus.active;
    }

    // Parse partner streak status
    DashboardStreakStatus partnerStreakStatus;
    final pStatus = json['partner_streak_status'] ?? 'inactive';
    if (pStatus == 'broken') {
      partnerStreakStatus = DashboardStreakStatus.broken;
    } else if (pStatus == 'frozen') {
      partnerStreakStatus = DashboardStreakStatus.frozen;
    } else if (pStatus == 'inactive' || pStatus == 'no_partner') {
      partnerStreakStatus = DashboardStreakStatus.inactive;
    } else {
      partnerStreakStatus = DashboardStreakStatus.active;
    }

    // Parse my calendar
    List<DateTime> calendar = [];
    if (json['my_calendar'] != null) {
      calendar =
          (json['my_calendar'] as List)
              .map((e) => DateTime.parse(e.toString()))
              .toList();
    } else if (json['myCalendar'] != null) {
      calendar =
          (json['myCalendar'] as List)
              .map((e) => DateTime.parse(e.toString()))
              .toList();
    }

    // Parse partner calendar
    List<DateTime> partnerCalendar = [];
    if (json['partner_calendar'] != null) {
      partnerCalendar =
          (json['partner_calendar'] as List)
              .map((e) => DateTime.parse(e.toString()))
              .toList();
    }

    // Parse combined calendar
    List<Map<String, dynamic>> combinedCalendar = [];
    if (json['combined_calendar'] != null) {
      combinedCalendar =
          (json['combined_calendar'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    }

    // Parse members
    List<GroupMember> members = [];
    if (json['members'] != null) {
      members =
          (json['members'] as List)
              .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
              .toList();
    }

    // Parse leaderboard
    List<LeaderboardEntry> leaderboard = [];
    if (json['leaderboard'] != null) {
      leaderboard =
          (json['leaderboard'] as List)
              .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList();
      // ── Recompute ranks client-side using dense ranking ──
      // Sort by currentStreak descending, then by displayName for stable order
      leaderboard.sort((a, b) {
        final cmp = b.currentStreak.compareTo(a.currentStreak);
        return cmp != 0 ? cmp : a.displayName.compareTo(b.displayName);
      });
      for (int i = 0; i < leaderboard.length; i++) {
        int rank = i + 1;
        leaderboard[i] = LeaderboardEntry(
          rank: rank,
          userId: leaderboard[i].userId,
          displayName: leaderboard[i].displayName,
          avatarId: leaderboard[i].avatarId,
          photoKey: leaderboard[i].photoKey,
          currentStreak: leaderboard[i].currentStreak,
          isMe: leaderboard[i].isMe,

        );
      }
    }

    // ── Determine current user's userId from every available hint ──
    // Priority: leaderboard isMe entry → json['my_user_id'] → members is_me field
    String? myUserId = json['my_user_id'] as String?;
    if (myUserId == null) {
      final meLeader = leaderboard.where((e) => e.isMe).firstOrNull;
      if (meLeader != null) myUserId = meLeader.userId;
    }

    // ── Re-flag members with isMe using the resolved userId ──
    if (myUserId != null && members.isNotEmpty) {
      members =
          members.map((m) {
            final flag = m.userId == myUserId || m.isMe;
            if (flag == m.isMe) return m;
            return GroupMember(
              userId: m.userId,
              displayName: m.displayName,
              avatarId: m.avatarId,
              photoKey: m.photoKey,
              currentStreak: m.currentStreak,
              bestStreak: m.bestStreak,
              totalLogs: m.totalLogs,
              streakStatus: m.streakStatus,
              lastDone: m.lastDone,
              doneToday: m.doneToday,
              calendar: m.calendar,
              rank: m.rank,
              isMe: flag,

            );
          }).toList();
    }

    // ── Recompute myRank from the fixed leaderboard ──
    final rawMyRank = json['my_rank'] ?? 0;
    int computedMyRank = rawMyRank is int ? rawMyRank : 0;
    if (leaderboard.isNotEmpty) {
      final meEntry = leaderboard.where((e) => e.isMe).firstOrNull;
      if (meEntry != null) {
        computedMyRank = meEntry.rank;
      }
    }

    return DashboardHabit(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'] ?? '🔥',
      spaceType: spaceType,
      currentStreak:
          json['my_current_streak'] ??
          json['current_streak'] ??
          json['currentStreak'] ??
          0,
      bestStreak:
          json['my_best_streak'] ??
          json['best_streak'] ??
          json['bestStreak'] ??
          0,
      streakStatus: streakStatus,
      isDoneToday: _parseBool(
        json['my_done_today'] ??
            json['is_done_today'] ??
            json['completedToday'],
      ),
      doneCount:
          json['my_total_logs'] ?? json['done_count'] ?? json['doneCount'] ?? 0,
      totalMembers: json['total_members'] ?? json['totalMembers'] ?? 1,
      whyReason: json['why_reason'] ?? json['whyReason'],
      myCalendar: calendar,
      habitHeader: json['habit_header'],
      scheduledDays:
          (json['scheduled_days'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
      startDate:
          json['start_date'] != null
              ? DateTime.parse(json['start_date'])
              : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      mode: json['mode'],
      isScheduledToday: _parseBool(json['is_scheduled_today']),
      lastCompletedAt: () {
        final raw = json['my_last_done'] ?? json['last_completed_at'];
        return raw != null ? DateTime.tryParse(raw.toString()) : null;
      }(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      targetDays: json['target_days'] ?? json['targetDays'],
      // Couple-specific
      partnerId: json['partner_id'],
      partnerAvatarKey: json['partner_avatar_key'],
      partnerPhotoId: json['partner_photo_id'],
      partnerPhotoKey: json['partner_photo_key'],
      partnerCurrentStreak: json['partner_current_streak'] ?? 0,
      partnerBestStreak: json['partner_best_streak'] ?? 0,
      partnerTotalLogs: json['partner_total_logs'] ?? 0,
      partnerStreakStatus: partnerStreakStatus,
      partnerDoneToday: _parseBool(json['partner_done_today']),
      partnerLastDone:
          json['partner_last_done'] != null
              ? DateTime.tryParse(json['partner_last_done'].toString())
              : null,
      partnerCalendar: partnerCalendar,
      combinedCalendar: combinedCalendar,
      groupStreak: json['group_streak'] ?? 0,
      // Challenge fields (me)
      daysRemaining: json['days_remaining'],
      myDaysCompleted: json['my_days_completed'],
      myDaysMissed: json['my_days_missed'],
      myLogsNeeded: json['my_logs_needed'],
      myCompletionPct:
          json['my_completion_pct'] != null
              ? (json['my_completion_pct'] as num).toDouble()
              : null,
      // Challenge fields (partner)
      partnerDaysCompleted: json['partner_days_completed'],
      partnerDaysMissed: json['partner_days_missed'],
      partnerLogsNeeded: json['partner_logs_needed'],
      partnerCompletionPct:
          json['partner_completion_pct'] != null
              ? (json['partner_completion_pct'] as num).toDouble()
              : null,
      canStillComplete:
          json['can_still_complete'] != null
              ? _parseBool(json['can_still_complete'])
              : null,
      // Group habit fields
      members: members,
      leaderboard: leaderboard,
      doneTodayCount: json['done_today_count'] ?? 0,
      streakThreshold: json['streak_threshold'] ?? 0,
      myRank: computedMyRank,
      myDisplayName: json['my_display_name'],
      myAvatarId: json['my_avatar_id'],
      myAvatarKey: json['my_avatar_key'] as String?,
      myPhotoKey: json['my_photo_key'] as String?,
    );
  }
}

/// Sticky Header for top-of-screen persistent messages
class StickyHeader {
  final String message;
  final String type; // 'milestone', 'warning', 'nudge', 'break'

  StickyHeader({required this.message, required this.type});

  factory StickyHeader.fromJson(Map<String, dynamic> json) {
    return StickyHeader(
      message: json['message'] ?? '',
      type: json['type'] ?? 'nudge',
    );
  }
}

/// Represents a challenge that has ended and is awaiting user dismissal.
class EndedHabit {
  final String id;
  final String name;
  final String emoji;
  final String spaceType; // 'solo' | 'couple' | 'group'
  final String challengeStatus; // 'completed' | 'failed'

  // ── Solo / "my" stats (used by all three space types) ──
  final int daysCompleted;
  final int daysMissed;
  final double completionPct;
  final int bestStreak;

  // ── Couple-only partner stats ──
  final String? partnerId;
  final int? partnerDaysCompleted;
  final double? partnerCompletionPct;

  final DateTime? startDate;
  final DateTime? endDate;

  EndedHabit({
    required this.id,
    required this.name,
    required this.emoji,
    this.spaceType = 'solo',
    required this.challengeStatus,
    required this.daysCompleted,
    required this.daysMissed,
    required this.completionPct,
    required this.bestStreak,
    this.partnerId,
    this.partnerDaysCompleted,
    this.partnerCompletionPct,
    this.startDate,
    this.endDate,
  });

  bool get isCompleted => challengeStatus == 'completed';
  bool get isCouple => spaceType == 'couple';
  bool get isGroup => spaceType == 'group';

  factory EndedHabit.fromJson(Map<String, dynamic> json) {
    final type = json['space_type'] as String? ?? 'solo';

    // For couple/group the API returns my_* prefixed keys.
    // For solo it returns flat keys. Support both.
    int _int(String myKey, String flatKey) =>
        (json[myKey] ?? json[flatKey] ?? 0) as int;
    double _dbl(String myKey, String flatKey) {
      final v = json[myKey] ?? json[flatKey];
      return v != null ? (v as num).toDouble() : 0.0;
    }

    return EndedHabit(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Habit',
      emoji: json['emoji'] as String? ?? '🏁',
      spaceType: type,
      challengeStatus: json['challenge_status'] as String? ?? 'failed',
      daysCompleted: _int('my_days_completed', 'days_completed'),
      daysMissed: _int('my_days_missed', 'days_missed'),
      completionPct: _dbl('my_completion_pct', 'completion_pct'),
      bestStreak: _int('my_best_streak', 'best_streak'),
      // Couple-only
      partnerId: json['partner_id'] as String?,
      partnerDaysCompleted: json['partner_days_completed'] as int?,
      partnerCompletionPct:
          json['partner_completion_pct'] != null
              ? (json['partner_completion_pct'] as num).toDouble()
              : null,
      startDate:
          json['start_date'] != null
              ? DateTime.tryParse(json['start_date'].toString())
              : null,
      endDate:
          json['end_date'] != null
              ? DateTime.tryParse(json['end_date'].toString())
              : null,
    );
  }
}

class DashboardData {
  final List<DashboardAlert> alerts;
  final List<DashboardHabit> habits;
  final List<EndedHabit> endedHabits;
  final StickyHeader? stickyHeader;
  final String? status;
  final String? statusMessage;

  DashboardData({
    this.alerts = const [],
    this.habits = const [],
    this.endedHabits = const [],
    this.stickyHeader,
    this.status,
    this.statusMessage,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final alertsList =
        (json['alerts'] as List?)
            ?.map((a) => DashboardAlert.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final habitsList =
        (json['habits'] as List?)
            ?.map((h) => DashboardHabit.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [];

    final endedHabitsList =
        (json['ended_habits'] as List?)
            ?.map((h) => EndedHabit.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [];

    StickyHeader? header;
    if (json['sticky_header'] != null) {
      header = StickyHeader.fromJson(
        json['sticky_header'] as Map<String, dynamic>,
      );
    }

    return DashboardData(
      alerts: alertsList,
      habits: habitsList,
      endedHabits: endedHabitsList,
      stickyHeader: header,
      status: json['status'] as String?,
      statusMessage: json['status_message'] as String?,
    );
  }

  // ✅ NEW: copyWith method for efficient state updates
  DashboardData copyWith({
    List<DashboardAlert>? alerts,
    List<DashboardHabit>? habits,
    List<EndedHabit>? endedHabits,
    StickyHeader? stickyHeader,
    String? status,
    String? statusMessage,
  }) {
    return DashboardData(
      alerts: alerts ?? this.alerts,
      habits: habits ?? this.habits,
      endedHabits: endedHabits ?? this.endedHabits,
      stickyHeader: stickyHeader ?? this.stickyHeader,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
