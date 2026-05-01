import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../all/all_dashboard_view.dart';
import '../all/cubit/all_dashboard_cubit.dart';
import '../solo/solo_dashboard_view.dart';
import '../couple/couple_space_view.dart';
import '../group/group_space_view.dart';
import '../habits/cubit/habits_cubit.dart';
import 'widgets/hero_progress_banner.dart';
import 'widgets/habits_header_hero.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/cubit/profile_state.dart';
import '../profile/profile_popup.dart';
import '../../models/user_model.dart';
import '../../services/space_service.dart';
import '../../services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../shared/sticky_action_buttons.dart';

/// Unified habits hub — Midnight theme with glow effects, tab selector, and dynamic dashboards.
class HabitsHubScreen extends StatefulWidget {
  final int initialTab;

  const HabitsHubScreen({super.key, this.initialTab = 0});

  @override
  State<HabitsHubScreen> createState() => HabitsHubScreenState();
}

class HeroStats {
  final int total;
  final int scheduled;
  final int completed;
  HeroStats({this.total = 0, this.scheduled = 0, this.completed = 0});
}

class HabitsHubScreenState extends State<HabitsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  AllDashboardCubit? _allDashboardCubit;
  int _activeTabIndex = 0;

  final Map<int, HeroStats> _tabStats = {
    0: HeroStats(),
    1: HeroStats(),
    2: HeroStats(),
    3: HeroStats(),
  };

  static const _tabs = ['Today', 'Solo', 'Duo', 'Squad'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _allDashboardCubit == null) {
        final profileState = context.read<ProfileCubit>().state;
        final String userId =
            profileState is ProfileLoaded ? profileState.profile.id : '';
        setState(() {
          _allDashboardCubit = AllDashboardCubit(
            context.read<SpaceService>(),
            userId: userId,
          )..loadDashboard();
        });
      }
    });

    _tabController.addListener(() {
      if (_tabController.index != _activeTabIndex) {
        setState(() {
          _activeTabIndex = _tabController.index;
        });
      }
    });
  }

  /// Called externally (e.g. from [MainNavigation] via GlobalKey) to jump to a
  /// specific sub-tab inside the hub without animation lag.
  void jumpToTab(int index) {
    if (!mounted) return;
    _tabController.animateTo(index.clamp(0, _tabs.length - 1));
  }

  void _updateStats(int tabIndex, int total, int scheduled, int completed) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = _tabStats[tabIndex]!;
      if (current.total == total &&
          current.scheduled == scheduled &&
          current.completed == completed)
        return;
      setState(() {
        _tabStats[tabIndex] = HeroStats(
          total: total,
          scheduled: scheduled,
          completed: completed,
        );
      });
    });
  }

  /// Shows the profile popup bottom sheet.
  Future<void> _showProfilePopup(
    BuildContext ctx,
    ProfileLoaded profileState,
  ) async {
    String? finalDisplayUrl = profileState.displayUrl;
    if (finalDisplayUrl == null && profileState.profile.avatarId != null) {
      finalDisplayUrl = await ctx.read<ProfileService>().getAvatarUrlById(
        profileState.profile.avatarId!,
      );
    }
    final currentUser = Supabase.instance.client.auth.currentUser;
    final tempUser = UserModel(
      id: profileState.profile.id,
      email: currentUser?.email ?? '',
      displayName: profileState.profile.displayName,
      avatarUrl: finalDisplayUrl,
      createdAt: profileState.profile.updatedAt,
    );
    if (!ctx.mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder:
          (sheetCtx) => Padding(
            padding: MediaQuery.viewInsetsOf(sheetCtx),
            child: ProfilePopup(
              user: tempUser,
              profile: profileState.profile,
              avatarUrl: profileState.profile.hasPhoto ? null : finalDisplayUrl,
              photoUrl: profileState.profile.hasPhoto ? finalDisplayUrl : null,
              onEditAvatar: () => Navigator.pop(sheetCtx),
              onScanQR: () => Navigator.pop(sheetCtx),
            ),
          ),
    );
    if (result == true && ctx.mounted) {
      ctx.read<ProfileCubit>().loadProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _allDashboardCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allDashboardCubit == null) {
      return const Scaffold(
        backgroundColor: AppColors.midnightPageBG,
        body: SizedBox.shrink(),
      );
    }

    // Notice we use the Midnight theme colors here.
    return BlocProvider<AllDashboardCubit>.value(
      value: _allDashboardCubit!,
      child: Scaffold(
        backgroundColor: AppColors.midnightPageBG,
        body: Column(
          children: [
            // ── Hero Header (Replaces StickyActionButtons + Old Banner) ──
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState is! ProfileLoaded) {
                  return const SizedBox(height: 60);
                }
                final activeStats = _tabStats[_activeTabIndex]!;
                final overlayTopInset =
                    (MediaQuery.paddingOf(context).top + 60) * 0.9;
                return Stack(
                  children: [
                    HeroProgressBanner(
                      scheduled: activeStats.scheduled,
                      done: activeStats.completed,
                      remaining: (activeStats.scheduled - activeStats.completed)
                          .clamp(0, 9999),
                      topContentInset: overlayTopInset,
                    ),
                    SafeArea(
                      bottom: false,
                      child: StickyActionButtons(
                        spaceType: _activeTabIndex == 2
                            ? SpaceType.couple
                            : _activeTabIndex == 3
                                ? SpaceType.group
                                : SpaceType.solo,
                        profile: profileState.profile,
                        displayUrl: profileState.displayUrl,
                        scrollController: _scrollController,
                        blendWithDarkHeader: true,
                      ),
                    ),
                  ],
                );
              },
            ),

            // ── White Section ──
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.midnightSurfaceBG,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: HabitTabSelector(
                        tabs: const ['today', 'solo', 'duo', 'squad'],
                        tabController: _tabController,
                        onTabChanged: (index) {
                          _tabController.animateTo(index);
                        },
                      ),
                    ),

                    // ── Dashboard Views ──
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          BlocProvider<AllDashboardCubit>.value(
                            value: _allDashboardCubit!,
                            child: AllDashboardView(
                              showAppBar: false,
                              onStatsUpdate:
                                  (t, s, c) => _updateStats(0, t, s, c),
                            ),
                          ),
                          BlocProvider(
                            create:
                                (context) =>
                                    HabitsCubit(context.read<SpaceService>()),
                            child: SoloDashboardView(
                              showAppBar: false,
                              onStatsUpdate:
                                  (t, s, c) => _updateStats(1, t, s, c),
                            ),
                          ),
                          BlocProvider(
                            create:
                                (context) =>
                                    HabitsCubit(context.read<SpaceService>()),
                            child: CoupleSpaceView(
                              showAppBar: false,
                              onStatsUpdate:
                                  (t, s, c) => _updateStats(2, t, s, c),
                            ),
                          ),
                          BlocProvider(
                            create:
                                (context) =>
                                    HabitsCubit(context.read<SpaceService>()),
                            child: GroupSpaceView(
                              showAppBar: false,
                              onStatsUpdate:
                                  (t, s, c) => _updateStats(3, t, s, c),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
