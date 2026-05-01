import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_helpers.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/cubit/profile_state.dart';
import '../../models/user_model.dart';
import '../../models/space_model.dart';
import '../../services/space_service.dart';
import '../couple/cubit/spaces_cubit.dart';
import '../couple/cubit/spaces_state.dart';
import '../spaces/widgets/create_space_dialog.dart';
import '../spaces/widgets/premium_required_dialog.dart';
import '../shared/sticky_action_buttons.dart';
import '../spaces/widgets/join_space_popup.dart';
import 'widgets/group_habit_card.dart';
import '../spaces/widgets/add_member_dialog.dart';
import '../spaces/widgets/manage_members_sheet.dart';
import '../habits/widgets/add_habit_sheet.dart';
import 'widgets/group_habit_detail_view.dart';
import 'cubit/group_dashboard_cubit.dart';
import 'cubit/group_dashboard_state.dart';
import '../invites/cubit/invite_cubit.dart';
import '../invites/cubit/invite_state.dart';
import '../solo/widgets/today_progress_widget.dart';
import '../solo/widgets/challenge_result_card.dart';
import '../solo/widgets/smart_feed_card.dart';
import '../solo/widgets/sticky_header_banner.dart';

class GroupSpaceView extends StatefulWidget {
  final bool showAppBar;
  final void Function(int total, int scheduled, int completed)? onStatsUpdate;
  const GroupSpaceView({super.key, this.showAppBar = true, this.onStatsUpdate});

  @override
  State<GroupSpaceView> createState() => _GroupSpaceViewState();
}

class _GroupSpaceViewState extends State<GroupSpaceView>
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

  // ── Open AddHabitSheet for the group space ──
  void _openAddHabit(BuildContext context, String spaceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitSheet(spaceId: spaceId),
    ).then((result) {
      if (result == true && context.mounted) {
        try {
          context.read<GroupDashboardCubit>().refreshDashboard(
            spaceId: spaceId,
          );
        } catch (_) {}
      }
    });
  }

  // ── Animated pill button — label collapses to icon after 1.5 s ──
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
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: BlocBuilder<SpacesCubit, SpacesState>(
              builder: (context, spacesState) {
                return SafeArea(
                  top: widget.showAppBar,
                  child: Column(
                    children: [
                      if (widget.showAppBar)
                        BlocBuilder<ProfileCubit, ProfileState>(
                          builder: (context, profileState) {
                            final currentProfile =
                                profileState is ProfileLoaded
                                    ? profileState.profile
                                    : profile;
                            final currentAvatarUrl =
                                profileState is ProfileLoaded
                                    ? profileState.avatarUrl
                                    : avatarUrl;
                            return StickyActionButtons(
                              spaceType: SpaceType.group,
                              profile: currentProfile,
                              displayUrl:
                                  profileState is ProfileLoaded
                                      ? profileState.displayUrl
                                      : currentAvatarUrl,
                              scrollController: _scrollController,
                            );
                          },
                        ),
                      Expanded(
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          cacheExtent: 600,
                          slivers: [
                            // ── Pull-to-refresh ──
                            CupertinoSliverRefreshControl(
                              onRefresh: () {
                                final cubit =
                                    context.read<GroupDashboardCubit>();
                                final spacesCubit = context.read<SpacesCubit>();
                                final state = spacesCubit.state;
                                if (state is SpacesLoaded &&
                                    state.groupSpaces.isNotEmpty) {
                                  final activeSpace = state.groupSpaces.first;
                                  return cubit.refreshDashboard(
                                    spaceId: activeSpace.id,
                                  );
                                }
                                return Future.value();
                              },
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16.0,
                                8.0,
                                16.0,
                                120.0,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  BlocBuilder<SpacesCubit, SpacesState>(
                                    builder: (context, state) {
                                      if (state is SpacesLoading) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(40.0),
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF6B6BE0),
                                            ),
                                          ),
                                        );
                                      }

                                      if (state is SpacesError) {
                                        return Center(
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                size: 64,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                state.message,
                                                textAlign: TextAlign.center,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      color: Colors.red,
                                                    ),
                                              ),
                                              const SizedBox(height: 16),
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
                                        );
                                      }

                                      if (state is SpacesLoaded) {
                                        final groupSpaces = state.groupSpaces;
                                        if (groupSpaces.isEmpty)
                                          return _buildEmptyState(
                                            context,
                                            isPremium,
                                          );

                                        final activeSpace = groupSpaces.first;
                                        final isCreator =
                                            activeSpace.createdBy == profile.id;

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            MultiBlocProvider(
                                              providers: [
                                                BlocProvider(
                                                  create:
                                                      (context) =>
                                                          GroupDashboardCubit(
                                                            context
                                                                .read<
                                                                  SpaceService
                                                                >(),
                                                            userId: profile.id,
                                                          )..loadDashboard(
                                                            spaceId:
                                                                activeSpace.id,
                                                          ),
                                                ),
                                              ],
                                              child: BlocBuilder<
                                                GroupDashboardCubit,
                                                GroupDashboardState
                                              >(
                                                builder: (
                                                  context,
                                                  dashboardState,
                                                ) {
                                                  final hasHabits =
                                                      dashboardState
                                                          is GroupDashboardLoaded &&
                                                      dashboardState
                                                          .data
                                                          .habits
                                                          .isNotEmpty;
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildGroupSpaceBanner(
                                                        context,
                                                        activeSpace,
                                                        isCreator,
                                                        hasHabits: hasHabits,
                                                      ),
                                                      // const SizedBox(
                                                      //   height: 12,
                                                      // ),
                                                      if (dashboardState
                                                          is GroupDashboardLoading)
                                                        const Center(
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  32.0,
                                                                ),
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color: Color(
                                                                    0xFF8B5CF6,
                                                                  ),
                                                                ),
                                                          ),
                                                        )
                                                      else if (dashboardState
                                                          is GroupDashboardError)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                24,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Error loading habits: ${dashboardState.message}',
                                                            style:
                                                                GoogleFonts.plusJakartaSans(
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                          ),
                                                        )
                                                      else if (dashboardState
                                                          is GroupDashboardLoaded) ...[
                                                        Builder(
                                                          builder: (context) {
                                                            final habits =
                                                                dashboardState
                                                                    .data
                                                                    .habits;
                                                            WidgetsBinding
                                                                .instance
                                                                .addPostFrameCallback(
                                                                  (_) =>
                                                                      _triggerLabelCollapseIfNeeded(),
                                                                );
                                                            if (habits.isEmpty)
                                                              return _buildNoHabitsView(
                                                                context,
                                                                activeSpace.id,
                                                                isCreator,
                                                              );
                                                            final pending =
                                                                habits
                                                                    .where(
                                                                      (h) =>
                                                                          h.isScheduledToday &&
                                                                          !h.isDoneToday,
                                                                    )
                                                                    .toList();
                                                            final completed =
                                                                habits
                                                                    .where(
                                                                      (h) =>
                                                                          h.isScheduledToday &&
                                                                          h.isDoneToday,
                                                                    )
                                                                    .toList();
                                                            final scheduledToday =
                                                                pending.length +
                                                                completed
                                                                    .length;
                                                            final completedToday =
                                                                completed
                                                                    .length;

                                                            WidgetsBinding.instance.addPostFrameCallback((
                                                              _,
                                                            ) {
                                                              if (mounted &&
                                                                  widget.onStatsUpdate !=
                                                                      null) {
                                                                widget
                                                                    .onStatsUpdate!(
                                                                  habits.length,
                                                                  scheduledToday,
                                                                  completedToday,
                                                                );
                                                              }
                                                            });

                                                            return Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                // ── Ended challenge result cards ──
                                                                if (dashboardState
                                                                    .data
                                                                    .endedHabits
                                                                    .isNotEmpty) ...[
                                                                  Row(
                                                                    children: [
                                                                      Container(
                                                                        width:
                                                                            4,
                                                                        height:
                                                                            18,
                                                                        decoration: BoxDecoration(
                                                                          color:
                                                                              AppTheme.onBackground,
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                2,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        'Challenge Results',
                                                                        style: GoogleFonts.plusJakartaSans(
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.w800,
                                                                          color:
                                                                              AppTheme.onBackground,
                                                                          letterSpacing:
                                                                              -0.3,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 12,
                                                                  ),
                                                                  ...dashboardState.data.endedHabits.map(
                                                                    (
                                                                      ended,
                                                                    ) => ChallengeResultCard(
                                                                      key: ValueKey(
                                                                        'ended_${ended.id}',
                                                                      ),
                                                                      habit:
                                                                          ended,
                                                                      onDismiss:
                                                                          () => context
                                                                              .read<
                                                                                GroupDashboardCubit
                                                                              >()
                                                                              .dismissChallengeResult(
                                                                                ended.id,
                                                                              ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                ],

                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Text(
                                                                      'Team Routine',
                                                                      style: GoogleFonts.plusJakartaSans(
                                                                        fontSize:
                                                                            17 *
                                                                            Responsive.scale(
                                                                              context,
                                                                            ),
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color:
                                                                            AppTheme.onBackground,
                                                                        letterSpacing:
                                                                            -0.4,
                                                                      ),
                                                                    ),
                                                                    if (isCreator)
                                                                      _buildAnimatedAddButton(
                                                                        context,
                                                                        activeSpace
                                                                            .id,
                                                                      ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 16,
                                                                ),
                                                                ...habits.map((
                                                                  habit,
                                                                ) {
                                                                  final idx = habits
                                                                      .indexOf(
                                                                        habit,
                                                                      );
                                                                  final isLast =
                                                                      idx ==
                                                                      habits.length -
                                                                          1;
                                                                  return GroupHabitCard(
                                                                    key: ValueKey(
                                                                      'group_${habit.id}',
                                                                    ),
                                                                    habit:
                                                                        habit,
                                                                    index: idx,
                                                                    isLast:
                                                                        isLast,
                                                                    onTap: () async {
                                                                      // ✅ Read cubit BEFORE creating the route
                                                                      final cubit =
                                                                          context
                                                                              .read<
                                                                                GroupDashboardCubit
                                                                              >();

                                                                      final result = await Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder:
                                                                              (ctx) => GroupHabitDetailView(
                                                                                habit:
                                                                                    habit,
                                                                                // ✅ Pass the cubit method directly, not trying to read from new context
                                                                                onMarkDone:
                                                                                    () async => await cubit
                                                                                        .completeHabit(
                                                                                          habit.id,
                                                                                          activeSpace.id,
                                                                                        )
                                                                                        .then(
                                                                                          (
                                                                                            _,
                                                                                          ) =>
                                                                                              true,
                                                                                        ),
                                                                              ),
                                                                        ),
                                                                      );
                                                                      if (result ==
                                                                              'updated' ||
                                                                          result ==
                                                                              'deleted') {
                                                                        if (context
                                                                            .mounted) {
                                                                          cubit.loadDashboard(
                                                                            spaceId:
                                                                                activeSpace.id,
                                                                          );
                                                                        }
                                                                      }
                                                                    },
                                                                    onMarkDone: () async {
                                                                      try {
                                                                        await context
                                                                            .read<
                                                                              GroupDashboardCubit
                                                                            >()
                                                                            .completeHabit(
                                                                              habit.id,
                                                                              activeSpace.id,
                                                                            );
                                                                        return true;
                                                                      } catch (
                                                                        _
                                                                      ) {
                                                                        return false;
                                                                      }
                                                                    },
                                                                  );
                                                                }),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ] else
                                                        _buildNoHabitsView(
                                                          context,
                                                          activeSpace.id,
                                                          isCreator,
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return _buildEmptyState(
                                        context,
                                        isPremium,
                                      );
                                    },
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isPremium) {
    if (!isPremium) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200 * Responsive.scale(context),
                height: 200 * Responsive.scale(context),
                child: DotLottieLoader.fromAsset(
                  'assets/LottieAnimations/community.lottie',
                  frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                    if (dotlottie != null) {
                      return Lottie.memory(dotlottie.animations.values.single);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Squad Space ',
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
                'Been invited to a Group space? Check your pending invites below. Want to create your own? Upgrade to Premium.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 14 * Responsive.scale(context),
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
                  onPressed: () => _showCreateSpaceDialog(context, isPremium),
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
                            letterSpacing: 1.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
            ],
          ),
        ),
      );
    }

    // Premium user — full create/join state
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200 * Responsive.scale(context),
              height: 200 * Responsive.scale(context),
              child: DotLottieLoader.fromAsset(
                'assets/LottieAnimations/community.lottie',
                frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                  if (dotlottie != null) {
                    return Lottie.memory(dotlottie.animations.values.single);
                  } else {
                    return Container();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'re the Main Character',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 21 * Responsive.scale(context),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF18181B),
                letterSpacing: -1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Time to build your empire. Create a space or join a crew.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14 * Responsive.scale(context),
                color: const Color(0xFF71717A),
                fontWeight: FontWeight.w500,
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
                  backgroundColor: const Color(0xFF18181B),
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
                    const Icon(Icons.add_circle_outline, size: 24),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'START A SQUAD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16 * Responsive.scale(context),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<InviteCubit, InviteState>(
              builder: (context, inviteState) {
                final profileState =
                    context.read<ProfileCubit>().state as ProfileLoaded;
                final count =
                    inviteState is InviteLoaded ? inviteState.count : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              () => _showJoinSpacePopup(context, profileState),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF18181B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: const BorderSide(
                              color: Color(0xFFE4E4E7),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                'JOIN A CREW',
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                              const Icon(Icons.mail_outline_rounded, size: 24),
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
            const SizedBox(height: 24),
            Text(
              'Create your own space to add habits and members,\nor share your QR to join someone else\'s space!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5A5A5A),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                const PremiumRequiredDialog(featureName: 'Create Group Space'),
      );
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder:
          (_) => CreateSpaceSheet(
            spaceType: 'group',
            onSpaceCreated: () => context.read<SpacesCubit>().loadSpaces(),
          ),
    ).then((created) {
      if (created == true && context.mounted) {
        context.read<SpacesCubit>().loadSpaces();
      }
    });
  }

  Widget _buildNoHabitsView(
    BuildContext context,
    String spaceId,
    bool isCreator,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 28,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No team habits yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isCreator
                ? 'Add the first habit your squad\nwill conquer together.'
                : 'The space creator hasn\'t added\nany habits yet. Check back soon!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (isCreator) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openAddHabit(context, spaceId),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Add First Habit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.onBackground,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupSpaceBanner(
    BuildContext context,
    SpaceModel space,
    bool isCreator, {
    bool hasHabits = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row: name + actions ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onBackground,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isCreator ? 'You created this space' : 'Member',
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
                // Try to get habit info from the GroupDashboardCubit if available
                List<Map<String, String>>? habitInfoList;
                try {
                  final dashState = context.read<GroupDashboardCubit>().state;
                  if (dashState is GroupDashboardLoaded) {
                    habitInfoList =
                        dashState.data.habits
                            .map((h) => {'emoji': h.emoji, 'name': h.name})
                            .toList();
                  }
                } catch (_) {}

                if (value == 'add_member') {
                  showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddMemberDialog(spaceId: space.id),
                  ).then((result) {
                    if (result != null &&
                        result['success'] == true &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
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
                                      'Invite sent!',
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
                        context.read<SpacesCubit>().loadSpaces();
                      } catch (_) {}
                    }
                  });
                } else if (value == 'manage_members') {
                  _showManageMembersSheet(
                    context,
                    space,
                    isReadOnly: false,
                    habitInfoList: habitInfoList,
                  );
                } else if (value == 'view_members') {
                  _showManageMembersSheet(
                    context,
                    space,
                    isReadOnly: true,
                    habitInfoList: habitInfoList,
                  );
                } else if (value == 'delete') {
                  _showDeleteSpaceDialog(context, space);
                } else if (value == 'leave') {
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
                    if (isCreator)
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
                              'Add Members',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isCreator)
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
                    if (!isCreator)
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
                              'View Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isCreator)
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
                    if (!isCreator)
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
        ),
        const SizedBox(height: 14),
      ],
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
