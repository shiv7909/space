import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_helpers.dart';
import '../../models/dashboard_model.dart';
import '../../models/home_brand_section_model.dart';
import '../../services/brand_challenge_service.dart';
import '../couple/cubit/couple_dashboard_cubit.dart';
import '../couple/cubit/couple_dashboard_state.dart';
import '../couple/cubit/spaces_cubit.dart';
import '../couple/cubit/spaces_state.dart';
import '../discover/cubit/discover_cubit.dart';
import '../discover/cubit/discover_state.dart';
import '../discover/models/discover_models.dart';
import '../discover/widgets/active_people_section.dart';
import '../group/cubit/group_dashboard_cubit.dart';
import '../group/cubit/group_dashboard_state.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/cubit/profile_state.dart';
import '../shared/sticky_action_buttons.dart';
import '../solo/cubit/solo_dashboard_cubit.dart';
import '../solo/cubit/solo_dashboard_state.dart';
import '../solo/widgets/challenge_result_card.dart';
import '../solo/widgets/today_progress_widget.dart';
import 'cubit/home_screen_cubit.dart';
import 'cubit/home_screen_state.dart';
import 'widgets/empty_today_guide.dart';
import 'widgets/hero_carousel_cards.dart';
import '../../services/snap_service.dart';
import '../../services/space_service.dart';
import '../snaps/cubit/snap_cubit.dart';
import '../snaps/widgets/snap_feed_widget.dart';
import '../spaces/screens/brand_challenge_screen.dart';
import 'cubit/home_analytics_cubit.dart';
import 'widgets/home_analytics_card.dart';
import 'widgets/home_brand_section.dart';

class HomeScreen extends StatefulWidget {
  final Position? discoverPosition;
  final VoidCallback? onOpenBrandDropsAll;

  const HomeScreen({
    super.key,
    this.discoverPosition,
    this.onOpenBrandDropsAll,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late PageController _carouselController;
  HomeBrandSectionModel? _homeBrandSection;
  bool _isBrandSectionLoading = true;
  SnapCubit? _homeSnapCubit;
  String? _homeSnapUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _carouselController = PageController(viewportFraction: 0.88);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHomeBrandSection();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHomeBrandSection();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeSnapCubit?.close();
    _scrollController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _ensureHomeSnapCubit(String userId) {
    if (userId.isEmpty) return;
    if (_homeSnapCubit != null && _homeSnapUserId == userId) return;
    _homeSnapCubit?.close();
    _homeSnapUserId = userId;
    _homeSnapCubit = SnapCubit(context.read<SnapService>(), userId: userId)
      ..loadHomeTray();
  }

  Future<void> _loadHomeBrandSection({bool forceRefresh = false}) async {
    if (_isBrandSectionLoading && _homeBrandSection != null) return;

    if (mounted) {
      setState(() {
        _isBrandSectionLoading = _homeBrandSection == null;
      });
    }

    final service = context.read<BrandChallengeService>();
    final result = await service.getHomeBrandSection(
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;
    setState(() {
      _homeBrandSection = result;
      _isBrandSectionLoading = false;
    });
  }

  void _openBrandChallenge(String challengeId) {
    if (challengeId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrandChallengeScreen(challengeId: challengeId),
      ),
    );
  }

  void _animateCarousel(int nextPage) {
    if (!mounted || !_carouselController.hasClients) return;
    _carouselController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _handleJoinRequest(DiscoverSpace space) async {
    final discoverCubit = context.read<DiscoverCubit>();
    final spacesCubit = context.read<SpacesCubit>();
    final spacesState = spacesCubit.state;

    if (spacesState is! SpacesLoaded) {
      final result = await discoverCubit.requestToJoin(space.spaceId);
      _handleJoinResult(result);
      return;
    }

    final currentGroup =
        spacesState.groupSpaces.isNotEmpty
            ? spacesState.groupSpaces.first
            : null;
    final currentCouple =
        spacesState.coupleSpaces.isNotEmpty
            ? spacesState.coupleSpaces.first
            : null;

    List<_WarningItem> warnings = [];

    if (space.spaceType == 'group' && currentGroup != null) {
      final isOwner = currentGroup.createdBy == discoverCubit.userId;
      if (isOwner) {
        warnings.add(
          _WarningItem(
            icon: '⚠️',
            color: Colors.red,
            text:
                'You own "${currentGroup.name}". Joining a new group will DELETE your space and remove all members permanently. This cannot be undone.',
          ),
        );
      } else {
        warnings.add(
          _WarningItem(
            icon: '👋',
            color: Colors.orange,
            text:
                'You will be removed from "${currentGroup.name}" and all your habit data in that space will be lost.',
          ),
        );
      }
    }

    if (space.spaceType == 'couple' && currentCouple != null) {
      final isOwner = currentCouple.createdBy == discoverCubit.userId;
      if (isOwner) {
        warnings.add(
          _WarningItem(
            icon: '⚠️',
            color: Colors.red,
            text:
                'You own "${currentCouple.name}". Joining will DELETE your couple space and remove your partner permanently. This cannot be undone.',
          ),
        );
      } else {
        warnings.add(
          _WarningItem(
            icon: '💔',
            color: Colors.orange,
            text:
                'You will leave "${currentCouple.name}" and your shared history will be lost.',
          ),
        );
      }
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinBottomSheet(space: space, warnings: warnings),
    );

    if (result?['proceed'] == true && mounted) {
      final joinResult = await discoverCubit.requestToJoin(space.spaceId);
      _handleJoinResult(joinResult);
    }
  }

  void _handleJoinResult(dynamic result) {
    if (!mounted) return;
    if (result is JoinSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request sent! 🙌'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (result is JoinError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        if (profileState is! ProfileLoaded) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: SizedBox.shrink(),
          );
        }

        final isPremium = profileState.profile.isPremium;
        _ensureHomeSnapCubit(profileState.profile.id);

        return BlocProvider(
          create: (context) {
            final cubit = HomeScreenCubit();
            cubit.startAutoScroll(_animateCarousel);
            return cubit;
          },
          child: BlocProvider(
            create: (context) =>
                HomeAnalyticsCubit(context.read<SpaceService>())
                  ..loadAnalytics(),
            child: Scaffold(
              backgroundColor: AppTheme.background,
              body: SafeArea(
                child: Column(
                  children: [
                    const _StickyHeaderBar(),
                    Expanded(
                      child: BlocBuilder<HomeScreenCubit, HomeScreenState>(
                        builder: (context, homeState) {
                          return BlocBuilder<
                            SoloDashboardCubit,
                            SoloDashboardState
                          >(
                            builder: (context, dashState) {
                              return BlocBuilder<
                                GroupDashboardCubit,
                                GroupDashboardState
                              >(
                                builder: (context, groupState) {
                                  return BlocBuilder<
                                    DiscoverCubit,
                                    DiscoverState
                                  >(
                                    builder: (context, discoverState) {
                                      return CustomScrollView(
                                        controller: _scrollController,
                                        cacheExtent: 500,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                              parent: BouncingScrollPhysics(),
                                            ),
                                        slivers: [
                                          SliverToBoxAdapter(
                                            child: _buildTodayTabContent(
                                              context,
                                              dashState,
                                              groupState,
                                            ),
                                          ),
                                          SliverToBoxAdapter(
                                            child: const HomeAnalyticsCard(),
                                          ),
                                          SliverToBoxAdapter(
                                            child: Builder(
                                              builder: (context) {
                                                final snapCubit = _homeSnapCubit;
                                                if (snapCubit == null ||
                                                    _homeSnapUserId == null) {
                                                  return const SizedBox.shrink();
                                                }

                                                final soloHabits =
                                                    dashState
                                                            is SoloDashboardLoaded
                                                        ? dashState.data.habits
                                                        : <DashboardHabit>[];
                                                final groupHabits =
                                                  groupState
                                                          is GroupDashboardLoaded
                                                      ? groupState.data.habits
                                                      : <DashboardHabit>[];

                                              return BlocBuilder<
                                                SpacesCubit,
                                                SpacesState
                                              >(
                                                builder: (
                                                  context,
                                                  spacesState,
                                                ) {
                                                  bool hasEligibleSpaces =
                                                      false;
                                                  if (spacesState
                                                      is SpacesLoaded) {
                                                    hasEligibleSpaces =
                                                        spacesState
                                                            .coupleSpaces
                                                            .isNotEmpty ||
                                                        spacesState
                                                            .groupSpaces
                                                            .isNotEmpty;
                                                  }
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          16,
                                                          8,
                                                          16,
                                                          8,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.fromLTRB(
                                                                8,
                                                                0,
                                                                8,
                                                                10,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Stories',
                                                                style: GoogleFonts.plusJakartaSans(
                                                                  fontSize: 17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      AppTheme
                                                                          .onBackground,
                                                                  letterSpacing:
                                                                      -0.3,
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              if (hasEligibleSpaces)
                                                                Text(
                                                                  'Fresh updates',
                                                                  style: GoogleFonts.inter(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        AppTheme
                                                                            .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        BlocProvider<
                                                          SnapCubit
                                                        >.value(
                                                          value: snapCubit,
                                                          child: SnapFeedWidget(
                                                            spaceId:
                                                                '00000000-0000-0000-0000-000000000000',
                                                            currentUserId:
                                                                _homeSnapUserId!,
                                                            habits: [
                                                              ...soloHabits,
                                                              ...groupHabits,
                                                            ],
                                                            isHomeContext: true,
                                                            hasSpaces:
                                                                hasEligibleSpaces,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: HomeBrandSection(
                                            section: _homeBrandSection,
                                            isLoading: _isBrandSectionLoading,
                                            onOpenCard: _openBrandChallenge,
                                            onShowMoreBrandDrops:
                                                widget.onOpenBrandDropsAll ??
                                                () {},
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: ActivePeopleSection(),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 100),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _buildTodayTabContent(
    BuildContext context,
    SoloDashboardState dashState,
    GroupDashboardState groupState,
  ) {
    if (dashState is SoloDashboardLoading) return const SizedBox.shrink();
    if (dashState is! SoloDashboardLoaded) return const SizedBox.shrink();

    final allEndedHabits = _collectAllEndedHabits(
      context,
      dashState,
      groupState,
    );
    final groupHabits =
        groupState is GroupDashboardLoaded
            ? groupState.data.habits
            : <DashboardHabit>[];
    final hasAnyHabits =
        dashState.data.habits.isNotEmpty || groupHabits.isNotEmpty;

    if (!hasAnyHabits && allEndedHabits.isEmpty) return const EmptyTodayGuide();
    if (allEndedHabits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5C4AE4), Color(0xFF4ECDC4)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Challenge Results',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16 * Responsive.scale(context),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.onBackground.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${allEndedHabits.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children:
                allEndedHabits
                    .map(
                      (ended) => ChallengeResultCard(
                        key: ValueKey('home_ended_${ended.id}'),
                        habit: ended,
                        onDismiss: () => _dismissEndedHabit(context, ended),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<EndedHabit> _collectAllEndedHabits(
    BuildContext context,
    SoloDashboardLoaded soloState,
    GroupDashboardState groupState,
  ) {
    final Map<String, EndedHabit> byId = {};
    for (final h in soloState.data.endedHabits) byId[h.id] = h;
    try {
      final coupleState = context.read<CoupleDashboardCubit>().state;
      if (coupleState is CoupleDashboardLoaded) {
        for (final h in coupleState.data.endedHabits) byId[h.id] = h;
      }
    } catch (_) {}
    if (groupState is GroupDashboardLoaded) {
      for (final h in groupState.data.endedHabits) byId[h.id] = h;
    }
    return byId.values.toList()..sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? -1 : 1;
      return a.name.compareTo(b.name);
    });
  }

  void _dismissEndedHabit(BuildContext context, EndedHabit habit) {
    if (habit.isCouple) {
      try {
        context.read<CoupleDashboardCubit>().dismissChallengeResult(habit.id);
      } catch (_) {
        context.read<SoloDashboardCubit>().dismissChallengeResult(habit.id);
      }
    } else if (habit.isGroup) {
      try {
        context.read<GroupDashboardCubit>().dismissChallengeResult(habit.id);
      } catch (_) {
        context.read<SoloDashboardCubit>().dismissChallengeResult(habit.id);
      }
    } else {
      context.read<SoloDashboardCubit>().dismissChallengeResult(habit.id);
    }
  }

  Widget _buildHeroCarousel(
    BuildContext context,
    SoloDashboardState dashState,
    GroupDashboardState groupState,
    bool isPremium,
  ) {
    int scheduled = 0, completed = 0, remaining = 0;
    if (dashState is SoloDashboardLoaded) {
      final habits = dashState.data.habits;
      scheduled = habits.where((h) => h.isScheduledToday).length;
      completed =
          habits.where((h) => h.isScheduledToday && h.isDoneToday).length;
      remaining = (scheduled - completed).clamp(0, scheduled);
    }

    final s = Responsive.scale(context);
    return SizedBox(
      height: 135 * s,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Stack(
          children: [
            dashState is SoloDashboardLoading
                ? HeroCarouselCards.buildShimmerCard()
                : TodayProgressWidget(
                  totalScheduled: scheduled,
                  completed: completed,
                  remaining: remaining,
                ),
            _buildSpaceTag('Solo', const Color(0xFF5C4AE4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceTag(String label, Color color) {
    return Positioned(
      bottom: 12,
      right: 16,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildPageIndicator(HomeScreenState homeState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(HomeScreenCubit.carouselCount, (i) {
        final isActive = homeState.activeCarouselPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color:
                isActive
                    ? AppTheme.onBackground
                    : AppTheme.onSurfaceVariant.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Warning item + Join sheet + Paywall (same as before) ───────────────────
class _WarningItem {
  final String icon;
  final Color color;
  final String text;
  _WarningItem({required this.icon, required this.color, required this.text});
}

class _JoinBottomSheet extends StatelessWidget {
  final DiscoverSpace space;
  final List<_WarningItem> warnings;
  const _JoinBottomSheet({required this.space, required this.warnings});

  @override
  Widget build(BuildContext context) {
    final isCouple = space.spaceType == 'couple';
    final hasRedWarning = warnings.any((w) => w.color == Colors.red);
    final hasWarning = warnings.isNotEmpty;
    final buttonText =
        hasRedWarning
            ? 'I understand, Send Request'
            : hasWarning
            ? 'Yes, Send Request'
            : 'Send Request';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCouple ? Icons.favorite : Icons.groups_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.spaceName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCouple ? 'Couple Space' : 'Group Space',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${space.memberCount} / ${space.memberLimit} · ${space.memberLimit - space.memberCount} spots left',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (space.habitPreviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Habits',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (final habit in space.habitPreviews)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              habit.emoji ?? '⚡',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                                if (habit.isChallenge)
                                  Text(
                                    'Challenge Habit',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentAmber,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (var w in warnings)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: w.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(w.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context, {'proceed': true}),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: hasRedWarning ? Colors.red : null,
                gradient:
                    hasRedWarning
                        ? null
                        : const LinearGradient(
                          colors: [Color(0xFF5C4AE4), Color(0xFF7B6EF6)],
                        ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                buttonText,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context, {'proceed': false}),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumPaywallSheet extends StatelessWidget {
  const PremiumPaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Premium Feature',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Premium to join spaces and connect with others.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C4AE4), Color(0xFF7B6EF6)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Upgrade to Premium',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Maybe later',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky header bar (App Bar) ─────────────────────────────────────────────
class _StickyHeaderBar extends StatelessWidget {
  const _StickyHeaderBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, ps) {
        if (ps is! ProfileLoaded) {
          return const SizedBox.shrink();
        }

        return StickyActionButtons(
          spaceType: SpaceType.solo,
          profile: ps.profile,
          displayUrl: ps.displayUrl,
          scrollController: ScrollController(),
        );
      },
    );
  }
}
