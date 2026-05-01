import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';
import '../../core/routes/app_router.dart';
import '../auth/cubit/auth_cubit.dart';
import '../profile/cubit/profile_cubit.dart';
import 'widgets/name_input_screen.dart';
import 'widgets/avatar_selection_screen.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          // ✅ Reload profile & auth so MainNavigation / HomeScreen have data
          final authCubit = context.read<AuthCubit>();
          final profileCubit = context.read<ProfileCubit>();
          final onboardingCubit = context.read<OnboardingCubit>();

          // Ensure ProfileCubit has the userId (it may still be '' from main.dart)
          if (profileCubit.userId.isEmpty) {
            profileCubit.updateUserId(onboardingCubit.userId);
          }

          // Re-check auth → re-fetches profile, sets needsOnboarding = false
          authCubit.checkAuthStatus();

          // Also explicitly reload ProfileCubit (it drives HomeScreen + MainNavigation)
          profileCubit.loadProfile();

          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        } else if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is OnboardingLoading || state is OnboardingCompleting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is OnboardingNameStep) {
          return NameInputScreen(
            firstName: state.firstName,
            lastName: state.lastName,
          );
        }

        if (state is OnboardingAvatarStep) {
          return AvatarSelectionScreen(
            firstName: state.firstName,
            lastName: state.lastName,
            avatars: state.avatars,
            selectedAvatarId: state.selectedAvatarId,
            avatarUrls: state.avatarUrls,
          );
        }

        // Initial state
        return const Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
