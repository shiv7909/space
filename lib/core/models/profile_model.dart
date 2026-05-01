class ProfileModel {
  final String id;
  final String? displayName;
  final String? avatarId;
  final DateTime? premiumUntil;
  final bool isPremiumFlag;
  final String timezone;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    this.displayName,
    this.avatarId,
    this.premiumUntil,
    this.isPremiumFlag = false,
    this.timezone = 'UTC',
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarId: json['avatar_id'] as String?,
      premiumUntil:
          json['premium_until'] != null
              ? DateTime.parse(json['premium_until'] as String)
              : null,
      isPremiumFlag: json['is_premium'] as bool? ?? false,
      timezone: json['timezone'] as String? ?? 'UTC',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_id': avatarId,
      'premium_until': premiumUntil?.toIso8601String(),
      'is_premium': isPremiumFlag,
      'timezone': timezone,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? displayName,
    String? avatarId,
    DateTime? premiumUntil,
    bool? isPremiumFlag,
    String? timezone,
  }) {
    return ProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      isPremiumFlag: isPremiumFlag ?? this.isPremiumFlag,
      timezone: timezone ?? this.timezone,
      updatedAt: DateTime.now(),
    );
  }

  bool get isComplete => displayName != null && displayName!.isNotEmpty;

  bool get isPremium {
    if (isPremiumFlag) return true;
    if (premiumUntil != null && premiumUntil!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }
}
