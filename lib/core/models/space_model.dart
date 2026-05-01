import 'package:equatable/equatable.dart';

class SpaceModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final String? inviteCode;
  final String createdBy;
  final bool isPremiumSpace;
  final DateTime createdAt;
  final SpaceStats stats;

  const SpaceModel({
    required this.id,
    required this.name,
    required this.type,
    this.inviteCode,
    required this.createdBy,
    required this.isPremiumSpace,
    required this.createdAt,
    this.stats = const SpaceStats(),
  });

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      inviteCode: json['invite_code'] as String?,
      createdBy: json['created_by'] as String,
      isPremiumSpace: json['is_premium_space'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      stats:
          json['stats'] != null
              ? SpaceStats.fromJson(json['stats'])
              : const SpaceStats(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'is_premium_space': isPremiumSpace,
      'created_at': createdAt.toIso8601String(),
      'stats': stats.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, name, type, inviteCode, stats];
}

class SpaceStats {
  final int totalHabits;
  final int activeStreak;
  final int membersCount;
  final int completionRate;

  const SpaceStats({
    this.totalHabits = 0,
    this.activeStreak = 0,
    this.membersCount = 1,
    this.completionRate = 0,
  });

  factory SpaceStats.fromJson(Map<String, dynamic> json) {
    return SpaceStats(
      totalHabits: json['total_habits'] ?? 0,
      activeStreak: json['active_streak'] ?? 0,
      membersCount: json['members_count'] ?? 1,
      completionRate: json['completion_rate'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_habits': totalHabits,
    'active_streak': activeStreak,
    'members_count': membersCount,
    'completion_rate': completionRate,
  };
}
