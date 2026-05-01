import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart' as app_auth;

import '../home/home_screen.dart';
import '../solo/cubit/solo_dashboard_cubit.dart';
import '../group/cubit/group_dashboard_cubit.dart';
import '../../services/space_service.dart';
import '../habits/habits_hub_screen.dart';
import '../../services/firebase_notification_service.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/cubit/profile_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../couple/cubit/couple_dashboard_cubit.dart';
import '../discover/cubit/discover_cubit.dart';
import '../discover/cubit/active_people_cubit.dart';
import '../activity/cubit/activity_cubit.dart';
import '../activity/cubit/activity_state.dart';
import '../invites/pending_invites_screen.dart';
import '../spaces/screens/brand_discovery_screen.dart';
import '../discover/widgets/discover_content.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _brandDiscoveryRefreshToken = 0;
  SoloDashboardCubit? _soloCubit;
  CoupleDashboardCubit? _coupleCubit;
  GroupDashboardCubit? _groupCubit;

  // ── Activity ──
  late final ActivityCubit _activityCubit;

  // ── Discover ──
  late final DiscoverCubit _discoverCubit;
  late final ActivePeopleCubit _activePeopleCubit;
  Position? _discoverPosition;

  double _lastScrollPosition = 0.0;
  bool _isBottomNavVisible = true;
  bool _isAnimating = false;

  // ── Key for controlling HabitsHubScreen sub-tabs from notifications ──
  final GlobalKey<HabitsHubScreenState> _habitsHubKey =
      GlobalKey<HabitsHubScreenState>();

  // ── Cached Screens to prevent excessive list re-renders on scroll ──
  List<Widget>? _cachedScreens;

  // ── Nav items (4 tabs: Home, Search, Habits, Spaces) ──
  static const _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Habits',
    ),
    _NavItem(
      icon: Icons.rocket_launch_outlined,
      activeIcon: Icons.rocket_launch_rounded,
      label: 'Spaces',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialise Discover cubit once — data loads immediately, no GPS wait
    _discoverCubit = DiscoverCubit(Supabase.instance.client);
    _activePeopleCubit = ActivePeopleCubit(Supabase.instance.client);
    _activityCubit = ActivityCubit(Supabase.instance.client)
      ..loadAll(); // Load immediately for badge

    // Attempt to initialize dashboard cubits synchronously if profile is ready
    _tryInitCubits();

    _initDiscoverLocation();

    // Fallback: Check again after frame (in case profile loads very fast right now)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _soloCubit == null) {
        _tryInitCubits(); // Try again
        if (_soloCubit != null) setState(() {});
      }
    });

    // Register notification navigation callback
    _setupNotificationNavigation();
  }

  /// Setup notification navigation handler
  void _setupNotificationNavigation() {
    FirebaseNotificationService().setNavigationCallback((data) {
      _handleNotificationNavigation(data);
    });
  }

  /// Handle notification navigation based on type and data
  ///
  /// Matches the 5 backend notification types:
  ///   nudge, partner_done, space_invite, join_accepted, streak_broken
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final spaceId = data['space_id'] as String?;
    final habitId = data['habit_id'] as String?;
    final inviteId = data['invite_id'] as String?;

    print(
      '🔔 Processing notification: type=$type, spaceId=$spaceId, habitId=$habitId, inviteId=$inviteId',
    );

    switch (type) {
      // ── Duo: partner nudged you ──
      case 'nudge':
        _navigateToSpace(spaceId, habitId: habitId);
        break;

      // ── Duo: partner completed a habit ──
      case 'partner_done':
        _navigateToSpace(spaceId, habitId: habitId);
        break;

      // ── Someone invited you to their space ──
      case 'space_invite':
        _navigateToInvites();
        break;

      // ── Your join request was accepted ──
      case 'join_accepted':
        _navigateToSpace(spaceId);
        break;

      // ── Overnight cron: your streak broke ──
      // NOTE: For solo habits, space_id may be null — only habit_id is sent.
      case 'streak_broken':
        if (spaceId != null) {
          _navigateToSpace(spaceId);
        } else {
          // Solo streak broken — no space_id, navigate to solo tab
          _navigateToSoloDashboard();
        }
        break;

      default:
        print('⚠️ Unknown notification type: $type');
        _navigateToHome();
    }
  }

  /// Navigate to home tab
  void _navigateToHome() {
    print('📍 Navigating to Home');
    if (!mounted) return;
    setState(() {
      _currentIndex = 0;
      _lastScrollPosition = 0.0;
      _isBottomNavVisible = true;
    });
  }

  /// Navigate to the solo dashboard tab directly
  void _navigateToSoloDashboard() {
    print('📍 Navigating to Solo Dashboard');
    if (!mounted) return;
    setState(() {
      _currentIndex = 2; // Habits tab is now index 2
      _lastScrollPosition = 0.0;
      _isBottomNavVisible = true;
    });
    // Jump to Solo sub-tab inside the hub
    _habitsHubKey.currentState?.jumpToTab(0);
    if (_soloCubit != null) {
      _soloCubit!.loadDashboard();
    }
    _showNotificationBanner('💔 Streak broken', 'Time to start fresh!');
  }

  /// Navigate to a specific space based on type
  void _navigateToSpace(String? spaceId, {String? habitId}) {
    if (spaceId == null) {
      print('⚠️ No spaceId provided, navigating to home');
      _navigateToHome();
      return;
    }

    print('📍 Navigating to space: $spaceId');
    _loadSpaceAndNavigate(spaceId, habitId: habitId);
  }

  /// Navigate to invites screen (real screen, not placeholder)
  void _navigateToInvites() {
    print('📍 Navigating to Pending Invites');
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PendingInvitesScreen()),
      );
    }
  }

  /// Load a space and navigate to it
  Future<void> _loadSpaceAndNavigate(String spaceId, {String? habitId}) async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch the space directly from the spaces table
      final response = await supabase
          .from('spaces')
          .select('id, name, type')
          .eq('id', spaceId)
          .limit(1);

      if (response.isEmpty) {
        print('⚠️ Space not found: $spaceId');
        _navigateToHome();
        return;
      }

      final spaceData = response.first;
      final spaceName = spaceData['name'] as String?;
      final spaceType = spaceData['type'] as String? ?? '';

      print('🔍 Found space: $spaceType - $spaceId');

      if (mounted) {
        setState(() {
          _lastScrollPosition = 0.0;
          _isBottomNavVisible = true;

          // Route based on space type — all go to Habits tab (index 2)
          // then switch to the correct sub-tab inside the hub
          switch (spaceType.toLowerCase()) {
            case 'solo':
              _currentIndex = 2;
              _habitsHubKey.currentState?.jumpToTab(0);
              if (_soloCubit != null) {
                _soloCubit!.loadDashboard(focusHabitId: habitId);
              }
              break;
            case 'couple':
              _currentIndex = 2;
              _habitsHubKey.currentState?.jumpToTab(1);
              if (_coupleCubit != null) {
                _coupleCubit!.loadDashboard(
                  spaceId: spaceId,
                  focusHabitId: habitId,
                );
              }
              break;
            case 'group':
              _currentIndex = 2;
              _habitsHubKey.currentState?.jumpToTab(2);
              if (_groupCubit != null) {
                _groupCubit!.loadDashboard(
                  spaceId: spaceId,
                  focusHabitId: habitId,
                );
              }
              break;
            default:
              _currentIndex = 0;
          }
        });

        _showNotificationBanner('Opening Space', spaceName ?? 'Your space');
      }
    } catch (e) {
      print('❌ Error loading space: $e');
      _navigateToHome();
    }
  }

  /// Show in-app notification banner
  void _showNotificationBanner(String title, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 13)),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _tryInitCubits() {
    if (_soloCubit != null) return;

    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      final userId = profileState.profile.id;
      final spaceService = context.read<SpaceService>();

      _soloCubit = SoloDashboardCubit(spaceService, userId: userId)
        ..loadDashboard();

      _coupleCubit = CoupleDashboardCubit(spaceService, userId: userId);

      _groupCubit = GroupDashboardCubit(spaceService, userId: userId);

      _loadGroupSpaceIfExists(userId);
    }
  }

  Future<void> _initDiscoverLocation() async {
    // Fire immediately without GPS
    _discoverCubit.loadAll(null);
    _activePeopleCubit.load();

    // Then try to get location in the background
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        );
        if (mounted) {
          setState(() {
            _discoverPosition = pos;
          });
        }
      }
    } catch (_) {}

    if (mounted && _discoverPosition != null) {
      _discoverCubit.loadAll(_discoverPosition);
      _activePeopleCubit.load(
        lat: _discoverPosition?.latitude,
        lng: _discoverPosition?.longitude,
      );
      _cachedScreens = _buildScreens();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try again here (e.g. if arriving via route push)
    if (_soloCubit == null) {
      _tryInitCubits();
      if (_soloCubit != null) setState(() {});
    }
  }

  Future<void> _loadGroupSpaceIfExists(String userId) async {
    try {
      final spaces = await context.read<SpaceService>().getUserSpaces(userId);
      final groupSpaces = spaces.where((s) => s.type == 'group').toList();
      if (groupSpaces.isNotEmpty && mounted && _groupCubit != null) {
        _groupCubit!.loadDashboard(spaceId: groupSpaces.first.id);
      }
    } catch (_) {}
  }

  List<Widget> _buildScreens() {
    return [
      MultiBlocProvider(
        providers: [BlocProvider.value(value: _activePeopleCubit)],
        child: HomeScreen(
          discoverPosition: _discoverPosition,
          onOpenBrandDropsAll: _openBrandDropsAll,
        ),
      ),
      DiscoverContent(
        cubit: _discoverCubit,
        position: _discoverPosition,
        isEmbedded: false, // it gets its own scaffold/appbar
      ),
      HabitsHubScreen(key: _habitsHubKey),
      BrandDiscoveryScreen(
        key: ValueKey('brand_discovery_$_brandDiscoveryRefreshToken'),
      ),
    ];
  }

  void _openBrandDropsAll() {
    if (!mounted) return;
    setState(() {
      _lastScrollPosition = 0.0;
      _isBottomNavVisible = true;
      _currentIndex = 3;
      // Recreate discovery screen so it boots with default 'all' filter.
      _brandDiscoveryRefreshToken++;
      _cachedScreens = _buildScreens();
    });
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    if (notification.metrics.axis != Axis.vertical) return;
    if (_isAnimating) return;

    final currentScroll = notification.metrics.pixels;
    final delta = currentScroll - _lastScrollPosition;

    const scrollDownThreshold = 10.0;
    const scrollUpThreshold = 5.0;

    if (delta > scrollDownThreshold &&
        currentScroll > 80 &&
        _isBottomNavVisible) {
      _isAnimating = true;
      setState(() => _isBottomNavVisible = false);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _isAnimating = false;
      });
    } else if ((delta < -scrollUpThreshold || currentScroll < 50) &&
        !_isBottomNavVisible) {
      _isAnimating = true;
      setState(() => _isBottomNavVisible = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _isAnimating = false;
      });
    }

    _lastScrollPosition = currentScroll;
  }

  void _onTabChanged(int index) {
    setState(() {
      _lastScrollPosition = 0.0;
      _isBottomNavVisible = true;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 52.0;
    final totalNavHeight = navBarHeight + bottomPadding;

    // ── Listen for ProfileLoaded so we create the cubit as soon as it arrives ──
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listener: (context, profileState) {
            if (profileState is ProfileLoaded && _soloCubit == null) {
              setState(() {
                _tryInitCubits();
              });
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, app_auth.AuthState>(
        builder: (context, state) {
          final profile =
              state is app_auth.AuthAuthenticated ? state.profile : null;
          final isPremium = profile?.isPremium ?? false;

          // Cubit not ready yet — show loading indicator instead of blank screen
          if (_soloCubit == null) {
            return const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.onBackground,
                  ),
                ),
              ),
            );
          }

          return BlocProvider<SoloDashboardCubit>.value(
            value: _soloCubit!,
            child: _buildMainScaffold(isPremium, totalNavHeight, bottomPadding),
          );
        },
      ),
    );
  }

  Widget _buildMainScaffold(
    bool isPremium,
    double totalNavHeight,
    double bottomPadding,
  ) {
    if (_cachedScreens == null) {
        _cachedScreens = _buildScreens();
    }
    final screens = _cachedScreens!;

    return BlocProvider<SoloDashboardCubit>.value(
      value: _soloCubit!,
      child: BlocProvider<CoupleDashboardCubit>.value(
        value: _coupleCubit!,
        child: BlocProvider<GroupDashboardCubit>.value(
          value: _groupCubit!,
          child: BlocProvider<DiscoverCubit>.value(
            value: _discoverCubit,
            child: BlocProvider<ActivePeopleCubit>.value(
              value: _activePeopleCubit,
              child: BlocProvider<ActivityCubit>.value(
                value: _activityCubit,
                child: Scaffold(
                  extendBody: true,
                  body: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      _onScrollNotification(notification);
                      return false;
                    },
                    child: Stack(
                      children: [
                        IndexedStack(index: _currentIndex, children: screens),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                          bottom: _isBottomNavVisible ? (bottomPadding > 0 ? bottomPadding : 16.0) : -(totalNavHeight + 40),
                          left: 24,
                          right: 24,
                          child: BlocBuilder<ActivityCubit, ActivityState>(
                            builder: (context, activityState) {
                              return _PremiumNavBar(
                                currentIndex: _currentIndex,
                                items: _navItems,
                                isPremium: isPremium,
                                onTap: _onTabChanged,
                                bottomPadding: bottomPadding,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NAV ITEM MODEL
// ═══════════════════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM GEN-Z FLOATING NAV BAR
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumNavBar extends StatefulWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final bool isPremium;
  final ValueChanged<int> onTap;
  final double bottomPadding;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.items,
    required this.isPremium,
    required this.onTap,
    required this.bottomPadding,
  });

  @override
  State<_PremiumNavBar> createState() => _PremiumNavBarState();
}

class _PremiumNavBarState extends State<_PremiumNavBar>
    with TickerProviderStateMixin {
  // Per-item tap controllers
  late List<AnimationController> _tapControllers;
  late List<Animation<double>> _tapAnimations;

  @override
  void initState() {
    super.initState();

    _tapControllers = List.generate(
      widget.items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
      ),
    );
    _tapAnimations =
        _tapControllers
            .map(
              (c) => TweenSequence([
                TweenSequenceItem(
                  tween: Tween(
                    begin: 1.0,
                    end: 0.78,
                  ).chain(CurveTween(curve: Curves.easeIn)),
                  weight: 40,
                ),
                TweenSequenceItem(
                  tween: Tween(
                    begin: 0.78,
                    end: 1.0,
                  ).chain(CurveTween(curve: Curves.elasticOut)),
                  weight: 60,
                ),
              ]).animate(c),
            )
            .toList();
  }

  @override
  void didUpdateWidget(_PremiumNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _tapControllers[widget.currentIndex].forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final c in _tapControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    const navHeight = 60.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / n;

        return Container(
          height: navHeight,
          decoration: BoxDecoration(
            color: AppTheme.surface, // Clean white to match luxury aesthetic
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Sliding Active Indicator Bubble ──
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: widget.currentIndex * itemWidth + (itemWidth - 46) / 2,
                top: (navHeight - 46) / 2,
                width: 46,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint, // Sophisticated beige highlight
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // ── Nav items row ──
              Positioned.fill(
                child: Row(
                  children: List.generate(n, (i) {
                    final isActive = widget.currentIndex == i;
                    final item = widget.items[i];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onTap(i);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedBuilder(
                          animation: _tapAnimations[i],
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _tapAnimations[i].value,
                              child: child,
                            );
                          },
                          child: SizedBox(
                            height: navHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ── Icon ──
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 240),
                                      switchInCurve: Curves.easeOutBack,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, anim) => ScaleTransition(
                                        scale: anim,
                                        child: FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                      ),
                                      child: i == 2
                                          ? SizedBox(
                                              key: ValueKey('habits_$isActive'),
                                              width: isActive ? 22 : 20,
                                              height: isActive ? 22 : 20,
                                              child: SvgPicture.asset(
                                                isActive
                                                    ? 'assets/Svg/iconmonstr-layer-multiple-alt-filled.svg'
                                                    : 'assets/Svg/iconmonstr-layer-multiple-alt-lined.svg',
                                                colorFilter: ColorFilter.mode(
                                                  isActive
                                                      ? AppColors.primaryTextDark
                                                      : AppColors.textMuted,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            )
                                          : isActive
                                              ? Icon(
                                                  key: ValueKey('active_$i'),
                                                  item.activeIcon,
                                                  size: 22,
                                                  color: AppColors.primaryTextDark,
                                                )
                                              : Icon(
                                                  key: ValueKey('inactive_$i'),
                                                  item.icon,
                                                  size: 20,
                                                  color: AppColors.textMuted,
                                                ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
