import 'package:equatable/equatable.dart';

class InviteModel extends Equatable {
  final String inviteId;
  final String spaceId;
  final String spaceName;
  final String spaceType;
  final String invitedById;
  final String invitedByName;
  final String? invitedByAvatar;
  final String? invitedByAvatarKey;   // preset avatar storage key
  final String? invitedByPhotoId;     // UUID → profile_photos table
  final String? invitedByPhotoKey;    // real profile photo storage key
  final DateTime createdAt;

  const InviteModel({
    required this.inviteId,
    required this.spaceId,
    required this.spaceName,
    required this.spaceType,
    required this.invitedById,
    required this.invitedByName,
    this.invitedByAvatar,
    this.invitedByAvatarKey,
    this.invitedByPhotoId,
    this.invitedByPhotoKey,
    required this.createdAt,
  });

  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      inviteId: json['invite_id'] as String,
      spaceId: json['space_id'] as String,
      spaceName: json['space_name'] as String? ?? 'Unknown Space',
      spaceType: json['space_type'] as String? ?? 'couple',
      invitedById: json['invited_by_id'] as String,
      invitedByName: json['invited_by_name'] as String? ?? 'Someone',
      invitedByAvatar: json['invited_by_avatar'] as String?,
      invitedByAvatarKey: json['invited_by_avatar_key'] as String?,
      invitedByPhotoId: json['invited_by_photo_id'] as String?,
      invitedByPhotoKey: json['invited_by_photo_key'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get spaceTypeLabel {
    switch (spaceType) {
      case 'couple':
        return 'Duo';
      case 'group':
        return 'Squad';
      default:
        return spaceType;
    }
  }

  String get spaceTypeEmoji {
    switch (spaceType) {
      case 'couple':
        return '🤝';
      case 'group':
        return '👥';
      default:
        return '📦';
    }
  }

  @override
  List<Object?> get props => [inviteId, spaceId, invitedById, createdAt];
}
