import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Features/auth/auth_view.dart';
import '../../Features/navigation/main_navigation.dart';
import '../../Features/splash/splash_view.dart';
import '../../Features/onboarding/onboarding_view.dart';
import '../../Features/onboarding/cubit/onboarding_cubit.dart';
import '../../Features/discover/screens/join_requests_screen.dart';
import '../../Features/activity/activity_screen.dart';
import '../../Features/activity/cubit/activity_cubit.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String joinRequests = '/join-requests';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashView(), settings);
      case auth:
        return _fadeRoute(const AuthView(), settings);
      case onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final profileService = RepositoryProvider.of<ProfileService>(
              context,
            );
            final authService = RepositoryProvider.of<AuthService>(context);

            return FutureBuilder(
              future: authService.getCurrentUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Scaffold(
                    backgroundColor: Color(0xFFF5F5F8),
                    body: SizedBox.shrink(),
                  );
                }

                return BlocProvider(
                  create:
                      (context) => OnboardingCubit(
                        profileService: profileService,
                        userId: snapshot.data!.id,
                      )..startOnboarding(),
                  child: const OnboardingView(),
                );
              },
            );
          },
        );
      case home:
        return _fadeRoute(const MainNavigation(), settings);
      case '/activity':
        return _fadeRoute(
          BlocProvider(
            create: (context) => ActivityCubit(Supabase.instance.client),
            child: const ActivityScreen(),
          ),
          settings,
        );
      case joinRequests:
        final args = settings.arguments as Map<String, String>;
        return _fadeRoute(
          JoinRequestsScreen(
            spaceId: args['spaceId']!,
            spaceName: args['spaceName'] ?? 'Space',
          ),
          settings,
        );
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }

  /// Smooth fade transition — no slide, no flicker
  static Route<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}
