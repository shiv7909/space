import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/error_helpers.dart';
import '../../../services/profile_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService profileService;
  String userId;

  ProfileCubit({required this.profileService, required this.userId})
    : super(ProfileInitial());

  void updateUserId(String newUserId) {
    userId = newUserId;
  }

  Future<void> loadProfile() async {
    if (userId.isEmpty) return;

    emit(ProfileLoading());
    try {
      final profile = await profileService.getProfile(userId);

      if (profile == null) {
        emit(const ProfileError('Profile not found'));
        return;
      }

      // Resolve display image — photo first, avatar fallback
      String? avatarUrl;
      String? photoUrl;

      if (profile.hasPhoto && profile.photoKey != null) {
        // photoKey is always present now via the profile_photos JOIN
        try {
          photoUrl = profileService.getProfilePhotoUrl(profile.photoKey!);
        } catch (_) {
          // Fall through to avatar
        }
      }

      if (profile.avatarId != null) {
        avatarUrl = await profileService.getAvatarUrlById(profile.avatarId!);
      }

      emit(
        ProfileLoaded(
          profile: profile,
          avatarUrl: avatarUrl,
          photoUrl: photoUrl,
        ),
      );
    } catch (e) {
      emit(ProfileError(userMessage(e)));
    }
  }

  /// Sets the profile immediately (e.g. from AuthCubit) to avoid double-fetching
  Future<void> setProfile(
    dynamic profile, {
    String? avatarUrl,
    String? photoUrl,
  }) async {
    // We accept dynamic or specific type, but since we are inside the file, we can assume 'ProfileModel'
    // But wait, I need to import ProfileModel if I use it in signature, or keep it dynamic to avoid circle if distinct?
    // ProfileService returns ProfileModel.
    // Let's assume the caller passes the correct object.

    if (profile == null) return;

    // Convert to loaded state immediately
    // If avatarUrl is not passed but we have avatarId, we might want to fetch it?
    // Or just assume the caller has done the work (AuthCubit does).

    emit(
      ProfileLoaded(profile: profile, avatarUrl: avatarUrl, photoUrl: photoUrl),
    );
  }

  Future<void> updateProfile({String? displayName, String? avatarId}) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    emit(ProfileUpdating());
    try {
      final updatedProfile = await profileService.updateProfile(
        userId: userId,
        displayName: displayName,
        avatarId: avatarId,
      );

      // Fetch new avatar URL if avatar was updated
      String? avatarUrl = currentState.avatarUrl;
      String? photoUrl = currentState.photoUrl;
      if (avatarId != null) {
        avatarUrl = await profileService.getAvatarUrlById(avatarId);
      }

      emit(ProfileUpdated(updatedProfile));
      emit(
        ProfileLoaded(
          profile: updatedProfile,
          avatarUrl: avatarUrl,
          photoUrl: photoUrl,
        ),
      );
    } catch (e) {
      emit(ProfileError(userMessage(e)));
      // Restore previous state
      emit(currentState);
    }
  }

  Future<void> updateAvatar(String avatarId) async {
    await updateProfile(avatarId: avatarId);
  }

  Future<void> updateDisplayName(String displayName) async {
    await updateProfile(displayName: displayName);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PROFILE PHOTO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload a real profile photo. Shows uploading state, then refreshes.
  Future<void> uploadProfilePhoto(File imageFile) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    // Show uploading state so UI can display a progress indicator
    emit(
      ProfilePhotoUploading(
        profile: currentState.profile,
        avatarUrl: currentState.avatarUrl,
        photoUrl: currentState.photoUrl,
      ),
    );

    try {
      final updatedProfile = await profileService.uploadProfilePhoto(imageFile);

      // Resolve the new photo URL — photoKey is always present via the JOIN in getProfile
      String? photoUrl;
      if (updatedProfile.hasPhoto && updatedProfile.photoKey != null) {
        photoUrl = profileService.getProfilePhotoUrl(updatedProfile.photoKey!);
      }

      // Keep avatar URL around for fallback
      String? avatarUrl = currentState.avatarUrl;
      if (updatedProfile.avatarId != null && avatarUrl == null) {
        avatarUrl = await profileService.getAvatarUrlById(
          updatedProfile.avatarId!,
        );
      }

      emit(ProfileUpdated(updatedProfile));
      emit(
        ProfileLoaded(
          profile: updatedProfile,
          avatarUrl: avatarUrl,
          photoUrl: photoUrl,
        ),
      );
    } catch (e) {
      emit(ProfileError(userMessage(e)));
      emit(currentState);
    }
  }

  /// Delete real photo and revert to avatar display.
  Future<void> deleteProfilePhoto() async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    emit(
      ProfilePhotoUploading(
        profile: currentState.profile,
        avatarUrl: currentState.avatarUrl,
        photoUrl: currentState.photoUrl,
      ),
    );

    try {
      final updatedProfile = await profileService.deleteProfilePhoto();

      // Re-resolve avatar URL
      String? avatarUrl;
      if (updatedProfile.avatarId != null) {
        avatarUrl = await profileService.getAvatarUrlById(
          updatedProfile.avatarId!,
        );
      }

      emit(ProfileUpdated(updatedProfile));
      emit(
        ProfileLoaded(
          profile: updatedProfile,
          avatarUrl: avatarUrl,
          photoUrl: null,
        ),
      );
    } catch (e) {
      emit(ProfileError(userMessage(e)));
      emit(currentState);
    }
  }
}
