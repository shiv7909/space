import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_helpers.dart';
import '../../models/dashboard_model.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/cubit/profile_state.dart';
import '../../models/user_model.dart';
import '../../models/space_model.dart';
import '../../services/space_service.dart';
import '../../services/profile_service.dart';
import 'cubit/spaces_cubit.dart';
import 'cubit/spaces_state.dart';
import 'cubit/couple_dashboard_cubit.dart';
import 'cubit/couple_dashboard_state.dart';
import '../spaces/widgets/create_space_dialog.dart';
import '../spaces/widgets/premium_required_dialog.dart';
import '../shared/sticky_action_buttons.dart';
import '../spaces/widgets/join_space_popup.dart';
import '../spaces/widgets/add_member_dialog.dart';
import '../spaces/widgets/manage_members_sheet.dart';
import '../habits/widgets/add_habit_sheet.dart';
import 'widgets/couple_habit_detail_view.dart';
import '../solo/widgets/smart_feed_card.dart';
import '../solo/widgets/sticky_header_banner.dart';
import '../solo/widgets/challenge_result_card.dart';
import '../qr/qr_scanner_view.dart';
import 'widgets/couple_habit_card.dart';
import '../invites/cubit/invite_cubit.dart';
import '../invites/cubit/invite_state.dart';

class CoupleSpaceView extends StatefulWidget {
  final bool showAppBar;
  final void Function(int total, int scheduled, int completed)? onStatsUpdate;
  const CoupleSpaceView({
    super.key,
    this.showAppBar = true,
    this.onStatsUpdate,
  });

  @override
  State<CoupleSpaceView> createState() => _CoupleSpaceViewState();
}

class _CoupleSpaceViewState extends State<CoupleSpaceView>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _labelController;
  late Animation<double> _labelWidth;
  late Animation<double> _labelOpacity;
  bool _labelAnimationTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _labelWidth = CurvedAnimation(
      parent: _labelController,
      curve: Curves.easeInOut,
    );
    _labelOpacity = CurvedAnimation(
      parent: _labelController,
      curve: Curves.easeIn,
    );
  }

  void _triggerLabelCollapseIfNeeded() {
    if (_labelAnimationTriggered || !mounted || _labelController.isAnimating)
      return;
    _labelAnimationTriggered = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_labelController.isAnimating) {
        _labelController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'first_completion':
        return '🌱';
      case 'comeback':
        return '💪';
      case 'milestone':
        return '🏆';
      case 'personal_best':
        return '⭐';
      case 'challenge_complete':
        return '🎯';
      case 'streak_progress':
      default:
        return '🔥';
    }
  }

  void _openAddHabit(BuildContext context, String spaceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitSheet(spaceId: spaceId),
    ).then((result) {
      if (result == true && context.mounted) {
        try {
          context.read<CoupleDashboardCubit>().refreshDashboard();
        } catch (_) {}
      }
    });
  }

  Widget _buildAnimatedAddButton(BuildContext context, String spaceId) {
    return GestureDetector(
      onTap: () => _openAddHabit(context, spaceId),
      child: AnimatedBuilder(
        animation: _labelController,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.onBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1.0 - _labelWidth.value,
                    child: FadeTransition(
                      opacity: ReverseAnimation(_labelOpacity),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 5),
                          Text(
                            'New Habit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Leave space confirmation ─────────────────────────────────────────
  void _showLeaveSpaceDialog(BuildContext context, SpaceModel space) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Leave Space',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to leave "${space.name}"? You\'ll need a new invite to rejoin.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<SpacesCubit>().leaveSpace(space.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Leave',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ─── Delete space confirmation ────────────────────────────────────────
  void _showDeleteSpaceDialog(BuildContext context, SpaceModel space) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.accentRed,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Space',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'This will permanently delete "${space.name}" and all its habits. This action cannot be undone.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<SpacesCubit>().deleteSpace(space.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        if (profileState is! ProfileLoaded) {
          return const Center(child: Text('Please log in'));
        }
        final profile = profileState.profile;
        final avatarUrl = profileState.avatarUrl;
        final isPremium = profile.isPremium;

        return BlocProvider(
          create:
              (context) => SpacesCubit(
                spaceService: context.read(),
                userId: profile.id,
                inviteCubit: context.read<InviteCubit>(),
              )..loadSpaces(),
          child: BlocListener<SpacesCubit, SpacesState>(
            listenWhen: (_, s) => s is SpacesLoaded,
            listener: (context, state) {
              if (state is SpacesLoaded && state.coupleSpaces.isNotEmpty) {
                final cubit = context.read<CoupleDashboardCubit>();
                final spaceId = state.coupleSpaces.first.id;
                if (cubit.activeSpaceId != spaceId) {
                  cubit.loadDashboard(spaceId: spaceId);
                }
              }
            },
            child: Scaffold(
              backgroundColor: AppTheme.background,
              body: SafeArea(
                top: widget.showAppBar,
                child: Column(
                  children: [
                    // ── App bar (hidden when embedded in HabitsHubScreen) ──
                    if (widget.showAppBar)
                      BlocBuilder<ProfileCubit, ProfileState>(
                        builder: (context, ps) {
                          final p = ps is ProfileLoaded ? ps.profile : profile;
                          final d =
                              ps is ProfileLoaded ? ps.displayUrl : avatarUrl;
                          return StickyActionButtons(
                            spaceType: SpaceType.couple,
                            profile: p,
                            displayUrl: d,
                            scrollController: _scrollController,
                          );
                        },
                      ),
                    // ── Body ──
                    Expanded(
                      child: BlocBuilder<SpacesCubit, SpacesState>(
                        builder: (context, spacesState) {
                          if (spacesState is SpacesLoading) {
                            return const SizedBox.shrink();
                          }
                          if (spacesState is SpacesLoaded) {
                            final coupleSpaces = spacesState.coupleSpaces;
                            if (coupleSpaces.isEmpty) {
                              return _buildEmptyState(context, isPremium);
                            }
                            final activeSpace = coupleSpaces.first;
                            return _buildDuoDashboard(
                              context,
                              activeSpace,
                              profile.id,
                              isPremium,
                            );
                          }
                          if (spacesState is SpacesError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 56,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      spacesState.message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppTheme.accentRed,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed:
                                          () =>
                                              context
                                                  .read<SpacesCubit>()
                                                  .loadSpaces(),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return _buildEmptyState(context, isPremium);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── DUO DASHBOARD — full dashboard like solo ────────���────────────────
  Widget _buildDuoDashboard(
    BuildContext context,
    SpaceModel space,
    String userId,
    bool isPremium,
  ) {
    final isOwner = space.createdBy == userId;
    final coupleCubit = context.read<CoupleDashboardCubit>();
    if (coupleCubit.activeSpaceId != space.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) coupleCubit.loadDashboard(spaceId: space.id);
      });
    }
    return BlocConsumer<CoupleDashboardCubit, CoupleDashboardState>(
      listener: (context, state) {
        if (state is CoupleDashboardHabitCompleted) {
          final emoji = _categoryEmoji(state.category);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.completionMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: AppTheme.onBackground,
            ),
          );
        }
      },
      buildWhen: (prev, next) {
        if (next is CoupleDashboardRefreshing &&
            prev is CoupleDashboardLoaded) {
          return false;
        }
        return true;
      },
      builder: (context, dashboardState) {
        final effectiveState =
            dashboardState is CoupleDashboardRefreshing
                ? CoupleDashboardLoaded(data: dashboardState.data)
                : dashboardState;

        if (effectiveState is CoupleDashboardLoading) {
          return const SizedBox.shrink();
        }
        if (effectiveState is CoupleDashboardError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    effectiveState.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        () => context
                            .read<CoupleDashboardCubit>()
                            .loadDashboard(spaceId: space.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (effectiveState is CoupleDashboardLoaded) {
          final liveHabitCount = effectiveState.data.habits.length;
          return _buildLoadedDashboard(
            context,
            effectiveState,
            space,
            isPremium,
            isOwner,
            liveHabitCount,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─── Loaded dashboard — fully lazy CustomScrollView ───────────────────
  Widget _buildLoadedDashboard(
    BuildContext context,
    CoupleDashboardLoaded state,
    SpaceModel space,
    bool isPremium,
    bool isOwner,
    int liveHabitCount,
  ) {
    final isNoPartner = state.data.status == 'no_partner';
    final isError = state.data.status == 'error';

    // Allow habits even without a partner!
    final all = isError ? <DashboardHabit>[] : state.data.habits;
    final pending =
        all.where((h) => h.isScheduledToday && !h.isDoneToday).toList();
    final completed =
        all.where((h) => h.isScheduledToday && h.isDoneToday).toList();
    final rest = all.where((h) => !h.isScheduledToday).toList();
    final sorted = [...pending, ...completed, ...rest];

    final scheduledToday = pending.length + completed.length;
    final completedToday = completed.length;

    final isEmpty = sorted.isEmpty;
    final hasAlerts = state.data.alerts.isNotEmpty && !isEmpty;
    final hasBanner = state.data.stickyHeader != null && !isEmpty;
    // Trigger label collapse once list is ready
    if (!isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.onStatsUpdate != null) {
          widget.onStatsUpdate!(all.length, scheduledToday, completedToday);
        }
        _triggerLabelCollapseIfNeeded();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.onStatsUpdate != null) {
          widget.onStatsUpdate!(0, 0, 0);
        }
      });
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 600,
      slivers: [
        // ── Pull-to-refresh ──
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await context.read<CoupleDashboardCubit>().refreshDashboard();
          },
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              // ── ALWAYS show Duo space header banner ──
              _buildDuoSpaceBanner(context, space, isOwner, liveHabitCount),
              // ── Error inline ──
              if (isError) _buildErrorContentInline(context, state, space),

              // ── Empty state: no habits yet ──
              if (!isError && isEmpty)
                _buildNoHabitsContentInline(
                  context,
                  space,
                  isNoPartner,
                  isPremium,
                  isOwner,
                ),

              // ── Ended challenge result cards ──
              if (state.data.endedHabits.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.onBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Challenge Results',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onBackground,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...state.data.endedHabits.map(
                  (ended) => ChallengeResultCard(
                    key: ValueKey('ended_${ended.id}'),
                    habit: ended,
                    onDismiss:
                        () => context
                            .read<CoupleDashboardCubit>()
                            .dismissChallengeResult(ended.id),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Alerts carousel
              if (hasAlerts) ...[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.data.alerts.length,
                    itemBuilder: (context, i) {
                      final alert = state.data.alerts[i];
                      return SmartFeedCard(
                        alert: alert,
                        onDismiss:
                            () => context
                                .read<CoupleDashboardCubit>()
                                .dismissAlert(alert.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Sticky banner
              if (hasBanner) ...[
                StickyHeaderBanner(header: state.data.stickyHeader!),
                const SizedBox(height: 12),
              ],

              // "Duo Habits" header — only when we have habits
              if (!isEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Duo Routine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17 * Responsive.scale(context),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (isOwner) _buildAnimatedAddButton(context, space.id),
                  ],
                ),
              if (!isEmpty) const SizedBox(height: 16),
            ]),
          ),
        ),

        // ── Habit list (only when there are habits) ──
        if (!isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final habit = sorted[index];
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CoupleHabitCard(
                        key: ValueKey(habit.id),
                        habit: habit,
                        index: index,
                        isLast: index == sorted.length - 1,
                        onMarkDone:
                            () async => await context
                                .read<CoupleDashboardCubit>()
                                .completeHabit(habit.id),
                        onTap: () async {
                          // ✅ Read cubit + service BEFORE creating the route
                          final cubit = context.read<CoupleDashboardCubit>();
                          final spaceService = context.read<SpaceService>();
                          final uid =
                              context.read<ProfileCubit>().state
                                      is ProfileLoaded
                                  ? (context.read<ProfileCubit>().state
                                          as ProfileLoaded)
                                      .profile
                                      .id
                                  : '';

                          // Mark nudges as seen when opening the detail view
                          if (uid.isNotEmpty) {
                            spaceService.markNudgesSeen(
                              habitId: habit.id,
                              userId: uid,
                            );
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (ctx) => CoupleHabitDetailView(
                                    habit: habit,
                                    // ✅ Pass the cubit method directly, not trying to read from new context
                                    onMarkDone:
                                        () async =>
                                            await cubit.completeHabit(habit.id),
                                  ),
                            ),
                          );
                          if (result == 'updated' || result == 'deleted') {
                            if (context.mounted) {
                              cubit.loadDashboard(spaceId: space.id);
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
                childCount: sorted.length,
                addRepaintBoundaries: false,
                addAutomaticKeepAlives: false,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Duo space banner — clean, minimal, no card/shadow ────────────────
  Widget _buildDuoSpaceBanner(
    BuildContext context,
    SpaceModel space,
    bool isOwner,
    int liveHabitCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row: name + actions ──
        FutureBuilder<int>(
          future: context.read<SpaceService>().getSpaceMemberCount(space.id),
          initialData: space.stats.membersCount,
          builder: (context, snapshot) {
            final memberCount = snapshot.data ?? space.stats.membersCount;
            final canAddMembers = memberCount < 2;
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17 * Responsive.scale(context),
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isOwner ? 'You created this space' : 'Member',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    final habitInfoList = [
                      for (var i = 0; i < liveHabitCount; i++)
                        <String, String>{},
                    ];
                    // Build real habit info from CoupleDashboardCubit
                    List<Map<String, String>>? habits;
                    try {
                      final dashState =
                          context.read<CoupleDashboardCubit>().state;
                      if (dashState is CoupleDashboardLoaded) {
                        habits =
                            dashState.data.habits
                                .map((h) => {'emoji': h.emoji, 'name': h.name})
                                .toList();
                      }
                    } catch (_) {}
                    final resolvedHabits = habits ?? habitInfoList;

                    if (value == 'add_member') {
                      _showAddMemberOptions(context, space);
                    } else if (value == 'manage_members') {
                      _showManageMembersSheet(
                        context,
                        space,
                        isReadOnly: false,
                        habitInfoList: resolvedHabits,
                      );
                    } else if (value == 'view_members') {
                      _showManageMembersSheet(
                        context,
                        space,
                        isReadOnly: true,
                        habitInfoList: resolvedHabits,
                      );
                    } else if (value == 'delete') {
                      _showDeleteSpaceDialog(context, space);
                    } else if (value == 'leave' && !isOwner) {
                      _showLeaveSpaceDialog(context, space);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black12,
                  offset: const Offset(0, 40),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: AppTheme.onSurfaceVariant,
                    size: 22,
                  ),
                  itemBuilder:
                      (context) => [
                        if (canAddMembers && isOwner)
                          PopupMenuItem<String>(
                            value: 'add_member',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 18,
                                  color: AppTheme.onBackground,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Invite Partner',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isOwner)
                          PopupMenuItem<String>(
                            value: 'manage_members',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.manage_accounts_rounded,
                                  size: 18,
                                  color: AppTheme.onBackground,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Space Overview',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isOwner)
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppTheme.accentRed,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Delete Space',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isOwner)
                          PopupMenuItem<String>(
                            value: 'view_members',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppTheme.onBackground,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Space Overview',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isOwner)
                          PopupMenuItem<String>(
                            value: 'leave',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.exit_to_app_rounded,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Leave Space',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ─── Error content (inline, below space banner) ───────────────────────
  Widget _buildErrorContentInline(
    BuildContext context,
    CoupleDashboardLoaded state,
    SpaceModel space,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Couldn\'t Load Dashboard',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.data.statusMessage ??
                'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed:
                  () => context.read<CoupleDashboardCubit>().loadDashboard(
                    spaceId: space.id,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.onBackground,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── No habits content (inline, below space banner) ───────���───────────
  // Owner: shows "Add First Habit" button
  // Member: shows "Ask [owner] to add habits to grow together"
  Widget _buildNoHabitsContentInline(
    BuildContext context,
    SpaceModel space,
    bool isNoPartner,
    bool isPremium,
    bool isOwner,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        children: [
          SizedBox(
            width: 160 * Responsive.scale(context),
            height: 160 * Responsive.scale(context),
            child: DotLottieLoader.fromAsset(
              'assets/LottieAnimations/COUPLEaNI.lottie',
              frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                if (dotlottie != null) {
                  return Lottie.memory(dotlottie.animations.values.single);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isOwner ? 'Start Your Duo Journey' : 'No Habits Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22 * Responsive.scale(context),
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // ── Owner: show add-habit messaging ──
          if (isOwner) ...[
            Text(
              isNoPartner
                  ? 'Add habits now and invite your\npartner when they\'re ready.'
                  : 'You\'re all set! Add your first\nshared habit and grow together.',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 15 * Responsive.scale(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Primary: Add Habit button (owner only)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openAddHabit(context, space.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.onBackground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add First Habit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Member: show "ask owner to add habits" ──
          if (!isOwner) ...[
            FutureBuilder<String>(
              future: _fetchOwnerName(context, space.createdBy),
              builder: (context, snapshot) {
                final ownerName = snapshot.data ?? 'your partner';
                return Column(
                  children: [
                    Text(
                      'Ask $ownerName to add habits\nso you can grow together 💕',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Subtle info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFFF6B6B),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Only the space creator can add new habits. Once added, you\'ll both be able to track them!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          // Secondary: Check Invites button (non-premium users who are owners)
          if (isOwner && !isNoPartner && !isPremium) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pushNamed(context, '/activity');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.onBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: BorderSide(color: AppTheme.outline, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Check Pending Invites',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16 * Responsive.scale(context),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Fetch the owner's display name by userId
  Future<String> _fetchOwnerName(BuildContext context, String ownerId) async {
    try {
      final profileService = context.read<ProfileService>();
      final profile = await profileService.getProfile(ownerId);
      return profile?.displayName ?? 'your partner';
    } catch (_) {
      return 'your partner';
    }
  }

  // ─── Empty state (no couple space exists) ─────────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isPremium) {
    if (!isPremium) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              if (context.mounted) {
                context.read<InviteCubit>().loadInvites();
              }
            },
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240 * Responsive.scale(context),
                    height: 240 * Responsive.scale(context),
                    child: DotLottieLoader.fromAsset(
                      'assets/LottieAnimations/COUPLEaNI.lottie',
                      frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                        if (dotlottie != null) {
                          return Lottie.memory(
                            dotlottie.animations.values.single,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Duo Space ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22 * Responsive.scale(context),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                      letterSpacing: -1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Been invited to a Duo space? Check your\npending invites below. Want to create your\nown? Upgrade to Premium.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 15 * Responsive.scale(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary: Check Pending Invites — with live badge
                  BlocBuilder<InviteCubit, InviteState>(
                    builder: (context, inviteState) {
                      final count =
                          inviteState is InviteLoaded ? inviteState.count : 0;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/activity');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.onBackground,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.mail_outline_rounded, size: 22),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  count > 0
                                      ? 'CHECK INVITES ($count pending)'
                                      : 'CHECK INVITES',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16 * Responsive.scale(context),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Secondary: Go Premium to create your own
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton(
                      onPressed:
                          () => _showCreateSpaceDialog(context, isPremium),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.onBackground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide(color: AppTheme.outline, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'GO PREMIUM TO CREATE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16 * Responsive.scale(context),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final profileState = context.read<ProfileCubit>().state as ProfileLoaded;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            if (context.mounted) {
              context.read<InviteCubit>().loadInvites();
            }
          },
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200 * Responsive.scale(context),
                  height: 200 * Responsive.scale(context),
                  child: DotLottieLoader.fromAsset(
                    'assets/LottieAnimations/COUPLEaNI.lottie',
                    frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                      if (dotlottie != null) {
                        return Lottie.memory(
                          dotlottie.animations.values.single,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Text(
                  'Power Couple Mode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21 * Responsive.scale(context),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onBackground,
                    letterSpacing: -1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sync up and level up. Start a duo\nspace with your favorite person.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 14 * Responsive.scale(context),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () => _showCreateSpaceDialog(context, isPremium),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_border, size: 22),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'START A DUO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16 * Responsive.scale(context),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // JOIN A DUO + CHECK INVITES side by side
                BlocBuilder<InviteCubit, InviteState>(
                  builder: (context, inviteState) {
                    final count =
                        inviteState is InviteLoaded ? inviteState.count : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  () => _showJoinSpacePopup(
                                    context,
                                    profileState,
                                  ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.onBackground,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                side: BorderSide(
                                  color: AppTheme.outline,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.qr_code, size: 24),
                                  const SizedBox(height: 6),
                                  Text(
                                    'JOIN A DUO',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13 * Responsive.scale(context),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/activity');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.onBackground,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                side: BorderSide(
                                  color: AppTheme.outline,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    count > 0
                                        ? 'INVITES ($count)'
                                        : 'CHECK INVITES',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13 * Responsive.scale(context),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showJoinSpacePopup(BuildContext context, ProfileLoaded profileState) {
    final tempUser = UserModel(
      id: profileState.profile.id,
      email: '',
      displayName: profileState.profile.displayName,
      avatarUrl: profileState.displayUrl,
      createdAt: profileState.profile.updatedAt,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => JoinSpacePopup(
            user: tempUser,
            avatarUrl: profileState.displayUrl,
          ),
    );
  }

  void _showCreateSpaceDialog(BuildContext context, bool isPremium) {
    if (!isPremium) {
      showDialog(
        context: context,
        builder:
            (context) =>
                const PremiumRequiredDialog(featureName: 'Create Duo Space'),
      );
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder:
          (_) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider.value(value: context.read<SpaceService>()),
              RepositoryProvider.value(value: context.read<ProfileCubit>()),
            ],
            child: CreateSpaceSheet(
              spaceType: 'couple',
              onSpaceCreated: () => context.read<SpacesCubit>().loadSpaces(),
            ),
          ),
    ).then((created) {
      if (created == true && context.mounted) {
        context.read<SpacesCubit>().loadSpaces();
      }
    });
  }

  void _showAddMemberOptions(BuildContext context, SpaceModel space) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invite Your Partner',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),

              // QR Code Scanner
              GestureDetector(
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (parentContext.mounted) {
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (context) => QRScannerView(spaceId: space.id),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFFFF6B6B),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scan QR Code',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onBackground,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Email Invite
              if (parentContext.read<ProfileCubit>().state is ProfileLoaded)
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (!parentContext.mounted) return;
                    final result =
                        await showModalBottomSheet<Map<String, dynamic>>(
                          context: parentContext,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddMemberDialog(spaceId: space.id),
                        );
                    if (result != null &&
                        result['success'] == true &&
                        parentContext.mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result['message'] as String? ??
                                      'Member added successfully!',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                      try {
                        parentContext.read<SpacesCubit>().loadSpaces();
                        parentContext
                            .read<CoupleDashboardCubit>()
                            .refreshDashboard();
                      } catch (_) {}
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.email_rounded,
                              color: Color(0xFF4CAF50),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Invite via Email',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onBackground,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCreateSpaceDialog(parentContext, false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.accentRed,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Upgrade to Premium to Invite via Email',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onBackground,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(
                height: MediaQuery.of(sheetContext).viewPadding.bottom + 8,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Manage Members sheet (owner-only) ────────────────────────────────
  void _showManageMembersSheet(
    BuildContext context,
    SpaceModel space, {
    bool isReadOnly = false,
    List<Map<String, String>>? habitInfoList,
  }) {
    final profileState = context.read<ProfileCubit>().state;
    final currentUserId =
        profileState is ProfileLoaded ? profileState.profile.id : '';
    final spacesCubit = context.read<SpacesCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ManageMembersSheet(
            space: space,
            currentUserId: currentUserId,
            spacesCubit: spacesCubit,
            isReadOnly: isReadOnly,
            habitInfoList: habitInfoList,
          ),
    );
  }
}
