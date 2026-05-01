class AvatarModel {
  final String id;
  final String avatarKey;
  final bool isPremium;
  final DateTime createdAt;

  const AvatarModel({
    required this.id,
    required this.avatarKey,
    this.isPremium = false,
    required this.createdAt,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['id'] as String,
      avatarKey: json['avatar_key'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar_key': avatarKey,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
