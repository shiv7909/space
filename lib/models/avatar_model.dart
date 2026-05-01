class AvatarModel {
  final String id;
  final String avatarKey;
  final DateTime createdAt;

  const AvatarModel({
    required this.id,
    required this.avatarKey,
    required this.createdAt,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['id'] as String,
      avatarKey: json['avatar_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar_key': avatarKey,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
