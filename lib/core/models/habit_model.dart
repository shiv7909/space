class HabitModel {
  final String id;
  final String name;
  final String? whyReason;
  final String emoji;
  final String mode;
  final int? targetDays;
  final List<int> scheduledDays;
  final String? spaceId;
  final bool isArchived;
  final DateTime createdAt;

  const HabitModel({
    required this.id,
    required this.name,
    this.whyReason,
    required this.emoji,
    required this.mode,
    this.targetDays,
    required this.scheduledDays,
    this.spaceId,
    this.isArchived = false,
    required this.createdAt,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      whyReason: json['why_reason'] as String?,
      emoji: json['emoji'] as String? ?? '🔥',
      mode: json['mode'] as String? ?? 'infinite',
      targetDays: json['target_days'] as int?,
      scheduledDays:
          (json['scheduled_days'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
      spaceId: json['space_id'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
