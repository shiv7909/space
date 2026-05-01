import 'package:equatable/equatable.dart';
import '../../../models/profile_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;
  final String? avatarUrl;
  final String? photoUrl;

  const ProfileLoaded({required this.profile, this.avatarUrl, this.photoUrl});

  @override
  List<Object?> get props => [profile, avatarUrl, photoUrl];

  /// The display URL — photo takes priority over avatar
  String? get displayUrl => photoUrl ?? avatarUrl;

  /// Whether the displayed image is a real photo upload
  bool get isShowingPhoto => profile.hasPhoto && photoUrl != null;

  ProfileLoaded copyWith({ProfileModel? profile, String? avatarUrl, String? photoUrl, bool clearPhoto = false}) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    );
  }
}

class ProfileUpdating extends ProfileState {}

class ProfilePhotoUploading extends ProfileState {
  final ProfileModel profile;
  final String? avatarUrl;
  final String? photoUrl;

  const ProfilePhotoUploading({required this.profile, this.avatarUrl, this.photoUrl});

  @override
  List<Object?> get props => [profile, avatarUrl, photoUrl];
}

class ProfileUpdated extends ProfileState {
  final ProfileModel profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}
