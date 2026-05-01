import 'package:equatable/equatable.dart';
import '../../../models/user_model.dart';
import '../../../models/profile_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final bool needsOnboarding;
  final ProfileModel? profile;
  final String? avatarUrl; // Cache the avatar URL here!
  final String? photoUrl;  // Cache the photo URL here!

  const AuthAuthenticated(
    this.user, {
    this.needsOnboarding = false,
    this.profile,
    this.avatarUrl,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [user, needsOnboarding, profile, avatarUrl, photoUrl];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
