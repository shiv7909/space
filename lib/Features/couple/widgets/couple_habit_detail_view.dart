import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../../models/dashboard_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/habit_emojis.dart';
import '../../../services/space_service.dart';
import '../../shared/habit_shape_widget.dart';

/// 💕 COUPLE HABIT DETAIL VIEW — Duo-specific detail with both partners' data
class CoupleHabitDetailView extends StatefulWidget {
  final DashboardHabit habit;
  final Future<bool> Function()? onMarkDone;

  const CoupleHabitDetailView({
    super.key,
    required this.habit,
    this.onMarkDone,
  });

  @override
  State<CoupleHabitDetailView> createState() => _CoupleHabitDetailViewState();
}

class _CoupleHabitDetailViewState extends State<CoupleHabitDetailView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _markDoneController;
  bool _markingDone = false;

  // ── Paginated calendar state ──────────────────────────────────────────
  late int _calYear;
  late int _calMonth;

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

    // Start on current month — no API call needed, dots come from h.myCalendar / h.partnerCalendar
    final now = DateTime.now();
    _calYear = now.year;
    _calMonth = now.month;
  }

  /// Navigate to a different month — purely local, no loading state needed.
  void _goToMonth(int year, int month) {
    final dt = DateTime(year, month);
    setState(() {
      _calYear = dt.year;
      _calMonth = dt.month;
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
    final bothDone = h.isDoneToday && h.partnerDoneToday;

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

                // ═══ SYNC STREAK + TODAY (merged hero card) ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildStreakHeroCard(h)),
                ),

                // ═══ COMPACT STATS ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(child: _buildCompactStats(h)),
                ),

                // ═══ CHALLENGE PROGRESS ═══
                if (h.mode == 'challenge' && h.targetDays != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildDuoChallengeProgress(h),
                    ),
                  ),

                // ═══ HABIT HEADER MESSAGE ═══
                if (h.habitHeader != null &&
                    (h.habitHeader!['message'] as String? ?? '').isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHabitHeaderBanner(h.habitHeader!),
                    ),
                  ),

                // ═══ DUO CALENDAR ═══
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildDuoCalendarSection(h),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            if (_shouldShowMarkDone)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: _buildMarkDoneButton(),
              ),

            if (widget.habit.isDoneToday)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: _buildCompletedBanner(bothDone),
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

  // ────────────────────────────────────────────────
  // HERO SECTION — couple-aware
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
            border: Border.all(color: const Color(0xFFE8D5F5), width: 2),
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
                    icon: Icons.favorite_rounded,
                    label: 'Couple',
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
  // STREAK HERO CARD — Sync streak BIG + today status
  // ────────────────────────────────────────────────
  Widget _buildStreakHeroCard(DashboardHabit h) {
    final syncStreak = h.groupStreak;
    final myStreak = h.currentStreak;
    final partnerStreak = h.partnerCurrentStreak;
    final bothDone = h.isDoneToday && h.partnerDoneToday;
    final hasPartner = h.partnerId != null;

    if (!h.isScheduledToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.nightlight_round_outlined,
              size: 15,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Rest day — no check-in needed',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

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
          // ── Top: fire + sync streak number ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: DotLottieLoader.fromAsset(
                  'assets/LottieAnimations/Fire.lottie',
                  frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
                    if (dotlottie != null) {
                      return Lottie.memory(
                        dotlottie.animations.values.single,
                        width: 52,
                        height: 52,
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$syncStreak',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onBackground,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          syncStreak == 1
                              ? 'day\nsync streak'
                              : 'days\nsync streak',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _heroStreakPill('You', myStreak),
                        const SizedBox(width: 6),
                        _heroStreakPill('Partner', partnerStreak),
                      ],
                    ),
                  ],
                ),
              ),
              if (syncStreak >= 7)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🏆', style: TextStyle(fontSize: 16)),
                ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFEDEDF2)),
          const SizedBox(height: 14),

          // ── Today's status ──
          Row(
            children: [
              Expanded(child: _buildStatusTile('You', h.isDoneToday)),
              const SizedBox(width: 10),
              Expanded(
                child:
                    hasPartner
                        ? _buildStatusTile('Partner', h.partnerDoneToday)
                        : _buildStatusTile('Partner', false, pending: true),
              ),
              if (bothDone) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Synced!',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStreakPill(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label · $count',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildStatusTile(String label, bool isDone, {bool pending = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color:
            isDone
                ? AppTheme.accentGreen.withValues(alpha: 0.07)
                : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDone
                  ? AppTheme.accentGreen.withValues(alpha: 0.20)
                  : const Color(0xFFEDEDF2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isDone ? AppTheme.accentGreen : const Color(0xFFE4E4EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone
                  ? Icons.check_rounded
                  : (pending
                      ? Icons.hourglass_empty_rounded
                      : Icons.radio_button_unchecked_rounded),
              size: 13,
              color: isDone ? Colors.white : AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onBackground,
                  ),
                ),
                Text(
                  isDone ? 'Done ✓' : (pending ? 'Waiting…' : 'Pending'),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceVariant,
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
  // COMPACT STATS — single card, 3 columns
  // ────────────────────────────────────────────────
  Widget _buildCompactStats(DashboardHabit h) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    'You',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    'Partner',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _compactStatRow(
            '🔥 Streak',
            '${h.currentStreak}',
            '${h.partnerCurrentStreak}',
          ),
          _compactStatRow(
            '⭐ Best',
            '${h.bestStreak}',
            '${h.partnerBestStreak}',
          ),
          _compactStatRow(
            '📅 Total',
            '${h.doneCount}',
            '${h.partnerTotalLogs}',
          ),
          if (h.myDaysCompleted != null || h.partnerDaysCompleted != null)
            _compactStatRow(
              '✅ Done',
              '${h.myDaysCompleted ?? 0}',
              '${h.partnerDaysCompleted ?? 0}',
            ),
          if (h.myDaysMissed != null || h.partnerDaysMissed != null)
            _compactStatRow(
              '❌ Missed',
              '${h.myDaysMissed ?? 0}',
              '${h.partnerDaysMissed ?? 0}',
            ),
        ],
      ),
    );
  }

  Widget _compactStatRow(String label, String myVal, String partnerVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                myVal,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                partnerVal,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // DUO CHALLENGE PROGRESS — Dual progress bars
  // ────────────────────────────────────────────────
  Widget _buildDuoChallengeProgress(DashboardHabit h) {
    if (h.targetDays == null || h.targetDays == 0)
      return const SizedBox.shrink();

    final myPct = (h.myCompletionPct ?? 0).clamp(0.0, 100.0);
    final partnerPct = (h.partnerCompletionPct ?? 0).clamp(0.0, 100.0);

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
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C4AE4).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  size: 16,
                  color: Color(0xFF5C4AE4),
                ),
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
              if (h.daysRemaining != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        h.daysRemaining! <= 3
                            ? AppTheme.accentRed.withValues(alpha: 0.08)
                            : const Color(0xFFEDEDF2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${h.daysRemaining}d left',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          h.daysRemaining! <= 3
                              ? AppTheme.accentRed
                              : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          // Your progress
          _buildProgressSection(
            label: 'You',
            pct: myPct,
            completed: h.myDaysCompleted ?? 0,
            total: h.targetDays!,
            color: const Color(0xFF2DA44E),
          ),
          const SizedBox(height: 14),
          // Partner progress
          _buildProgressSection(
            label: 'Partner',
            pct: partnerPct,
            completed: h.partnerDaysCompleted ?? 0,
            total: h.targetDays!,
            color: const Color(0xFF5C4AE4),
          ),
          // Status chips
          if (h.canStillComplete != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (h.myDaysMissed != null && h.myDaysMissed! > 0)
                  _challengeChip(
                    '${h.myDaysMissed} missed by you',
                    AppTheme.accentRed.withValues(alpha: 0.08),
                    AppTheme.accentRed,
                  ),
                if (h.myDaysMissed != null && h.myDaysMissed! > 0)
                  const SizedBox(width: 6),
                if (h.partnerDaysMissed != null && h.partnerDaysMissed! > 0)
                  _challengeChip(
                    '${h.partnerDaysMissed} missed by them',
                    const Color(0xFF5C4AE4).withValues(alpha: 0.08),
                    const Color(0xFF5C4AE4),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    h.canStillComplete == true
                        ? const Color(0xFF2DA44E).withValues(alpha: 0.06)
                        : AppTheme.accentRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    h.canStillComplete == true
                        ? Icons.check_circle_outline_rounded
                        : Icons.warning_amber_rounded,
                    size: 15,
                    color:
                        h.canStillComplete == true
                            ? const Color(0xFF2DA44E)
                            : AppTheme.accentRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    h.canStillComplete == true
                        ? 'Still possible to complete! ✨'
                        : 'Can\'t complete anymore',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          h.canStillComplete == true
                              ? const Color(0xFF2DA44E)
                              : AppTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection({
    required String label,
    required double pct,
    required int completed,
    required int total,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onBackground,
              ),
            ),
            const Spacer(),
            Text(
              '$completed/$total',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D4E),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${pct.round()}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _challengeChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(10),
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
  // DUO CALENDAR — paginated, one month at a time, both partners' dots
  // ────────────────────────────────────────────────
  Widget _buildDuoCalendarSection(DashboardHabit h) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(_calYear, _calMonth, 1);

    // Compute hasPrevMonth: is there a month before the current that is >= habit start?
    final habitStart = h.createdAt ?? h.startDate;
    final habitStartMonth =
        habitStart != null
            ? DateTime(habitStart.year, habitStart.month, 1)
            : null;
    final prevMonth = DateTime(_calYear, _calMonth - 1, 1);
    final hasPrevMonth =
        habitStartMonth == null || !prevMonth.isBefore(habitStartMonth);

    // hasNextMonth: don't allow going past the current real month
    final nowMonth = DateTime(now.year, now.month, 1);
    final hasNextMonth = currentMonthStart.isBefore(nowMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header + legend ──
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
              _legendDot(const Color(0xFF2DA44E), 'Both'),
              const SizedBox(width: 8),
              _legendDot(const Color(0xFF5C4AE4), 'You'),
              const SizedBox(width: 8),
              _legendDot(const Color(0xFFFF6B6B), 'Them'),
              const SizedBox(width: 8),
              _legendDot(AppTheme.accentRed.withValues(alpha: 0.5), 'Miss'),
            ],
          ),
        ),

        // ── Month card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month nav row
              Row(
                children: [
                  // Prev chevron
                  GestureDetector(
                    onTap:
                        hasPrevMonth
                            ? () {
                              HapticFeedback.selectionClick();
                              _goToMonth(_calYear, _calMonth - 1);
                            }
                            : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            hasPrevMonth
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
                            hasPrevMonth
                                ? AppTheme.onBackground
                                : AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                      ),
                    ),
                  ),

                  // Month label
                  Expanded(
                    child: Center(
                      child: Row(
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

                  // Next chevron
                  GestureDetector(
                    onTap:
                        hasNextMonth
                            ? () {
                              HapticFeedback.selectionClick();
                              _goToMonth(_calYear, _calMonth + 1);
                            }
                            : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            hasNextMonth
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
                            hasNextMonth
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

              // Day-of-week headers
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

              // Calendar grid — purely frontend, no loading state needed
              _buildDuoMonthGrid(h, now),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuoMonthGrid(DashboardHabit h, DateTime now) {
    final daysInMonth = DateTime(_calYear, _calMonth + 1, 0).day;
    final firstWeekday = DateTime(_calYear, _calMonth, 1).weekday % 7; // 0=Sun

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        ...List.generate(firstWeekday, (_) => const SizedBox()),
        ...List.generate(daysInMonth, (i) {
          final date = DateTime(_calYear, _calMonth, i + 1);
          return _buildDuoCalendarDay(date, h, now);
        }),
      ],
    );
  }

  Widget _buildDuoCalendarDay(DateTime date, DashboardHabit h, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(date.year, date.month, date.day);
    final isToday = thisDay == today;
    final isFuture = thisDay.isAfter(today);

    bool isBeforeStart = false;
    if (h.createdAt != null) {
      final created = DateTime(
        h.createdAt!.year,
        h.createdAt!.month,
        h.createdAt!.day,
      );
      if (thisDay.isBefore(created)) isBeforeStart = true;
    } else if (h.startDate != null) {
      final start = DateTime(
        h.startDate!.year,
        h.startDate!.month,
        h.startDate!.day,
      );
      if (thisDay.isBefore(start)) isBeforeStart = true;
    }

    final myDone = h.myCalendar.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
    final partnerDone = h.partnerCalendar.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
    final isScheduled = h.scheduledDays.contains(date.weekday);

    Color bgColor;
    Color textColor;
    Border? border;
    Widget? overlay;

    if (isFuture || isBeforeStart) {
      bgColor = const Color(0xFFF5F5F8);
      textColor = const Color(0xFFBBBBC5);
    } else if (isToday) {
      bgColor =
          myDone && partnerDone
              ? const Color(0xFF2DA44E)
              : myDone
              ? const Color(0xFF5C4AE4)
              : partnerDone
              ? const Color(0xFFFF6B6B)
              : const Color(0xFFF5F5F8);
      textColor =
          (myDone || partnerDone) ? Colors.white : const Color(0xFFBBBBC5);
      border = Border.all(color: AppTheme.onBackground, width: 2);
    } else if (myDone && partnerDone) {
      bgColor = const Color(0xFF2DA44E);
      textColor = Colors.white;
      overlay = Icon(
        Icons.favorite_rounded,
        size: 8,
        color: Colors.white.withValues(alpha: 0.7),
      );
    } else if (myDone) {
      bgColor = const Color(0xFF5C4AE4);
      textColor = Colors.white;
    } else if (partnerDone) {
      bgColor = const Color(0xFFFF6B6B);
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (overlay != null)
                  Positioned(top: 1, right: 1, child: overlay),
              ],
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
  // ──────────────────────────────────────��─────────
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
  // COMPLETED BANNER — couple-aware
  // ────────────────────────────────────────────────
  Widget _buildCompletedBanner(bool bothDone) {
    final color = bothDone ? const Color(0xFF5C4AE4) : AppTheme.accentGreen;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              bothDone ? Icons.favorite_rounded : Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            bothDone
                ? 'Both done — in sync! '
                : 'You\'re done! Waiting for partner…',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
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
                                        'e.g. We want to grow together...',
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
                              'Both partners\' streaks and history will be lost forever. This cannot be undone.',
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
}
