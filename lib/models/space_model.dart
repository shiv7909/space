import 'package:equatable/equatable.dart';
import '../core/models/space_visibility.dart';

class SpaceModel extends Equatable {
  final String id;
  final String name;
  final String type; // 'solo', 'couple', 'group'
  final String? inviteCode;
  final String createdBy;
  final bool isPremiumSpace;
  final DateTime createdAt;
  final SpaceStats stats;
  final SpaceVisibility visibility;
  final double? centroidLat;
  final double? centroidLng;
  final String? description;
  final String? categoryId;

  const SpaceModel({
    required this.id,
    required this.name,
    required this.type,
    this.inviteCode,
    required this.createdBy,
    required this.isPremiumSpace,
    required this.createdAt,
    this.stats = const SpaceStats(),
    this.visibility = SpaceVisibility.private,
    this.centroidLat,
    this.centroidLng,
    this.description,
    this.categoryId,
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
      visibility: SpaceVisibility.fromString(
          json['visibility'] as String? ?? 'private'),
      centroidLat: (json['centroid_lat'] as num?)?.toDouble(),
      centroidLng: (json['centroid_lng'] as num?)?.toDouble(),
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
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
      'visibility': visibility.value,
      'centroid_lat': centroidLat,
      'centroid_lng': centroidLng,
      'description': description,
      'category_id': categoryId,
    };
  }

  SpaceModel copyWith({
    SpaceVisibility? visibility,
    double? centroidLat,
    double? centroidLng,
    String? description,
    String? categoryId,
  }) {
    return SpaceModel(
      id: id,
      name: name,
      type: type,
      inviteCode: inviteCode,
      createdBy: createdBy,
      isPremiumSpace: isPremiumSpace,
      createdAt: createdAt,
      stats: stats,
      visibility: visibility ?? this.visibility,
      centroidLat: centroidLat ?? this.centroidLat,
      centroidLng: centroidLng ?? this.centroidLng,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  List<Object?> get props => [
        id, name, type, inviteCode, stats, visibility,
        centroidLat, centroidLng, description, categoryId,
      ];
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
