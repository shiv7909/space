import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Removed google_fonts and flutter_animate
import '../../core/routes/app_router.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart' as app_auth;
import '../../Features/profile/cubit/profile_cubit.dart';
import '../../Features/profile/cubit/profile_state.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _navigated = false;

  late final StreamSubscription _authSubscription;
  late final StreamSubscription _profileSubscription;

  @override
  void initState() {
    super.initState();

    final authCubit = context.read<AuthCubit>();
    _authSubscription = authCubit.stream.listen((state) {
      _checkAndNavigate();
    });

    final profileCubit = context.read<ProfileCubit>();
    _profileSubscription = profileCubit.stream.listen((state) {
      _checkAndNavigate();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (_navigated) return;

    final authState = context.read<AuthCubit>().state;

    if (authState is app_auth.AuthAuthenticated) {
      if (authState.needsOnboarding) {
        _navigate(AppRouter.onboarding);
        return;
      }
      final profileState = context.read<ProfileCubit>().state;
      if (profileState is ProfileLoaded) {
        _navigate(AppRouter.home);
      }
    } else if (authState is app_auth.AuthUnauthenticated ||
        authState is app_auth.AuthError) {
      _navigate(AppRouter.auth);
    }
  }

  void _navigate(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _authSubscription.cancel();
    _profileSubscription.cancel();
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _profileSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
