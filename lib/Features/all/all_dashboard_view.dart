import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:space/Features/solo/constants/solo_constants.dart'
    show SoloResponsiveSize;

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/genz_all_done_message.dart';
import '../../models/dashboard_model.dart';
import '../habits/habit_detail_view.dart';
import '../couple/widgets/couple_habit_detail_view.dart';
import '../group/widgets/group_habit_detail_view.dart';
import 'cubit/all_dashboard_cubit.dart';
import 'cubit/all_dashboard_state.dart';

class AllDashboardView extends StatefulWidget {
  final bool showAppBar;
  final void Function(int total, int scheduled, int completed)? onStatsUpdate;
  const AllDashboardView({
    super.key,
    this.showAppBar = true,
    this.onStatsUpdate,
  });

  @override
  State<AllDashboardView> createState() => _AllDashboardViewState();
}

class _AllDashboardViewState extends State<AllDashboardView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Navigate to detail view based on space type ──
  Future<void> _handleHabitTap(
    BuildContext context,
    DashboardHabit habit,
  ) async {
    final cubit = context.read<AllDashboardCubit>();
    Widget detailView;
    if (habit.spaceType == DashboardSpaceType.couple) {
      detailView = CoupleHabitDetailView(
        habit: habit,
        onMarkDone: () async => await cubit.completeHabit(habit),
      );
    } else if (habit.spaceType == DashboardSpaceType.group) {
      detailView = GroupHabitDetailView(
        habit: habit,
        onMarkDone: () async => await cubit.completeHabit(habit),
      );
    } else {
      detailView = HabitDetailView(
        habit: habit,
        onMarkDone: () async => await cubit.completeHabit(habit),
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => detailView),
    );
    if (result == 'updated' || result == 'deleted') {
      if (context.mounted) cubit.refreshDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<AllDashboardCubit, AllDashboardState>(
        listener: (context, state) {
          if (state is AllDashboardHabitCompleted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
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
        builder: (context, state) {
          if (state is AllDashboardLoading || state is AllDashboardInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.onBackground),
            );
          }
          if (state is AllDashboardError) {
            return Center(
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
                                .read<AllDashboardCubit>()
                                .refreshDashboard(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final dashboardState =
              state is AllDashboardRefreshing
                  ? state.data
                  : state is AllDashboardLoaded
                  ? state.data
                  : (state as AllDashboardHabitCompleted).data;

          final habits = dashboardState.habits;
          final pending =
              habits
                  .where((h) => h.isScheduledToday && !h.isDoneToday)
                  .toList();
          final completed =
              habits.where((h) => h.isScheduledToday && h.isDoneToday).toList();
          final scheduledToday = pending.length + completed.length;
          final completedToday = completed.length;
          final isEmpty = habits.isEmpty;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.onStatsUpdate != null) {
              widget.onStatsUpdate!(
                habits.length,
                scheduledToday,
                completedToday,
              );
            }
          });

          return SafeArea(
            top: widget.showAppBar,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh:
                      () =>
                          context.read<AllDashboardCubit>().refreshDashboard(),
                ),
                if (isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      4.rs(context),
                      0,
                      120.rs(context),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        // ═══════════════════════════════════════════
                        // SECTION 1: TODAY'S ROUTINE (pending)
                        // ═══════════════════════════════════════════
                        if (pending.isNotEmpty) ...[
                          _PhonePeSection(
                            title: "Today's Routine",
                            count: pending.length,
                            icon: Icons.schedule_rounded,
                            iconColor: AppColors.primary,
                            habits: pending,
                            onTap: (h) => _handleHabitTap(context, h),
                            onMarkDone:
                                (h) async => await context
                                    .read<AllDashboardCubit>()
                                    .completeHabit(h),
                          ),
                        ] else if (completed.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                            child: const GenZAllDoneMessage(),
                          ),
                        ],
                      ]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Divider(height: 1, thickness: 1, color: AppTheme.outline),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24.rs(context),
        0,
        24.rs(context),
        48.rs(context),
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
                if (dotlottie != null) {
                  return Lottie.memory(dotlottie.animations.values.single);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          SizedBox(height: 16.rs(context)),
          Text(
            'Nothing to see here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22.rs(context),
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.rs(context)),
          Text(
            'Add some habits in your workspaces to see your overall progress.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 15.rs(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PHONEPE-STYLE SECTION — Header + 4-per-row icon grid
// ═══════════════════════════════════════════════════════════════════════════════

class _PhonePeSection extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final List<DashboardHabit> habits;
  final bool isCompleted;
  final void Function(DashboardHabit) onTap;
  final Future<void> Function(DashboardHabit) onMarkDone;

  const _PhonePeSection({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.habits,
    this.isCompleted = false,
    required this.onTap,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final Map<DashboardSpaceType, List<DashboardHabit>> grouped = {
      DashboardSpaceType.solo: [],
      DashboardSpaceType.couple: [],
      DashboardSpaceType.group: [],
    };
    for (var h in habits) {
      grouped[h.spaceType]!.add(h);
    }
    final groupsToRender =
        grouped.entries.where((e) => e.value.isNotEmpty).toList();

    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Grouped Habits by Space ──
          ...groupsToRender.map((entry) {
            final spaceType = entry.key;
            final spaceHabits = entry.value;

            Color spaceColor;
            String spaceLabel;
            IconData spaceIcon;

            switch (spaceType) {
              case DashboardSpaceType.solo:
                spaceColor = AppColors.primary;
                spaceLabel = 'SOLO';
                spaceIcon = Icons.person_rounded;
                break;
              case DashboardSpaceType.couple:
                spaceColor = const Color(0xFFE91E63);
                spaceLabel = 'DUO';
                spaceIcon = Icons.favorite_rounded;
                break;
              case DashboardSpaceType.group:
                spaceColor = const Color(0xFF2196F3);
                spaceLabel = 'SQUAD';
                spaceIcon = Icons.groups_rounded;
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            color: spaceColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(spaceIcon, size: 14, color: spaceColor),
                        const SizedBox(width: 6),
                        Text(
                          spaceLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: spaceHabits.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 1,
                            crossAxisSpacing: 1,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (context, index) {
                        final habit = spaceHabits[index];
                        return _HabitGridTile(
                          habit: habit,
                          isCompleted: isCompleted || habit.isDoneToday,
                          onTap: () => onTap(habit),
                          onLongPress: () {
                            if (!habit.isDoneToday && habit.isScheduledToday) {
                              HapticFeedback.mediumImpact();
                              onMarkDone(habit);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HABIT GRID TILE — circular emoji icon + name
// ═══════════════════════════════════════════════════════════════════════════════

class _HabitGridTile extends StatelessWidget {
  final DashboardHabit habit;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _HabitGridTile({
    required this.habit,
    required this.isCompleted,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final checkOverlay = isCompleted;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Circular emoji icon ──
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Main circle
              Container(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    habit.emoji,
                    style: TextStyle(fontSize: isCompleted ? 18 : 22),
                  ),
                ),
              ),

              // ✅ Completion checkmark overlay
              if (checkOverlay)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.checkDoneBG,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Streak count (top-right) — only if > 0
              if (habit.currentStreak > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.streakBadgeBG,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 7)),
                        const SizedBox(width: 1),
                        Text(
                          '${habit.currentStreak}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.streakBadgeText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Habit name ──
          Flexible(
            child: Text(
              habit.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w600,
                color:
                    isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                height: 1.2,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
