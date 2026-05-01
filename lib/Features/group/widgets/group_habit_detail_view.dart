import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/dashboard_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/habit_emojis.dart';
import '../../../services/space_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/image_cache_service.dart';
import '../../shared/habit_shape_widget.dart';


/// 👥 GROUP HABIT DETAIL VIEW — Full group-specific detail screen
class GroupHabitDetailView extends StatefulWidget {
  final DashboardHabit habit;
  final Future<bool> Function()? onMarkDone;

  const GroupHabitDetailView({super.key, required this.habit, this.onMarkDone});

  @override
  State<GroupHabitDetailView> createState() => _GroupHabitDetailViewState();
}

class _GroupHabitDetailViewState extends State<GroupHabitDetailView>
    with TickerProviderStateMixin {
  late AnimationController _progressBarController;
  late Animation<double> _progressBarAnimation;
  late AnimationController _markDoneController;
  bool _markingDone = false;
  bool _todayListExpanded = false;

  // ── Paginated calendar state ──────────────────────────────────────────
  late int _calYear;
  late int _calMonth;
  HabitCalendarMonth? _calData;
  bool _calLoading = false;

  @override
  void initState() {
    super.initState();
    _progressBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressBarAnimation = CurvedAnimation(
      parent: _progressBarController,
      curve: Curves.easeOutCubic,
    );
    _progressBarController.forward();

    _markDoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Start on current month
    final now = DateTime.now();
    _calYear = now.year;
    _calMonth = now.month;
    _loadCalendarMonth(_calYear, _calMonth);
  }

  Future<void> _loadCalendarMonth(int year, int month) async {
    if (!mounted) return;
    setState(() => _calLoading = true);
    final service = context.read<SpaceService>();
    final data = await service.getHabitCalendar(
      habitId: widget.habit.id,
      year: year,
      month: month,
    );
    if (!mounted) return;
    setState(() {
      _calData = data;
      _calYear = year;
      _calMonth = month;
      _calLoading = false;
    });
  }

  @override
  void dispose() {
    _progressBarController.dispose();
    _markDoneController.dispose();
    super.dispose();
  }

  bool get _shouldShowMarkDone {
    if (widget.habit.isDoneToday) return false;
    final today = DateTime.now();
    if (!widget.habit.scheduledDays.contains(today.weekday)) return false;
    return true;
  }

  void _handleMarkDone() async {
    if (_markingDone) return;
    HapticFeedback.heavyImpact();
    setState(() => _markingDone = true);
    await _markDoneController.forward();

    bool success = false;
    if (widget.onMarkDone != null) {
      success = await widget.onMarkDone!();
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, 'updated');
    } else {
      await _markDoneController.reverse();
      setState(() => _markingDone = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Already completed or couldn\'t save. Try again.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.onBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ═══ APP BAR ═══
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 56,
                  automaticallyImplyLeading: false,
                  title: Row(children: [_buildBackButton()]),
                  actions: [
                    _buildActionButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: () => _showOptionsSheet(context),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),

                // ═══ HERO SECTION ═══
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _buildHeroSection(h),
                  ),
                ),

                // ═══ TEAM COMPLETION RING ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildTeamCompletionCard(h),
                  ),
                ),

                // ═══ MY STATS ROW ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildMyStatsRow(h)),
                ),

                // ═══ HABIT HEADER MESSAGE ═══
                if (h.habitHeader != null &&
                    (h.habitHeader!['message'] as String? ?? '').isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHabitHeaderBanner(h.habitHeader!),
                    ),
                  ),

                // ═══ WHO'S DONE TODAY ═══
                if (h.isScheduledToday)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildWhosDoneTodayCard(h),
                    ),
                  ),

                // ═══ FULL LEADERBOARD ═══
                if (h.leaderboard.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildLeaderboardCard(h)),
                  ),

                // ═══ MY CALENDAR ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildCalendarSection(h)),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // ═══ MARK DONE BUTTON ═══
            if (_shouldShowMarkDone)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: _buildMarkDoneButton(),
              ),

            // ═══ COMPLETED BANNER ═══
            if (widget.habit.isDoneToday)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: _buildCompletedBanner(),
              ),
          ],
        ),
      ),
    );
  }

  // ───��────────────────────────────────────────────
  // BACK BUTTON
  // ────────────────────────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppTheme.onBackground,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.onBackground, size: 20),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // HERO SECTION
  // ────────────────────────────────────────────────
  Widget _buildHeroSection(DashboardHabit h) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E5F5), width: 2),
          ),
          child: Center(child: HabitShapeWidget(emoji: h.emoji, size: 34)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (h.whyReason != null && h.whyReason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFED7AA).withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          h.whyReason!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF92400E),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildBadge(
                    icon: Icons.groups_rounded,
                    label: '${h.totalMembers} members',
                    color: const Color(0xFF5C4AE4),
                  ),
                  _buildBadge(
                    icon:
                        h.mode == 'challenge'
                            ? Icons.flag_rounded
                            : Icons.all_inclusive_rounded,
                    label:
                        h.mode == 'challenge'
                            ? 'Challenge${h.targetDays != null ? ' · ${h.targetDays}d' : ''}'
                            : 'Forever',
                    color: const Color(0xFF5C4AE4),
                  ),
                  _buildBadge(
                    icon: Icons.calendar_today_rounded,
                    label: _formatSchedule(h.scheduledDays),
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSchedule(List<int> days) {
    if (days.length == 7) return 'Daily';
    if (days.length == 5 && !days.contains(6) && !days.contains(7))
      return 'Weekdays';
    if (days.length == 2 && days.contains(6) && days.contains(7))
      return 'Weekends';
    return '${days.length}x/week';
  }

  // ────────────────────────────────────────────────
  // TEAM COMPLETION RING CARD
  // ────────────────────────────────────────────────
  Widget _buildTeamCompletionCard(DashboardHabit h) {
    final done = h.doneTodayCount;
    final total = h.totalMembers;
    final threshold = h.streakThreshold;
    final fraction = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    final isScheduledToday = h.isScheduledToday;

    // Colors
    Color accent;
    if (!isScheduledToday) {
      accent = AppTheme.onSurfaceVariant;
    } else if (threshold > 0) {
      if (done >= threshold) {
        accent = const Color(0xFF2DA44E);
      } else if (done >= threshold - 1) {
        accent = const Color(0xFFF59E0B);
      } else {
        accent = const Color(0xFFD1242F);
      }
    } else {
      if (done == total && total > 0) {
        accent = const Color(0xFF2DA44E);
      } else if (fraction >= 0.5) {
        accent = const Color(0xFFF59E0B);
      } else {
        accent = const Color(0xFFD1242F);
      }
    }

    final groupStreak = h.groupStreak;
    final statusLabel =
        !isScheduledToday
            ? 'Rest day'
            : done == total && total > 0
            ? 'Everyone done! 🎉'
            : threshold > 0 && done >= threshold
            ? 'Threshold reached ✓'
            : '$done of $total done today';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'TEAM PROGRESS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (groupStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        '$groupStreak squad streak',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD1242F),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Ring + stats side by side
          Row(
            children: [
              // Animated circular ring
              SizedBox(
                width: 90,
                height: 90,
                child: AnimatedBuilder(
                  animation: _progressBarAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RingPainter(
                        progress:
                            isScheduledToday
                                ? fraction * _progressBarAnimation.value
                                : 0.0,
                        accent: accent,
                        track: accent.withValues(alpha: 0.12),
                        strokeWidth: 9,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isScheduledToday ? '$done' : '—',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onBackground,
                                height: 1,
                              ),
                            ),
                            Text(
                              isScheduledToday ? 'of $total' : 'rest',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              // Right side stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isScheduledToday
                                ? accent
                                : AppTheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Threshold info
                    if (threshold > 0 && isScheduledToday) ...[
                      _progressStatRow(
                        label: 'Threshold',
                        value: '$threshold/${total}',
                        accent: const Color(0xFF5C4AE4),
                      ),
                      const SizedBox(height: 6),
                    ],
                    _progressStatRow(
                      label: 'Completed',
                      value: '$done',
                      accent: const Color(0xFF2DA44E),
                    ),
                    const SizedBox(height: 6),
                    _progressStatRow(
                      label: 'Pending',
                      value: '${total - done}',
                      accent: AppTheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Full-width bar at bottom
          if (isScheduledToday) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _progressBarAnimation,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 7,
                    child: Stack(
                      children: [
                        Container(color: accent.withValues(alpha: 0.10)),
                        FractionallySizedBox(
                          widthFactor: fraction * _progressBarAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressStatRow({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onBackground,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────
  // MY PERSONAL STATS ROW
  // ────────────────────────────────────────────────
  Widget _buildMyStatsRow(DashboardHabit h) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Row(
        children: [
          _quickStatItem(
            '${h.currentStreak}',
            'My Streak',
            AppTheme.accentAmber,
          ),
          _quickStatDivider(),
          _quickStatItem('${h.bestStreak}', 'My Best', const Color(0xFF8B5CF6)),
          _quickStatDivider(),
          _quickStatItem(
            '${h.myCalendar.length}',
            'Total',
            AppTheme.accentGreen,
          ),
          _quickStatDivider(),
          _quickStatItem(
            h.myRank > 0 ? _ordinal(h.myRank) : '—',
            'Rank',
            const Color(0xFF5C4AE4),
          ),
        ],
      ),
    );
  }

  Widget _quickStatItem(String value, String label, Color accent) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStatDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFEDEDF2));
  }

  // ───────────��────────────────────────────────────
  // HABIT HEADER BANNER
  // ────────────────────────────────────────────────
  Widget _buildHabitHeaderBanner(Map<String, dynamic> header) {
    final message = header['message'] as String? ?? '';
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // WHO'S DONE TODAY CARD
  // ────────────────────────────────────────────────
  Widget _buildWhosDoneTodayCard(DashboardHabit h) {
    // `h.members` already includes the current user — build directly from it.
    final allMembers =
        h.members
            .map(
              (m) => _GroupMemberRow(
                name: m.displayName,
                avatarId: m.avatarId,
                photoKey: m.photoKey,
                isDone: m.doneToday,
                isMe: m.isMe,
                currentStreak: m.currentStreak,
                bestStreak: m.bestStreak,
                totalLogs: m.totalLogs,
                rank: m.rank,

              ),
            )
            .toList();

    final doneList =
        allMembers.where((m) => m.isDone).toList()..sort(
          (a, b) =>
              a.isMe
                  ? -1
                  : b.isMe
                  ? 1
                  : 0,
        );
    final pendingList =
        allMembers.where((m) => !m.isDone).toList()..sort(
          (a, b) =>
              a.isMe
                  ? -1
                  : b.isMe
                  ? 1
                  : 0,
        );

    final totalCount = allMembers.length;
    final bool needsCollapse = totalCount > 4;
    // In collapsed state: show up to 2 done + 2 pending
    final visibleDone =
        needsCollapse && !_todayListExpanded
            ? doneList.take(2).toList()
            : doneList;
    final visiblePending =
        needsCollapse && !_todayListExpanded
            ? pendingList.take(2).toList()
            : pendingList;
    final hiddenCount = totalCount - visibleDone.length - visiblePending.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "TODAY",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DA44E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${doneList.length} done',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2DA44E),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (pendingList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pendingList.length} pending',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Done members (visible portion)
          ...visibleDone.map((m) => _buildMemberTile(m, isDone: true)),
          // Pending members (visible portion)
          ...visiblePending.map((m) => _buildMemberTile(m, isDone: false)),
          // Show more / less toggle
          if (needsCollapse) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap:
                  () =>
                      setState(() => _todayListExpanded = !_todayListExpanded),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _todayListExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _todayListExpanded
                          ? 'Show less'
                          : 'Show all $totalCount members${hiddenCount > 0 ? ' (+$hiddenCount)' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
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

  Widget _buildMemberTile(_GroupMemberRow m, {required bool isDone}) {
    final profileService = context.read<ProfileService>();
    final initials = _getInitials(m.name);

    final Color avatarBorder =
        isDone
            ? const Color(0xFF2DA44E).withValues(alpha: 0.3)
            : const Color(0xFFDDDDE3);
    final Color avatarText =
        isDone ? const Color(0xFF2DA44E) : AppTheme.onSurfaceVariant;
    final Color avatarBg =
        isDone
            ? const Color(0xFF2DA44E).withValues(alpha: 0.10)
            : AppTheme.surfaceVariant;

    Widget avatarFallback = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: avatarBg,
        shape: BoxShape.circle,
        border: Border.all(color: avatarBorder, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: avatarText,
          ),
        ),
      ),
    );

    Widget buildImageAvatar(String url) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: avatarBorder, width: 1.5),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            cacheKey: m.photoKey,
            cacheManager: ImageCacheService().cacheManager,
            fit: BoxFit.cover,
            width: 36,
            height: 36,
            httpHeaders: {'Accept': 'image/*', 'Connection': 'keep-alive'},
            placeholder: (context, url) => avatarFallback,
            errorWidget: (context, url, error) => avatarFallback,
          ),
        ),
      );
    }

    // Priority: real photo (photoKey) → avatar ID → initials fallback
    Widget avatarWidget;
    if (m.photoKey != null && m.photoKey!.isNotEmpty) {
      final url = profileService.getProfilePhotoUrl(m.photoKey!);
      avatarWidget = buildImageAvatar(url);
    } else if (m.avatarId != null) {
      avatarWidget = FutureBuilder<String?>(
        future: profileService.getAvatarUrlById(m.avatarId!),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done ||
              snap.data == null) {
            return avatarFallback;
          }
          return buildImageAvatar(snap.data!);
        },
      );
    } else {
      avatarWidget = avatarFallback;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          avatarWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        m.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              m.isMe ? FontWeight.w700 : FontWeight.w500,
                          color: AppTheme.onBackground,
                        ),
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 3),
                    Text(
                      '${m.currentStreak}d streak',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${m.totalLogs} total',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isDone
                      ? const Color(0xFF2DA44E).withValues(alpha: 0.08)
                      : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 12,
                  color:
                      isDone
                          ? const Color(0xFF2DA44E)
                          : AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  isDone ? 'Done' : 'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        isDone
                            ? const Color(0xFF2DA44E)
                            : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // FULL LEADERBOARD CARD
  // ────────────────────────────────────────────────
  Widget _buildLeaderboardCard(DashboardHabit h) {
    final entries = h.leaderboard;
    final maxStreak = entries.fold<int>(
      1,
      (prev, e) => e.currentStreak > prev ? e.currentStreak : prev,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEADERBOARD',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ...entries.map((entry) {
            final widthFactor =
                maxStreak > 0
                    ? (entry.currentStreak / maxStreak).clamp(0.0, 1.0)
                    : 0.0;
            final isTop3 = entry.rank <= 3;

            // Gold / silver / bronze for top 3, grey for rest
            final rankColor =
                entry.rank == 1
                    ? const Color(0xFFD4A017)
                    : entry.rank == 2
                    ? const Color(0xFF9E9E9E)
                    : entry.rank == 3
                    ? const Color(0xFFCD7F32)
                    : AppTheme.onSurfaceVariant;

            final profileService = context.read<ProfileService>();
            final initials = _getInitials(entry.displayName);
            final avatarColor =
                entry.isMe
                    ? const Color(0xFF5C4AE4)
                    : AppTheme.onSurfaceVariant;

            Widget avatarFallback = Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    entry.isMe
                        ? const Color(0xFF5C4AE4).withValues(alpha: 0.12)
                        : AppTheme.surfaceVariant,
                shape: BoxShape.circle,
                border:
                    entry.isMe
                        ? Border.all(
                          color: const Color(0xFF5C4AE4).withValues(alpha: 0.3),
                          width: 1.5,
                        )
                        : null,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
            );

            Widget buildLeaderboardImageAvatar(String url) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      entry.isMe
                          ? Border.all(
                            color: const Color(
                              0xFF5C4AE4,
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          )
                          : null,
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    cacheKey: entry.photoKey,
                    cacheManager: ImageCacheService().cacheManager,
                    fit: BoxFit.cover,
                    width: 32,
                    height: 32,
                    httpHeaders: {
                      'Accept': 'image/*',
                      'Connection': 'keep-alive',
                    },
                    placeholder: (context, url) => avatarFallback,
                    errorWidget: (context, url, error) => avatarFallback,
                  ),
                ),
              );
            }

            // Priority: real photo (photoKey) → avatar ID → initials fallback
            Widget avatarWidget;
            if (entry.photoKey != null && entry.photoKey!.isNotEmpty) {
              final url = profileService.getProfilePhotoUrl(entry.photoKey!);
              avatarWidget = buildLeaderboardImageAvatar(url);
            } else if (entry.avatarId != null) {
              avatarWidget = FutureBuilder<String?>(
                future: profileService.getAvatarUrlById(entry.avatarId!),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done ||
                      snap.data == null) {
                    return avatarFallback;
                  }
                  return buildLeaderboardImageAvatar(snap.data!);
                },
              );
            } else {
              avatarWidget = avatarFallback;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      entry.isMe
                          ? const Color(0xFF5C4AE4).withValues(alpha: 0.06)
                          : isTop3
                          ? const Color(0xFFFAF9FF)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      entry.isMe
                          ? Border.all(
                            color: const Color(
                              0xFF5C4AE4,
                            ).withValues(alpha: 0.15),
                            width: 1,
                          )
                          : isTop3
                          ? Border.all(color: const Color(0xFFF0F0F8), width: 1)
                          : null,
                ),
                child: Row(
                  children: [
                    // Rank number (coloured, no emoji)
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${entry.rank}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: isTop3 ? 14 : 12,
                          fontWeight: FontWeight.w700,
                          color: rankColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar with real image
                    avatarWidget,
                    const SizedBox(width: 10),
                    // Name + streak bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight:
                                        entry.isMe
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    color:
                                        entry.isMe
                                            ? const Color(0xFF5C4AE4)
                                            : AppTheme.onBackground,
                                  ),
                                ),
                              ),

                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 3),
                              Text(
                                '${entry.currentStreak}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3D3D4E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: SizedBox(
                                    height: 4,
                                    child: Stack(
                                      children: [
                                        Container(
                                          color:
                                              entry.isMe
                                                  ? const Color(
                                                    0xFF5C4AE4,
                                                  ).withValues(alpha: 0.10)
                                                  : const Color(0xFFEDEDF2),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: widthFactor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  entry.isMe
                                                      ? const Color(0xFF5C4AE4)
                                                      : const Color(0xFF2DA44E),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // MY CALENDAR SECTION — paginated, one month at a time
  // ────────────────────────────────────────────────
  Widget _buildCalendarSection(DashboardHabit h) {
    final data = _calData;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with legend ──
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'My History',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onBackground,
                ),
              ),
              const Spacer(),
              _legendDot(AppTheme.accentGreen, 'Done'),
              const SizedBox(width: 10),
              _legendDot(AppTheme.accentRed.withValues(alpha: 0.5), 'Miss'),
              const SizedBox(width: 10),
              _legendDot(const Color(0xFFD5D5DA), 'Rest'),
            ],
          ),
        ),

        // ── Month navigation + calendar ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month nav row
              Row(
                children: [
                  // Prev month
                  GestureDetector(
                    onTap:
                        (data?.hasPrevMonth == true && !_calLoading)
                            ? () {
                              HapticFeedback.selectionClick();
                              final dt = DateTime(_calYear, _calMonth - 1);
                              _loadCalendarMonth(dt.year, dt.month);
                            }
                            : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            (data?.hasPrevMonth == true && !_calLoading)
                                ? AppTheme.surfaceVariant
                                : AppTheme.surfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color:
                            (data?.hasPrevMonth == true && !_calLoading)
                                ? AppTheme.onBackground
                                : AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                      ),
                    ),
                  ),

                  // Month label (centered)
                  Expanded(
                    child: Center(
                      child:
                          _calLoading
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMMM yyyy',
                                    ).format(DateTime(_calYear, _calMonth)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onBackground,
                                    ),
                                  ),
                                  if (_calYear == now.year &&
                                      _calMonth == now.month) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'NOW',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.accentGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                    ),
                  ),

                  // Next month
                  GestureDetector(
                    onTap:
                        (data?.hasNextMonth == true && !_calLoading)
                            ? () {
                              HapticFeedback.selectionClick();
                              final dt = DateTime(_calYear, _calMonth + 1);
                              _loadCalendarMonth(dt.year, dt.month);
                            }
                            : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            (data?.hasNextMonth == true && !_calLoading)
                                ? AppTheme.surfaceVariant
                                : AppTheme.surfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color:
                            (data?.hasNextMonth == true && !_calLoading)
                                ? AppTheme.onBackground
                                : AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Day of week headers
              Row(
                children:
                    ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),

              const SizedBox(height: 6),

              // Calendar grid
              _calLoading || data == null
                  ? const SizedBox(height: 140)
                  : _buildMonthGrid(data, h, now),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(
    HabitCalendarMonth data,
    DashboardHabit h,
    DateTime now,
  ) {
    final daysInMonth = DateTime(data.year, data.month + 1, 0).day;
    final firstWeekday =
        DateTime(data.year, data.month, 1).weekday % 7; // 0=Sun

    final scheduledDays =
        data.scheduledDays.isNotEmpty ? data.scheduledDays : h.scheduledDays;

    final habitStart = data.habitStartDate ?? h.startDate ?? h.createdAt;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        ...List.generate(firstWeekday, (_) => const SizedBox()),
        ...List.generate(daysInMonth, (i) {
          final date = DateTime(data.year, data.month, i + 1);
          return _buildCalendarDay(
            date: date,
            data: data,
            scheduledDays: scheduledDays,
            habitStart: habitStart,
            now: now,
          );
        }),
      ],
    );
  }

  Widget _buildCalendarDay({
    required DateTime date,
    required HabitCalendarMonth data,
    required List<int> scheduledDays,
    required DateTime? habitStart,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(date.year, date.month, date.day);
    final isToday = thisDay == today;
    final isFuture = thisDay.isAfter(today);

    bool isBeforeStart = false;
    if (habitStart != null) {
      final start = DateTime(habitStart.year, habitStart.month, habitStart.day);
      if (thisDay.isBefore(start)) isBeforeStart = true;
    }

    final isCompleted = data.isCompleted(date);
    final isScheduled = scheduledDays.contains(date.weekday);

    Color bgColor;
    Color textColor;
    Border? border;

    if (isBeforeStart || isFuture) {
      bgColor = const Color(0xFFF5F5F8);
      textColor = const Color(0xFFBBBBC5);
    } else if (isToday && isCompleted) {
      bgColor = AppTheme.accentGreen;
      textColor = Colors.white;
      border = Border.all(color: AppTheme.onBackground, width: 2);
    } else if (isToday) {
      bgColor = const Color(0xFFF5F5F8);
      textColor = AppTheme.onBackground;
      border = Border.all(color: AppTheme.onBackground, width: 2);
    } else if (isCompleted) {
      bgColor = AppTheme.accentGreen;
      textColor = Colors.white;
    } else if (!isScheduled) {
      bgColor = const Color(0xFFEEEEF2);
      textColor = const Color(0xFFBBBBC5);
    } else {
      bgColor = AppTheme.accentRed.withValues(alpha: 0.12);
      textColor = const Color(0xFFBBBBC5);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth * 0.75;
        return Center(
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: border,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────
  // MARK DONE BUTTON
  // ────────────────────────────────────────────────
  Widget _buildMarkDoneButton() {
    return GestureDetector(
      onTap: _handleMarkDone,
      child: AnimatedBuilder(
        animation: _markDoneController,
        builder: (context, child) {
          final progress = _markDoneController.value;
          final bgColor =
              ColorTween(
                begin: AppTheme.onBackground,
                end: AppTheme.accentGreen,
              ).evaluate(_markDoneController)!;

          return Transform.scale(
            scale: 1.0 - (progress * 0.02),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child:
                    progress > 0.5
                        ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Mark Complete',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────
  // COMPLETED BANNER
  // ────────────────────────────────────────────────
  Widget _buildCompletedBanner() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.accentGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'You\'re done for today',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentGreen,
            ),
          ),
          const SizedBox(width: 6),
          const Text('✌️', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // OPTIONS SHEET
  // ───────────────────────────────────────────��────
  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                _optionTile(
                  Icons.edit_rounded,
                  'Edit Habit',
                  AppTheme.onSurfaceVariant,
                  () {
                    Navigator.pop(ctx);
                    _showEditSheet(context);
                  },
                ),
                _optionTile(
                  Icons.delete_rounded,
                  'Delete Habit',
                  AppTheme.accentRed,
                  () {
                    Navigator.pop(ctx);
                    _confirmDelete(context);
                  },
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          ),
    );
  }

  Widget _optionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: AppTheme.onBackground,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  // ────────────────────────────────────────────��───
  // EDIT SHEET
  // ────────────────────────────────────────────────
  void _showEditSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: widget.habit.name);
    final whyCtrl = TextEditingController(text: widget.habit.whyReason ?? '');
    String selectedEmoji = widget.habit.emoji;
    int selectedCategoryIndex = 0;
    bool showEmojiPicker = false;
    bool isSaving = false;
    bool isValid = true;

    const dark = AppTheme.onBackground;
    const textSecondary = AppTheme.onSurfaceVariant;
    const border = AppTheme.outline;
    const surfaceVariant = AppTheme.surfaceVariant;
    const bg = AppTheme.background;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              void validate() {
                setSheetState(() => isValid = nameCtrl.text.trim().isNotEmpty);
              }

              nameCtrl.addListener(validate);

              Future<void> save() async {
                if (!isValid || isSaving) return;
                final trimmedName = nameCtrl.text.trim();
                if (trimmedName.isEmpty) {
                  setSheetState(() => isValid = false);
                  return;
                }
                setSheetState(() => isSaving = true);
                try {
                  final spaceService = context.read<SpaceService>();
                  await spaceService.updateHabit(
                    habitId: widget.habit.id,
                    name: trimmedName,
                    whyReason:
                        whyCtrl.text.trim().isEmpty
                            ? null
                            : whyCtrl.text.trim(),
                    emoji: selectedEmoji,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Habit updated ✅',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.onBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    Navigator.pop(context, 'updated');
                  }
                } catch (e) {
                  setSheetState(() => isSaving = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to save: ${e.toString().replaceFirst('Exception: ', '')}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.accentRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                }
              }

              Widget buildEmojiPicker() {
                final categories = HabitEmojis.categories;
                final currentCategory = categories[selectedCategoryIndex];
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children:
                                categories.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final cat = entry.value;
                                  final isActive = idx == selectedCategoryIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: GestureDetector(
                                      onTap:
                                          () => setSheetState(
                                            () => selectedCategoryIndex = idx,
                                          ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive ? dark : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isActive ? dark : border,
                                            width: isActive ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              cat.icon,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              cat.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isActive
                                                        ? Colors.white
                                                        : dark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children:
                              currentCategory.emojis.map((emoji) {
                                final isSel = selectedEmoji == emoji;
                                return GestureDetector(
                                  onTap:
                                      () => setSheetState(() {
                                        selectedEmoji = emoji;
                                        showEmojiPicker = false;
                                      }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSel ? dark : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel ? dark : border,
                                        width: isSel ? 2 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.90,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Edit Habit',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: dark,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: textSecondary,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap:
                                        () => setSheetState(
                                          () =>
                                              showEmojiPicker =
                                                  !showEmojiPicker,
                                        ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color:
                                            showEmojiPicker
                                                ? dark
                                                : surfaceVariant,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color:
                                              showEmojiPicker ? dark : border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          selectedEmoji,
                                          style: const TextStyle(fontSize: 26),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: nameCtrl,
                                      autofocus: true,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: dark,
                                        height: 1.1,
                                        letterSpacing: -0.5,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Habit name...',
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          color: textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 22,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        errorText:
                                            !isValid
                                                ? 'Name cannot be empty'
                                                : null,
                                      ),
                                      cursorColor: dark,
                                      cursorWidth: 2.5,
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: buildEmojiPicker(),
                                crossFadeState:
                                    showEmojiPicker
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFED7AA),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '💡',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'WHY THIS HABIT?',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBF5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFED7AA,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: TextField(
                                  controller: whyCtrl,
                                  maxLines: 2,
                                  minLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF78350F),
                                    height: 1.4,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'e.g. I want to feel more energetic...',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(
                                        0xFFD97706,
                                      ).withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  cursorColor: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isValid && !isSaving ? save : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: dark,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    disabledBackgroundColor: surfaceVariant,
                                    disabledForegroundColor: textSecondary,
                                  ),
                                  child:
                                      isSaving
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text(
                                            'Save Changes',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // ────────────────────────────────────────────────
  // DELETE CONFIRMATION
  // ────────────────────────────────────────────────
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder:
              (ctx, setDialogState) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: AppTheme.accentRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete Habit?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'re about to permanently delete',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${widget.habit.emoji} ${widget.habit.name}"',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accentRed.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: AppTheme.accentRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All streaks and history will be lost forever. This cannot be undone.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.accentRed,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isDeleting ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onBackground,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isDeleting
                                  ? null
                                  : () async {
                                    setDialogState(() => isDeleting = true);
                                    try {
                                      final spaceService =
                                          context.read<SpaceService>();
                                      await spaceService.deleteHabit(
                                        widget.habit.id,
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${widget.habit.emoji} "${widget.habit.name}" deleted.',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor:
                                                AppTheme.onBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        Navigator.pop(context, 'deleted');
                                      }
                                    } catch (e) {
                                      setDialogState(() => isDeleting = false);
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Delete failed: ${e.toString().replaceFirst('Exception: ', '')}',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppTheme.accentRed,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            disabledBackgroundColor: AppTheme.accentRed
                                .withValues(alpha: 0.5),
                          ),
                          child:
                              isDeleting
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Delete',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}

// ── Ring painter for the circular team progress ──
class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color track;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint =
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final progressPaint =
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -3.14159 / 2, // start from top
        2 * 3.14159 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.accent != accent;
}

// ── Internal data class ──
class _GroupMemberRow {
  final String name;
  final String? avatarId;
  final String? photoKey;
  final bool isDone;
  final bool isMe;
  final int currentStreak;
  final int bestStreak;
  final int totalLogs;
  final int rank;


  const _GroupMemberRow({
    required this.name,
    this.avatarId,
    this.photoKey,
    required this.isDone,
    required this.isMe,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalLogs,
    required this.rank,

  });
}
