class ProfileModel {
  final String id;
  final String? displayName;
  final String? avatarId;
  final String? photoId; // UUID → profile_photos table
  final String? photoKey; // storage path e.g. "uid/uid.jpg"
  final DateTime? premiumUntil;
  final bool isPremiumFlag;
  final String timezone;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    this.displayName,
    this.avatarId,
    this.photoId,
    this.photoKey,
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
      photoId: json['photo_id'] as String?,
      photoKey: json['photo_key'] as String?,
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
      'photo_id': photoId,
      'photo_key': photoKey,
      'premium_until': premiumUntil?.toIso8601String(),
      'is_premium': isPremiumFlag,
      'timezone': timezone,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? displayName,
    String? avatarId,
    String? photoId,
    String? photoKey,
    DateTime? premiumUntil,
    bool? isPremiumFlag,
    String? timezone,
    bool clearPhoto = false,
  }) {
    return ProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      photoId: clearPhoto ? null : (photoId ?? this.photoId),
      photoKey: clearPhoto ? null : (photoKey ?? this.photoKey),
      premiumUntil: premiumUntil ?? this.premiumUntil,
      isPremiumFlag: isPremiumFlag ?? this.isPremiumFlag,
      timezone: timezone ?? this.timezone,
      updatedAt: DateTime.now(),
    );
  }

  bool get isComplete => displayName != null && displayName!.isNotEmpty;

  /// Whether this profile has a real uploaded photo (not just a preset avatar)
  /// photoKey is now always populated via the profile_photos JOIN in getProfile
  bool get hasPhoto => photoId != null;

  /// Premium restrictions have been removed — all users are now "premium".
  /// This getter always returns true for backward compatibility.
  bool get isPremium => true;
}
