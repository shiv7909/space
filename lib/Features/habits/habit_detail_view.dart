import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/dashboard_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/habit_emojis.dart';
import '../../services/space_service.dart';
import '../../core/utils/responsive_helpers.dart';
import '../shared/habit_shape_widget.dart';
import 'widgets/shimmer_loaders.dart';

/// 🎯 HABIT DETAIL VIEW — Clean, Light, Consistent with Solo Dashboard
class HabitDetailView extends StatefulWidget {
  final DashboardHabit habit;
  final Future<bool> Function()? onMarkDone;

  const HabitDetailView({super.key, required this.habit, this.onMarkDone});

  @override
  State<HabitDetailView> createState() => _HabitDetailViewState();
}

class _HabitDetailViewState extends State<HabitDetailView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _markDoneController;
  bool _markingDone = false;

  // ── Paginated calendar state ──────────────────────────────────────────
  late int _calYear;
  late int _calMonth;
  HabitCalendarMonth? _calData;
  bool _calLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

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
    _pulseController.dispose();
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

    bool success = false;
    if (widget.onMarkDone != null) {
      success = await widget.onMarkDone!();
    }

    if (!mounted) return;

    if (success) {
      // Now animate to success state
      await _markDoneController.forward();
      if (mounted) {
        Navigator.pop(context, 'updated');
      }
    } else {
      // If failed, don't animate
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
                // ═══ CLEAN APP BAR ═══
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

                // ═══ QUICK STATS ROW ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildQuickStats(h)),
                ),

                // ═══ CHALLENGE PROGRESS ═══ (only for challenge mode)
                if (h.mode == 'challenge' && h.targetDays != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ChallengeProgressCard(habit: h),
                    ),
                  ),

                // ═══ STREAK CARD ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildStreakCard(h)),
                ),

                // ═══ HABIT HEADER MESSAGE ═══ (right after hero — most visible spot)
                if (h.habitHeader != null &&
                    (h.habitHeader!['message'] as String? ?? '').isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHabitHeaderBanner(h.habitHeader!),
                    ),
                  ),

                // ═══ CALENDAR ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildCalendarSection(h)),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
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

  // ───────────────────────────────────────��────────
  // HERO SECTION — compact horizontal: icon left, info right
  // ────────────────────────────────────────────────
  Widget _buildHeroSection(DashboardHabit h) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: Responsive.scale(context) * 64,
          height: Responsive.scale(context) * 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18 * Responsive.scale(context)),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Center(
            child: HabitShapeWidget(
              emoji: h.emoji,
              size: 34 * Responsive.scale(context),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Info on the right
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                h.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18 * Responsive.scale(context),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // ── Why Reason pill — shown inline under name ──
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
              // Badges row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
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

  // ────────────────────────────────────────��───────
  // QUICK STATS ROW — 4 mini stats in a row
  // ────────────────────────────────────────────────
  Widget _buildQuickStats(DashboardHabit h) {
    // ── Challenge mode: show Days Done + Days Remaining ──
    if (h.mode == 'challenge' && h.targetDays != null) {
      final stats = _computeChallengeQuickStats(h);
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: 16 * Responsive.scale(context),
          horizontal: 8 * Responsive.scale(context),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20 * Responsive.scale(context)),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Row(
          children: [
            _quickStatItem('${stats.done}', 'Days Done', AppTheme.accentGreen),
            _quickStatDivider(),
            _quickStatItem(
              '${stats.remaining}',
              'Days Left',
              const Color(0xFF5C4AE4),
            ),
          ],
        ),
      );
    }

    // ── Infinite mode: original stats ──
    final totalDays = h.myCalendar.length;
    final scheduledPast =
        h.startDate != null
            ? DateTime.now().difference(h.startDate!).inDays + 1
            : totalDays;
    final rate =
        scheduledPast > 0
            ? ((totalDays / scheduledPast) * 100).clamp(0, 100).round()
            : 0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16 * Responsive.scale(context),
        horizontal: 8 * Responsive.scale(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * Responsive.scale(context)),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Row(
        children: [
          _quickStatItem('${h.currentStreak}', 'Current', AppTheme.accentAmber),
          _quickStatDivider(),
          _quickStatItem('${h.bestStreak}', 'Best', const Color(0xFF8B5CF6)),
          _quickStatDivider(),
          _quickStatItem('$totalDays', 'Total', AppTheme.accentGreen),
          _quickStatDivider(),
          _quickStatItem('$rate%', 'Rate', const Color(0xFF5C4AE4)),
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
              fontSize: 20 * Responsive.scale(context),
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
            ),
          ),
          SizedBox(height: 2 * Responsive.scale(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6 * Responsive.scale(context),
                height: 6 * Responsive.scale(context),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(
                    3 * Responsive.scale(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11 * Responsive.scale(context),
                  fontWeight: FontWeight.w600,
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
    return Container(
      width: 1.5,
      height: 32 * Responsive.scale(context),
      color: const Color(0xFFF1F5F9),
    );
  }

  // ────────────────────────────────────────────────
  // STREAK CARD
  // ────────────────���───────────────────────���───────
  Widget _buildStreakCard(DashboardHabit h) {
    final isActive = h.streakStatus == DashboardStreakStatus.active;
    final streakDays = h.currentStreak;

    return Container(
      padding: EdgeInsets.all(18 * Responsive.scale(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * Responsive.scale(context)),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Row(
        children: [
          // Fire with subtle glow
          Container(
            width: 56,
            height: 56,
            // decoration: BoxDecoration(
            //   color: isActive
            //       ? AppTheme.accentAmber.withValues(alpha: 0.12)
            //       : AppTheme.surfaceVariant,
            //   borderRadius: BorderRadius.circular(16),
            // ),
            child: Center(
              child: DotLottieLoader.fromAsset(
                'assets/LottieAnimations/Fire.lottie',
                frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                  if (dotlottie != null) {
                    return Lottie.memory(
                      dotlottie.animations.values.single,
                      width: 45 * Responsive.scale(context),
                      height: 45 * Responsive.scale(context),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      streakDays > 0 ? '$streakDays' : '0',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 26 * Responsive.scale(context),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      streakDays == 1 ? 'day streak' : 'days streak',
                      style: GoogleFonts.inter(
                        fontSize: 14 * Responsive.scale(context),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Keep it going! 💪'
                      : streakDays == 0
                      ? 'Start your streak today!'
                      : 'Complete today to continue',
                  style: GoogleFonts.inter(
                    fontSize: 12 * Responsive.scale(context),
                    fontWeight: FontWeight.w400,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isActive && streakDays >= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  8 * Responsive.scale(context),
                ),
              ),
              child: Text(
                '🏆',
                style: TextStyle(fontSize: 16 * Responsive.scale(context)),
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────���───────────
  // HABIT HEADER MESSAGE BANNER
  // ────────────────────────────────────────────────
  Widget _buildHabitHeaderBanner(Map<String, dynamic> header) {
    final message = header['message'] as String? ?? '';

    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // CALENDAR SECTION — paginated, one month at a time
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
                'History',
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

  Widget _buildMonthGrid(
    HabitCalendarMonth data,
    DashboardHabit h,
    DateTime now,
  ) {
    final daysInMonth = DateTime(data.year, data.month + 1, 0).day;
    final firstWeekday =
        DateTime(data.year, data.month, 1).weekday % 7; // 0=Sun

    // Use scheduled_days from the API response if available, else fall back to habit model
    final scheduledDays =
        data.scheduledDays.isNotEmpty ? data.scheduledDays : h.scheduledDays;

    // Effective habit start date (prefer API, fall back to model)
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
      textColor = AppTheme.onSurfaceVariant;
    } else {
      bgColor = AppTheme.accentRed.withValues(alpha: 0.12);
      textColor = AppTheme.accentRed;
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

  // ──���─────────────────────────────────────────────
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
    return const SizedBox.shrink();
  }

  // ────────────────────────────────────────────────
  // OPTIONS SHEET
  // ────────────────────────────────────────────────
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

  // ────────────────────────────────────────────────
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
                      // Handle + header row
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
                      // Scrollable fields
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Emoji + Name ──
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
                              // ── Emoji Picker ──
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
                              // ── Why ──
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
                              // ── Save Button ──
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
  // CHALLENGE QUICK STATS — for the challenge mode in habit detail
  // ────────────────────────────────────────────────
  _ChallengeQuickStats _computeChallengeQuickStats(DashboardHabit h) {
    final totalDays = h.targetDays ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int scheduledCount = 0;
    int doneCount = 0;

    final completedSet = <DateTime>{};
    for (final d in h.myCalendar) {
      completedSet.add(DateTime(d.year, d.month, d.day));
    }

    // Walk anchor → yesterday only (today is still pending)
    DateTime cursor =
        h.startDate != null
            ? DateTime(h.startDate!.year, h.startDate!.month, h.startDate!.day)
            : h.createdAt != null
            ? DateTime(h.createdAt!.year, h.createdAt!.month, h.createdAt!.day)
            : today;

    while (cursor.isBefore(today)) {
      if (h.scheduledDays.contains(cursor.weekday)) {
        scheduledCount++;
        if (completedSet.contains(cursor)) doneCount++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    // Today: count as done if completed, count as scheduled either way
    if (h.scheduledDays.contains(today.weekday)) {
      scheduledCount++;
      if (completedSet.contains(today)) doneCount++;
    }

    final remaining = (totalDays - scheduledCount).clamp(0, totalDays);

    return _ChallengeQuickStats(
      total: totalDays,
      done: doneCount,
      remaining: remaining,
    );
  }
}

class _ChallengeQuickStats {
  final int total;
  final int done;
  final int remaining;

  const _ChallengeQuickStats({
    required this.total,
    required this.done,
    required this.remaining,
  });
}

/// Challenge progress card — shows done/missed/remaining in a challenge
class _ChallengeProgressCard extends StatefulWidget {
  final DashboardHabit habit;
  const _ChallengeProgressCard({required this.habit});

  @override
  State<_ChallengeProgressCard> createState() => _ChallengeProgressCardState();
}

class _ChallengeProgressCardState extends State<_ChallengeProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _barAnimation = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeOutCubic,
    );
    _barController.forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  /// Count every calendar day from startDate up to (and including) today
  /// that falls on a scheduledDay, then split into done vs missed.
  _ChallengeStats _compute() {
    final h = widget.habit;
    final totalDays = h.targetDays ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Anchor: use startDate if available, else createdAt, else today
    final DateTime anchor =
        h.startDate != null
            ? DateTime(h.startDate!.year, h.startDate!.month, h.startDate!.day)
            : h.createdAt != null
            ? DateTime(h.createdAt!.year, h.createdAt!.month, h.createdAt!.day)
            : today;

    // Build a Set<DateTime> of completed days for O(1) lookup
    final completedSet = <DateTime>{};
    for (final d in h.myCalendar) {
      completedSet.add(DateTime(d.year, d.month, d.day));
    }

    int done = 0;
    int missed = 0;

    // Walk every day from anchor → yesterday (today is still pending, not missed)
    DateTime cursor = anchor;
    while (cursor.isBefore(today)) {
      if (h.scheduledDays.contains(cursor.weekday)) {
        if (completedSet.contains(cursor)) {
          done++;
        } else {
          missed++;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    // Today: only count as done if completed, never as missed
    if (h.scheduledDays.contains(today.weekday) &&
        completedSet.contains(today)) {
      done++;
    }

    // Remaining = totalDays already committed minus days elapsed on-schedule
    // Cap remaining at zero so it never goes negative
    final elapsed = done + missed;
    final remaining = (totalDays - elapsed).clamp(0, totalDays);
    final completionPct = totalDays > 0 ? done / totalDays : 0.0;

    return _ChallengeStats(
      total: totalDays,
      done: done,
      missed: missed,
      remaining: remaining,
      pct: completionPct,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final stats = _compute();

    // Colour shifts: all green if done, amber warning if missing many
    final missRate = stats.total > 0 ? stats.missed / stats.total : 0.0;
    final Color accentBar =
        stats.done == stats.total
            ? AppTheme.accentGreen
            : missRate > 0.3
            ? AppTheme.accentAmber
            : const Color(0xFF5C4AE4);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentBar.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.flag_rounded, size: 16, color: accentBar),
              ),
              const SizedBox(width: 10),
              Text(
                'Challenge Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // Total days badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.outline, width: 1),
                ),
                child: Text(
                  '${h.targetDays}d total',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Four stat tiles ──
          Row(
            children: [
              _StatTile(
                value: stats.total,
                label: 'Total',
                color: AppTheme.onSurfaceVariant,
                icon: Icons.outlined_flag_rounded,
              ),
              const SizedBox(width: 8),
              _StatTile(
                value: stats.done,
                label: 'Done',
                color: AppTheme.accentGreen,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _StatTile(
                value: stats.missed,
                label: 'Missed',
                color: AppTheme.accentRed,
                icon: Icons.cancel_outlined,
              ),
              const SizedBox(width: 8),
              _StatTile(
                value: stats.remaining,
                label: 'Left',
                color: const Color(0xFF5C4AE4),
                icon: Icons.hourglass_bottom_rounded,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Animated segmented progress bar ──
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedBuilder(
                  animation: _barAnimation,
                  builder: (context, _) {
                    final animVal = _barAnimation.value;
                    final total = stats.total > 0 ? stats.total : 1;
                    final doneWidth =
                        (stats.done / total) * totalWidth * animVal;
                    final missedWidth =
                        (stats.missed / total) * totalWidth * animVal;
                    final remainingWidth = totalWidth - doneWidth - missedWidth;
                    return SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          if (stats.done > 0)
                            SizedBox(
                              width: doneWidth,
                              child: Container(color: AppTheme.accentGreen),
                            ),
                          if (stats.missed > 0)
                            SizedBox(
                              width: missedWidth,
                              child: Container(
                                color: AppTheme.accentRed.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          if (remainingWidth > 0)
                            SizedBox(
                              width: remainingWidth,
                              child: Container(color: const Color(0xFFF0F0F5)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ── Legend + percentage ──
          Row(
            children: [
              _LegendDot(color: AppTheme.accentGreen, label: 'Done'),
              const SizedBox(width: 12),
              _LegendDot(
                color: AppTheme.accentRed.withValues(alpha: 0.7),
                label: 'Missed',
              ),
              const SizedBox(width: 12),
              _LegendDot(color: const Color(0xFFD5D5DA), label: 'Left'),
              const Spacer(),
              AnimatedBuilder(
                animation: _barAnimation,
                builder: (context, _) {
                  final pct = (stats.pct * 100 * _barAnimation.value).toInt();
                  return Text(
                    '$pct% complete',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentBar,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small stat tile inside the challenge card ──
class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.14), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 5),
            Text(
              '$value',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onBackground,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
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
      ),
    );
  }
}

// ── Tiny legend dot ──
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
}

class _ChallengeStats {
  final int total;
  final int done;
  final int missed;
  final int remaining;
  final double pct;

  const _ChallengeStats({
    required this.total,
    required this.done,
    required this.missed,
    required this.remaining,
    required this.pct,
  });
}
