import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'Features/auth/cubit/auth_cubit.dart';
import 'Features/auth/cubit/auth_state.dart' as app_auth;
import 'Features/profile/cubit/profile_cubit.dart';
import 'Features/invites/cubit/invite_cubit.dart';
import 'Features/activity/cubit/activity_badge_cubit.dart';
import 'Features/couple/cubit/spaces_cubit.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/space_service.dart';
import 'services/shape_service.dart';
import 'services/snap_service.dart';
import 'services/category_service.dart';
import 'services/brand_challenge_service.dart';
import 'services/firebase_notification_service.dart';
import 'services/home_widget_service.dart';

void main() async {
  // ── Global error boundary ────────────────────────────────────────
  // Catches widget-layer errors (build / layout / paint).
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // default red screen in debug
    _logFatalError(details.exception, details.stack);
  };

  // Catches platform-level errors (native code, isolate crashes).
  PlatformDispatcher.instance.onError = (error, stack) {
    _logFatalError(error, stack);
    return true; // prevent app termination
  };

  // ── Run inside a guarded zone to catch unhandled async errors ──
  runZonedGuarded(
    () async {
      // Initialize bindings first
      WidgetsFlutterBinding.ensureInitialized();

      // Now initialize Firebase (requires bindings)
      await Firebase.initializeApp();

      // Initialize Firebase Cloud Messaging asynchronously
      // We do not await this because it requests permissions and fetches network tokens,
      // which blocks the app from rendering its first frame if awaited!
      FirebaseNotificationService().initialize();

      SupabaseConfig.validate();

      // Initialize Supabase (requires bindings)
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );

      // Create services
      final supabaseClient = Supabase.instance.client;
      final authService = AuthService(supabaseClient: supabaseClient);
      final profileService = ProfileService(supabaseClient: supabaseClient);
      final spaceService = SpaceService(supabaseClient: supabaseClient);
      final shapeService = ShapeService(supabaseClient: supabaseClient);
      final snapService = SnapService(supabaseClient: supabaseClient);
      final categoryService = CategoryService(supabaseClient: supabaseClient);
      final brandChallengeService = BrandChallengeService(supabaseClient: supabaseClient);

      // Initialize home screen widget with dummy data
      // Fire-and-forget — don't block first frame render
      HomeWidgetService().initialize();

      // Configure image cache for performance (after bindings are initialized)
      imageCache.maximumSize = 100; // Max 100 images in memory
      imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100 MB max

      runApp(
        MyApp(
          authService: authService,
          profileService: profileService,
          spaceService: spaceService,
          shapeService: shapeService,
          snapService: snapService,
          categoryService: categoryService,
          brandChallengeService: brandChallengeService,
        ),
      );
    },
    (error, stack) => _logFatalError(error, stack),
  );
}

/// Centralized fatal-error handler.
/// In debug mode: prints to console.
/// In release mode: this is the hook for Crashlytics/Sentry when integrated.
void _logFatalError(Object error, StackTrace? stack) {
  if (kDebugMode) {
    debugPrint('\n╔══════════════════════════════════════════╗');
    debugPrint('║  🔴 UNHANDLED ERROR                      ║');
    debugPrint('╚══════════════════════════════════════════╝');
    debugPrint('$error');
    if (stack != null) debugPrint('$stack');
  }
  // TODO: Send to Crashlytics / Sentry when integrated
  // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final ProfileService profileService;
  final SpaceService spaceService;
  final ShapeService shapeService;
  final SnapService snapService;
  final CategoryService categoryService;
  final BrandChallengeService brandChallengeService;

  const MyApp({
    super.key,
    required this.authService,
    required this.profileService,
    required this.spaceService,
    required this.shapeService,
    required this.snapService,
    required this.categoryService,
    required this.brandChallengeService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: profileService),
        RepositoryProvider.value(value: spaceService),
        RepositoryProvider.value(value: shapeService),
        RepositoryProvider.value(value: snapService),
        RepositoryProvider.value(value: categoryService),
        RepositoryProvider.value(value: brandChallengeService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => AuthCubit(
                  authService: authService,
                  profileService: profileService,
                )..checkAuthStatus(),
          ),
          BlocProvider(
            create:
                (context) => ActivityBadgeCubit(Supabase.instance.client),
          ),
          BlocProvider(
            create:
                (context) =>
                    ProfileCubit(profileService: profileService, userId: ''),
          ),
          BlocProvider(
            create: (context) => InviteCubit(spaceService: spaceService),
          ),
          // Provide SpacesCubit globally
          BlocProvider(
            create: (context) {
              final authCubit = context.read<AuthCubit>();
              final userId =
                  authCubit.state is app_auth.AuthAuthenticated
                      ? (authCubit.state as app_auth.AuthAuthenticated).user.id
                      : '';
              final spacesCubit = SpacesCubit(
                spaceService: spaceService,
                userId: userId,
                inviteCubit: context.read<InviteCubit>(),
              );
              if (userId.isNotEmpty) {
                spacesCubit.loadSpaces();
              }
              return spacesCubit;
            },
          ),
        ],
        child: BlocListener<AuthCubit, app_auth.AuthState>(
          listener: (context, state) {
            if (state is app_auth.AuthAuthenticated) {
              // When user logs in or re-checks auth, always refresh profile
              final profileCubit = context.read<ProfileCubit>();
              profileCubit.updateUserId(state.user.id);

              // OPTIMIZATION: If AuthCubit already fetched the profile, pass it directly
              // to avoid a SECOND network call and a 'Loading' state glitch.
              if (state.profile != null) {
                profileCubit.setProfile(
                  state.profile,
                  avatarUrl: state.avatarUrl,
                  photoUrl: state.photoUrl,
                );
              } else {
                profileCubit.loadProfile();
              }

              // Update SpacesCubit userId and reload
              final spacesCubit = context.read<SpacesCubit>();
              spacesCubit.updateUserId(state.user.id);

              // Initialize ActivityBadgeCubit
              context.read<ActivityBadgeCubit>().initForUser();

              // Start polling for pending invites
              context.read<InviteCubit>().startPolling();
            }
          },
          child: MaterialApp(
            title: 'space',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.splash,
          ),
        ),
      ),
    );
  }
}
