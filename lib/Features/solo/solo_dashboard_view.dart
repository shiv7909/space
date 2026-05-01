import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../habits/habit_detail_view.dart';
import '../shared/sticky_action_buttons.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/cubit/profile_state.dart';
import '../habits/widgets/add_habit_sheet.dart';
import 'cubit/solo_dashboard_cubit.dart';
import 'cubit/solo_dashboard_state.dart';
import 'widgets/smart_feed_card.dart';
import 'widgets/solo_habit_card.dart';
import 'widgets/sticky_header_banner.dart';
import 'widgets/challenge_result_card.dart';
import 'constants/solo_constants.dart';

class SoloDashboardView extends StatefulWidget {
  final bool showAppBar;
  final void Function(int total, int scheduled, int completed)? onStatsUpdate;
  const SoloDashboardView({
    super.key,
    this.showAppBar = true,
    this.onStatsUpdate,
  });

  @override
  State<SoloDashboardView> createState() => _SoloDashboardViewState();
}

class _SoloDashboardViewState extends State<SoloDashboardView>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _labelController;
  late Animation<double> _labelWidth;
  late Animation<double> _labelOpacity;
  bool _labelAnimationTriggered = false;
  bool _postFrameCallbackRegistered = false;

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

  void dispose() {
    _scrollController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Widget _buildAddHabitButton(BuildContext context) {
    return SizedBox(
      width: 180.rs(context), // Decreased width, adjust as needed
      child: ElevatedButton(
        onPressed: () => _openAddHabit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.onBackground,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20.rs(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 22.rs(context)),
            SizedBox(width: 10.rs(context)),
            Text(
              'New Habit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.rs(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddHabit(BuildContext context) {
    final spaceId = context.read<SoloDashboardCubit>().activeSpaceId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitSheet(spaceId: spaceId),
    ).then((result) {
      if (result == true && context.mounted) {
        context.read<SoloDashboardCubit>().loadDashboard();
      }
    });
  }

  Widget _buildAnimatedAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddHabit(context),
      child: AnimatedBuilder(
        animation: _labelController,
        builder: (context, _) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.rs(context),
              vertical: 8.rs(context),
            ),
            decoration: BoxDecoration(
              color: AppTheme.onBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16.rs(context),
                  color: Colors.white,
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1.0 - _labelWidth.value,
                    child: FadeTransition(
                      opacity: ReverseAnimation(_labelOpacity),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 5.rs(context)),
                          Text(
                            'New Habit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.rs(context),
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

        // ✅ NO BlocProvider here — SoloDashboardCubit is provided by MainNavigation
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: BlocConsumer<SoloDashboardCubit, SoloDashboardState>(
            listener: (context, dashboardState) {
              if (dashboardState is SoloDashboardHabitCompleted) {
                final emoji = SoloConstants.categoryEmoji(
                  dashboardState.category,
                );
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Text(emoji, style: TextStyle(fontSize: 20.rs(context))),
                        SizedBox(width: 10.rs(context)),
                        Expanded(
                          child: Text(
                            dashboardState.completionMessage,
                            style: TextStyle(
                              fontSize: 14.rs(context),
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
              if (next is SoloDashboardRefreshing &&
                  prev is SoloDashboardLoaded)
                return false;
              return true;
            },
            builder: (context, dashboardState) {
              final effectiveState =
                  dashboardState is SoloDashboardRefreshing
                      ? SoloDashboardLoaded(data: dashboardState.data)
                      : dashboardState;

              return SafeArea(
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
                            spaceType: SpaceType.solo,
                            profile: p,
                            displayUrl: d,
                            scrollController: _scrollController,
                          );
                        },
                      ),
                    // ── Scrollable body ──
                    Expanded(child: _buildBody(context, effectiveState)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Body switches between states ───────────────────────────────────────
  Widget _buildBody(BuildContext context, SoloDashboardState state) {
    if (state is SoloDashboardLoading) {
      return const SizedBox.shrink();
    }
    if (state is SoloDashboardError) {
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
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.accentRed, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    () => context.read<SoloDashboardCubit>().loadDashboard(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state is SoloDashboardLoaded) {
      return _buildLoaded(context, state);
    }
    return const SizedBox.shrink();
  }

  // ─── Loaded state — fully lazy CustomScrollView ─────────────────────────
  Widget _buildLoaded(BuildContext context, SoloDashboardLoaded state) {
    final all = state.data.habits;
    final pending =
        all.where((h) => h.isScheduledToday && !h.isDoneToday).toList();
    final completed =
        all.where((h) => h.isScheduledToday && h.isDoneToday).toList();
    final rest = all.where((h) => !h.isScheduledToday).toList();
    final sorted = [...pending, ...completed, ...rest];

    final isEmpty = sorted.isEmpty;
    final hasAlerts = state.data.alerts.isNotEmpty && !isEmpty;
    final hasBanner = state.data.stickyHeader != null && !isEmpty;
    final hasEndedHabits = state.data.endedHabits.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.onStatsUpdate != null) {
        widget.onStatsUpdate!(
          all.length,
          pending.length + completed.length,
          completed.length,
        );
      }
    });

    // Trigger label collapse once list is ready
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _triggerLabelCollapseIfNeeded(),
    );

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 600,
      slivers: [
        // ── Pull-to-refresh ──
        CupertinoSliverRefreshControl(
          onRefresh:
              () => context.read<SoloDashboardCubit>().refreshDashboard(),
        ),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            24.rs(context),
            8.rs(context),
            24.rs(context),
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              // ── Ended challenge result cards ──
              if (hasEndedHabits) ...[
                Row(
                  children: [
                    Container(
                      width: 4.rs(context),
                      height: 18.rs(context),
                      decoration: BoxDecoration(
                        color: AppTheme.onBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8.rs(context)),
                    Text(
                      'Challenge Results',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.rs(context),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onBackground,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.rs(context)),
                ...state.data.endedHabits.map(
                  (ended) => ChallengeResultCard(
                    key: ValueKey('ended_${ended.id}'),
                    habit: ended,
                    onDismiss:
                        () => context
                            .read<SoloDashboardCubit>()
                            .dismissChallengeResult(ended.id),
                  ),
                ),
                SizedBox(height: 16.rs(context)),
              ],

              // Alerts carousel
              if (hasAlerts) ...[
                SizedBox(
                  height: 120.rs(context),
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
                                .read<SoloDashboardCubit>()
                                .dismissAlert(alert.id),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24.rs(context)),
              ],

              // Sticky banner
              if (hasBanner) ...[
                StickyHeaderBanner(header: state.data.stickyHeader!),
                SizedBox(height: 24.rs(context)),
              ],

              // Progress is now in the hero header — removed from here

              // "Your Habits" header
              if (!isEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Habits',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.rs(context),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                        letterSpacing: -0.4,
                      ),
                    ),
                    _buildAnimatedAddButton(context),
                  ],
                ),
              if (!isEmpty) SizedBox(height: 16.rs(context)),
            ]),
          ),
        ),

        // ── Habit cards ──
        if (isEmpty && !hasEndedHabits)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(context),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              24.rs(context),
              0,
              24.rs(context),
              120.rs(context),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final habit = sorted[index];
                  return RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.rs(context)),
                      child: SoloHabitCard(
                        key: ValueKey(habit.id),
                        habit: habit,
                        index: index,
                        isLast: index == sorted.length - 1,
                        initiallyExpanded: index == 0,
                        onTap: () async {
                          // ✅ Read cubit BEFORE creating the route
                          final cubit = context.read<SoloDashboardCubit>();

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (ctx) => HabitDetailView(
                                    habit: habit,
                                    // ✅ Pass the cubit method directly, not trying to read from new context
                                    onMarkDone:
                                        () async =>
                                            await cubit.completeHabit(habit.id),
                                  ),
                            ),
                          );
                          if (result == 'updated' || result == 'deleted') {
                            if (context.mounted) cubit.loadDashboard();
                          }
                        },
                        onMarkDone:
                            () async => await context
                                .read<SoloDashboardCubit>()
                                .completeHabit(habit.id),
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

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24.rs(context),
        0,
        24.rs(context),
        0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 200.rs(context),
            height: 200.rs(context),
            child: DotLottieLoader.fromAsset(
              'assets/LottieAnimations/SOLOaNI.lottie',
              frameBuilder: (ctx, dotlottie) {
                if (dotlottie != null)
                  return Lottie.memory(dotlottie.animations.values.single);
                return const SizedBox.shrink();
              },
            ),
          ),
          SizedBox(height: 16.rs(context)),
          Text(
            'Me, Myself & Growth',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 21.rs(context),
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.rs(context)),
          Text(
            'Your personal space to track habits\nand level up your life.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 14.rs(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.rs(context)),
          _buildAddHabitButton(context),
        ],
      ),
    );
  }
}
