class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromSupabaseUser(dynamic user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['full_name'],
      avatarUrl: user.userMetadata?['avatar_url'],
      createdAt:
          user.createdAt is String
              ? DateTime.parse(user.createdAt)
              : user.createdAt as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_metadata': {'full_name': displayName, 'avatar_url': avatarUrl},
      'created_at': createdAt.toIso8601String(),
    };
  }
}
