import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/firebase_notification_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;
  final ProfileService profileService;
  StreamSubscription? _authStateSubscription;

  AuthCubit({required this.authService, required this.profileService})
    : super(AuthInitial()) {
    // Listen to auth state changes
    _authStateSubscription = authService.authStateChanges.listen((user) async {
      if (user != null) {
        print('🔵 AuthCubit: authStateChanges - User logged in: ${user.id}');

        // Save FCM Token immediately after login
        await FirebaseNotificationService().saveFcmToken();

        try {
          final profile = await profileService.getProfile(user.id);
          final needsOnboarding = profile == null || !profile.isComplete;
          print(
            '🟡 AuthCubit: authStateChanges - needsOnboarding = $needsOnboarding',
          );

          String? avatarUrl;
          String? photoUrl;

          if (profile?.avatarId != null) {
            avatarUrl = await profileService.getAvatarUrlById(
              profile!.avatarId!,
            );
          }

          if (profile != null && profile.hasPhoto && profile.photoKey != null) {
            try {
              photoUrl = profileService.getProfilePhotoUrl(profile.photoKey!);
            } catch (_) {
              // Ignore invalid photo
            }
          }

          emit(
            AuthAuthenticated(
              user,
              needsOnboarding: needsOnboarding,
              profile: profile,
              avatarUrl: avatarUrl,
              photoUrl: photoUrl,
            ),
          );
        } catch (e) {
          // Network/SSL error — don't treat as missing profile.
          // checkAuthStatus() will resolve this with its own retry.
          print(
            '🔴 AuthCubit: authStateChanges - network error, skipping navigation: $e',
          );
        }
      } else {
        print('🔵 AuthCubit: authStateChanges - User logged out');
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        print(
          '🔵 AuthCubit: checkAuthStatus - Checking profile for user: ${user.id}',
        );
        final profile = await profileService.getProfile(user.id);
        print(
          '🔵 AuthCubit: checkAuthStatus - Profile result: ${profile?.displayName ?? "NULL"}',
        );
        final needsOnboarding = profile == null || !profile.isComplete;
        print(
          '🟡 AuthCubit: checkAuthStatus - needsOnboarding = $needsOnboarding',
        );

        String? avatarUrl;
        String? photoUrl;

        if (profile?.avatarId != null) {
          avatarUrl = await profileService.getAvatarUrlById(profile!.avatarId!);
        }

        if (profile != null && profile.hasPhoto && profile.photoKey != null) {
            try {
              photoUrl = profileService.getProfilePhotoUrl(profile.photoKey!);
            } catch (_) {}
        }

        emit(
          AuthAuthenticated(
            user,
            needsOnboarding: needsOnboarding,
            profile: profile,
            avatarUrl: avatarUrl,
            photoUrl: photoUrl,
          ),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // Network error during startup — retry once more before giving up
      print('🔴 AuthCubit: checkAuthStatus failed: $e — retrying...');
      await Future.delayed(const Duration(seconds: 1));
      try {
        final user = await authService.getCurrentUser();
        if (user != null) {
          final profile = await profileService.getProfile(user.id);
          final needsOnboarding = profile == null || !profile.isComplete;
          String? avatarUrl;
          String? photoUrl;

          if (profile?.avatarId != null) {
            avatarUrl = await profileService.getAvatarUrlById(
              profile!.avatarId!,
            );
          }

          if (profile != null && profile.hasPhoto && profile.photoKey != null) {
              try {
                photoUrl = profileService.getProfilePhotoUrl(profile.photoKey!);
              } catch (_) {}
          }

          emit(
            AuthAuthenticated(
              user,
              needsOnboarding: needsOnboarding,
              profile: profile,
              avatarUrl: avatarUrl,
              photoUrl: photoUrl,
            ),
          );
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e2) {
        print('🔴 AuthCubit: checkAuthStatus retry also failed: $e2');
        emit(AuthUnauthenticated());
      }
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      print('🔵 AuthCubit: Starting sign-in...');
      final user = await authService.signInWithGoogle();
      print('🟢 AuthCubit: Sign-in successful, user: ${user.email}');

      // Save FCM token for this user after successful login
      print('🔵 AuthCubit: Saving FCM token...');
      await FirebaseNotificationService().refreshAndSaveFCMToken();
      print('🟢 AuthCubit: FCM token saved');

      // Check if user needs onboarding
      print('🔵 AuthCubit: Checking profile for user: ${user.id}');
      final profile = await profileService.getProfile(user.id);
      print('🔵 AuthCubit: Profile result: ${profile?.displayName ?? "NULL"}');
      final needsOnboarding = profile == null || !profile.isComplete;
      print('🟡 AuthCubit: needsOnboarding = $needsOnboarding');

      // Fetch avatar URL if profile has an avatar
      String? avatarUrl;
      String? photoUrl;

      if (profile?.avatarId != null) {
        avatarUrl = await profileService.getAvatarUrlById(profile!.avatarId!);
      }

      if (profile != null && profile.hasPhoto && profile.photoKey != null) {
          try {
            photoUrl = profileService.getProfilePhotoUrl(profile.photoKey!);
          } catch (_) {}
      }

      emit(
        AuthAuthenticated(
          user,
          needsOnboarding: needsOnboarding,
          profile: profile,
          avatarUrl: avatarUrl,
          photoUrl: photoUrl,
        ),
      );
    } catch (e) {
      print('🔴 AuthCubit: Sign-in error: $e');
      emit(AuthError('Sign-in failed: ${e.toString()}'));
      // Emit unauthenticated after error so user can try again
      Future.delayed(const Duration(seconds: 2), () {
        if (state is AuthError) {
          emit(AuthUnauthenticated());
        }
      });
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
