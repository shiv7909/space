import 'package:equatable/equatable.dart';
import '../../../models/avatar_model.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingNameStep extends OnboardingState {
  final String? firstName;
  final String? lastName;

  const OnboardingNameStep({this.firstName, this.lastName});

  @override
  List<Object?> get props => [firstName, lastName];
}

class OnboardingAvatarStep extends OnboardingState {
  final String firstName;
  final String lastName;
  final List<AvatarModel> avatars;
  final String? selectedAvatarId;
  /// key = avatarKey, value = signed URL ready for Image.network
  final Map<String, String> avatarUrls;

  const OnboardingAvatarStep({
    required this.firstName,
    required this.lastName,
    required this.avatars,
    this.selectedAvatarId,
    this.avatarUrls = const {},
  });

  OnboardingAvatarStep copyWith({
    String? firstName,
    String? lastName,
    List<AvatarModel>? avatars,
    String? selectedAvatarId,
    Map<String, String>? avatarUrls,
  }) {
    return OnboardingAvatarStep(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatars: avatars ?? this.avatars,
      selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
      avatarUrls: avatarUrls ?? this.avatarUrls,
    );
  }

  @override
  List<Object?> get props => [firstName, lastName, avatars, selectedAvatarId, avatarUrls];
}

class OnboardingCompleting extends OnboardingState {}

class OnboardingCompleted extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError(this.message);

  @override
  List<Object> get props => [message];
}
