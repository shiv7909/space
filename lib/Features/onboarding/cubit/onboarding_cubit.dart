import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/profile_service.dart';
import '../../../services/firebase_notification_service.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final ProfileService profileService;
  final String userId;

  OnboardingCubit({required this.profileService, required this.userId})
    : super(OnboardingInitial());

  void startOnboarding() {
    emit(const OnboardingNameStep());
  }

  void updateName(String firstName, String lastName) {
    emit(OnboardingNameStep(firstName: firstName, lastName: lastName));
  }

  Future<void> proceedToAvatarSelection(String firstName, String lastName) async {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      emit(const OnboardingError('Please enter both first and last name'));
      return;
    }

    emit(OnboardingLoading());
    try {
      print('🔵 OnboardingCubit: Fetching avatars...');
      final avatars = await profileService.getAvatars();
      print('🟢 OnboardingCubit: Found ${avatars.length} avatars');

      // Show the grid immediately — URLs will stream in via _preloadAvatarUrls
      emit(OnboardingAvatarStep(
        firstName: firstName,
        lastName: lastName,
        avatars: avatars,
      ));

      // Sign all URLs in parallel — single batch, no serial loop
      _preloadAvatarUrls(avatars);
    } catch (e) {
      print('🔴 OnboardingCubit: Error loading avatars: $e');
      emit(OnboardingError('Failed to load avatars: ${e.toString()}'));
    }
  }

  /// Signs all avatar URLs in parallel using Future.wait — replaces the old
  /// serial byte-download loop that made 116 sequential network calls.
  void _preloadAvatarUrls(List<dynamic> avatars) async {
    if (isClosed) return;

    // Fire all signing requests at once
    final futures = avatars.map((avatar) async {
      try {
        final url = await profileService.getAvatarUrl(avatar.avatarKey);
        return MapEntry(avatar.avatarKey as String, url);
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);

    if (isClosed || state is! OnboardingAvatarStep) return;

    final urlMap = <String, String>{};
    for (final entry in results) {
      if (entry != null) urlMap[entry.key] = entry.value;
    }

    emit((state as OnboardingAvatarStep).copyWith(avatarUrls: urlMap));
    print('🟢 OnboardingCubit: ${urlMap.length} avatar URLs signed in parallel');
  }

  void selectAvatar(String avatarId) {
    if (state is OnboardingAvatarStep) {
      final currentState = state as OnboardingAvatarStep;
      emit(currentState.copyWith(selectedAvatarId: avatarId));
    }
  }

  Future<void> completeOnboarding() async {
    if (state is! OnboardingAvatarStep) return;

    final currentState = state as OnboardingAvatarStep;
    emit(OnboardingCompleting());

    try {
      final displayName = '${currentState.firstName} ${currentState.lastName}';
      await profileService.createProfile(
        userId: userId,
        displayName: displayName,
        avatarId: currentState.selectedAvatarId,
      );

      // Save FCM Token after profile creation (onboarding complete)
      await FirebaseNotificationService().saveFcmToken();

      emit(OnboardingCompleted());
    } catch (e) {
      emit(OnboardingError('Failed to complete onboarding: ${e.toString()}'));
    }
  }

  void skipAvatar() async {
    if (state is! OnboardingAvatarStep) return;

    final currentState = state as OnboardingAvatarStep;
    emit(OnboardingCompleting());

    try {
      final displayName = '${currentState.firstName} ${currentState.lastName}';
      await profileService.createProfile(
        userId: userId,
        displayName: displayName,
      );

      // Save FCM Token after profile creation (onboarding skipped)
      await FirebaseNotificationService().saveFcmToken();

      emit(OnboardingCompleted());
    } catch (e) {
      emit(OnboardingError('Failed to complete onboarding: ${e.toString()}'));
    }
  }
}
