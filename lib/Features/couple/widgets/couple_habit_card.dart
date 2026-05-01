import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';
import '../../shared/habit_shape_widget.dart';
import '../cubit/couple_dashboard_cubit.dart';

/// 💕 COUPLE HABIT CARD — Dual-progress layout showing both partners
/// Modern, flat, borderless design consistent with SoloHabitCard.
class CoupleHabitCard extends StatefulWidget {
  final DashboardHabit habit;
  final VoidCallback onTap;
  final Future<bool> Function() onMarkDone;
  final int index;
  final bool isLast;

  const CoupleHabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onMarkDone,
    this.index = 0,
    this.isLast = false,
  });

  @override
  State<CoupleHabitCard> createState() => _CoupleHabitCardState();
}

class _CoupleHabitCardState extends State<CoupleHabitCard>
    with SingleTickerProviderStateMixin {
  bool _checkAnimating = false;
  bool _pressing = false;
  late final AnimationController _checkController;
  late bool _calendarExpanded;
  late final List<DateTime?> _monthDays;

  // ── Nudge state ──
  bool _hasNudgedToday = false;
  bool _isNudging = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _calendarExpanded = widget.index == 0;
    _monthDays = _computeMonthDays();
    _loadNudgeState();
  }

  /// One-shot query on init to know if user already nudged today.
  Future<void> _loadNudgeState() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    // Only couple habits can be nudged
    if (widget.habit.spaceType != DashboardSpaceType.couple) return;
    // Only makes sense if there's a partner
    if (widget.habit.partnerId == null) return;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final result =
          await Supabase.instance.client
              .from('couple_nudges')
              .select('id')
              .eq('habit_id', widget.habit.id)
              .eq('sender_id', uid)
              .eq('nudge_date', today)
              .maybeSingle();
      if (mounted) setState(() => _hasNudgedToday = result != null);
    } catch (_) {}
  }

  Future<void> _handleNudge(BuildContext context) async {
    if (_isNudging || _hasNudgedToday) return;
    HapticFeedback.mediumImpact();
    setState(() => _isNudging = true);

    final code = await context.read<CoupleDashboardCubit>().sendNudge(
      widget.habit.id,
    );

    if (!mounted) return;

    switch (code) {
      case 'NUDGED':
        _showNudgeSnackBar(context, 'Nudge sent! 👀');
        setState(() => _hasNudgedToday = true);
        break;
      case 'ALREADY_DONE':
        _showNudgeSnackBar(context, 'They already did it today! 🎉');
        setState(() => _isNudging = false);
        break;
      case 'ALREADY_NUDGED':
        _showNudgeSnackBar(context, 'You already nudged them today 😄');
        setState(() => _hasNudgedToday = true);
        break;
      case 'NO_PARTNER':
        _showNudgeSnackBar(context, 'Invite your partner first!');
        setState(() => _isNudging = false);
        break;
      default:
        _showNudgeSnackBar(context, 'Something went wrong, try again');
        setState(() => _isNudging = false);
    }
  }

  void _showNudgeSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        backgroundColor: AppTheme.onBackground,
      ),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  // ✅ NEW: Reset animation when habit changes to prevent controller leaks
  @override
  void didUpdateWidget(CoupleHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habit.id != widget.habit.id) {
      // Habit changed — reset animation state
      if (_checkAnimating) {
        _checkController.reset();
        setState(() => _checkAnimating = false);
      }
    }
  }

  void _handleMarkDone() async {
    if (_checkAnimating) return;
    HapticFeedback.mediumImpact();
    setState(() => _checkAnimating = true);
    await _checkController.forward();
    final success = await widget.onMarkDone();
    if (!success && mounted) {
      await _checkController.reverse();
      setState(() => _checkAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final isDone = h.isDoneToday;
    final isScheduled = h.isScheduledToday;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressing ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(
                bottom: widget.isLast ? 0 : 14 * Responsive.scale(context),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16 * Responsive.scale(context),
                vertical: 14 * Responsive.scale(context),
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(
                  20 * Responsive.scale(context),
                ),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDone, isScheduled),
                  const SizedBox(height: 12),
                  _buildDuoStatusRow(),
                  _buildDualStatsRow(),
                  _buildCalendarSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isDone, bool isScheduled) {
    final h = widget.habit;
    final showCheck = isScheduled && !isDone;
    return Row(
      children: [
        HabitShapeWidget(emoji: h.emoji, size: 24 * Responsive.scale(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            h.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5 * Responsive.scale(context),
              fontWeight: FontWeight.w600,
              color: AppTheme.onBackground,
              decoration: TextDecoration.none,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Group streak badge (both users' combined) ──
        if (h.groupStreak > 0 && isScheduled && !isDone) ...[
          _buildGroupStreakBadge(),
          const SizedBox(width: 8),
        ],
        if (!isScheduled) _buildRestDayTag(),
        if (isDone) _buildDonePill(),
        if (showCheck) _buildInlineMarkDone(),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ── DUO STATUS DOTS (you + partner today)
  // ═══════════════════════════════════════════════
  Widget _buildDuoStatusRow() {
    final h = widget.habit;
    if (!h.isScheduledToday) return const SizedBox.shrink();
    final hasPartner = h.partnerId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          _buildPersonStatus('You', h.isDoneToday, true),
          if (hasPartner) ...[
            const SizedBox(width: 16),
            _buildPersonStatus('Partner', h.partnerDoneToday, false),
          ] else ...[
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDDDDE3),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Partner pending',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          // ── Nudge button ──
          _buildNudgeButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── NUDGE BUTTON
  // ═══════════════════════════════════════════════
  /// Rules (from spec):
  ///   hidden  — no partner, not scheduled, or partner already done today
  ///   disabled pill 'Nudged ✓' — already nudged today
  ///   active 👀 pill — default
  Widget _buildNudgeButton() {
    final h = widget.habit;
    // Hide if no partner
    if (h.partnerId == null) return const SizedBox.shrink();
    // Hide if not scheduled today
    if (!h.isScheduledToday) return const SizedBox.shrink();
    // Hide if partner already completed today
    if (h.partnerDoneToday) return const SizedBox.shrink();
    // Hide if I'm already done (nudge makes no sense)
    if (h.isDoneToday) return const SizedBox.shrink();

    final alreadyNudged = _hasNudgedToday;

    return GestureDetector(
      onTap: alreadyNudged ? null : () => _handleNudge(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              alreadyNudged
                  ? const Color(0xFFF0F0F5)
                  : const Color(0xFF5C4AE4).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                alreadyNudged
                    ? const Color(0xFFDDDDE3)
                    : const Color(0xFF5C4AE4).withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alreadyNudged ? '✓' : '👀',
              style: TextStyle(
                fontSize: alreadyNudged ? 11 : 12,
                color:
                    alreadyNudged
                        ? AppTheme.onSurfaceVariant
                        : const Color(0xFF5C4AE4),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              alreadyNudged ? 'Nudged' : 'Nudge',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    alreadyNudged
                        ? AppTheme.onSurfaceVariant
                        : const Color(0xFF5C4AE4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonStatus(String label, bool isDone, bool isMe) {
    final color = isDone ? const Color(0xFF2DA44E) : const Color(0xFFBBBBC5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
            color: isDone ? const Color(0xFF3D3D4E) : AppTheme.onSurfaceVariant,
          ),
        ),
        if (isDone) ...[
          const SizedBox(width: 3),
          Icon(Icons.check_rounded, size: 12, color: const Color(0xFF2DA44E)),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ── DUAL STATS ROW (my streak vs partner streak)
  // ═══════════════════════════════════════════════
  Widget _buildDualStatsRow() {
    final h = widget.habit;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statItem('${h.currentStreak}', 'you', icon: '🔥'),
                _dot(),
                _statItem('${h.partnerCurrentStreak}', 'them', icon: '🔥'),
                _dot(),
                _statItem('${h.groupStreak}', 'sync', icon: '⚡'),
                _dot(),
                _statItem('${h.bestStreak}d', 'best'),
              ],
            ),
          ),
        ),
        // Calendar toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _calendarExpanded = !_calendarExpanded);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color:
                  _calendarExpanded
                      ? AppTheme.onSurfaceVariant.withValues(alpha: 0.07)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 14,
                  color:
                      _calendarExpanded
                          ? AppTheme.onBackground
                          : AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _calendarExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color:
                        _calendarExpanded
                            ? AppTheme.onBackground
                            : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, {String? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (icon != null) ...[
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D3D4E),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '·',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    ),
  );

  // ═══════════════════════════════════════════════
  // ── CHALLENGE PROGRESS (dual progress bars)
  // ═══════════════════════════════════════════════
  Widget _buildChallengeProgress() {
    final h = widget.habit;
    if (h.targetDays == null || h.targetDays == 0)
      return const SizedBox.shrink();

    final myPct = (h.myCompletionPct ?? 0).clamp(0.0, 100.0);
    final partnerPct = (h.partnerCompletionPct ?? 0).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDF2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('🎯', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'Challenge Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (h.daysRemaining != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        h.daysRemaining! <= 3
                            ? AppTheme.accentRed.withValues(alpha: 0.08)
                            : const Color(0xFFEDEDF2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${h.daysRemaining}d left',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
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
          const SizedBox(height: 10),
          // My progress bar
          _buildProgressBar(
            label: 'You',
            pct: myPct,
            completed: h.myDaysCompleted ?? 0,
            total: h.targetDays!,
            color: const Color(0xFF2DA44E),
          ),
          const SizedBox(height: 8),
          // Partner progress bar
          _buildProgressBar(
            label: 'Partner',
            pct: partnerPct,
            completed: h.partnerDaysCompleted ?? 0,
            total: h.targetDays!,
            color: const Color(0xFF5C4AE4),
          ),
          // ── Missed / Remaining info ──
          if (h.myDaysMissed != null && h.myDaysMissed! > 0 ||
              h.partnerDaysMissed != null && h.partnerDaysMissed! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (h.myDaysMissed != null && h.myDaysMissed! > 0)
                  _challengeInfoChip(
                    '${h.myDaysMissed} missed',
                    AppTheme.accentRed.withValues(alpha: 0.08),
                    AppTheme.accentRed,
                  ),
                if (h.myDaysMissed != null && h.myDaysMissed! > 0)
                  const SizedBox(width: 6),
                if (h.canStillComplete == false)
                  _challengeInfoChip(
                    'can\'t complete',
                    AppTheme.accentRed.withValues(alpha: 0.08),
                    AppTheme.accentRed,
                  ),
                if (h.canStillComplete == true)
                  _challengeInfoChip(
                    'still possible ✨',
                    const Color(0xFF2DA44E).withValues(alpha: 0.08),
                    const Color(0xFF2DA44E),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar({
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
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '$completed/$total',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D4E),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${pct.round()}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _challengeInfoChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── ACTION WIDGETS
  // ═══════════════════════════════════════════════

  Widget _buildGroupStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '${widget.habit.groupStreak}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayTag() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.nightlight_round_outlined,
          size: 12,
          color: AppTheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          'Rest',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDonePill() {
    final h = widget.habit;
    final bothDone = h.isDoneToday && h.partnerDoneToday;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * Responsive.scale(context)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            bothDone ? Icons.favorite_rounded : Icons.check_circle_rounded,
            size: 24 * Responsive.scale(context),
            color: bothDone ? const Color(0xFF5C4AE4) : const Color(0xFF2DA44E),
          ),
          SizedBox(width: 6 * Responsive.scale(context)),
          Text(
            bothDone ? 'Synced' : 'Done',
            style: GoogleFonts.inter(
              fontSize: 12 * Responsive.scale(context),
              fontWeight: FontWeight.w700,
              color:
                  bothDone ? const Color(0xFF5C4AE4) : const Color(0xFF2DA44E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMarkDone() {
    return GestureDetector(
      onTap: () async {
        if (_checkAnimating) return;
        HapticFeedback.lightImpact();
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  "Mark as Done?",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                content: Text(
                  "Did you complete '${widget.habit.name}' for today?",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.onBackground.withValues(alpha: 0.8),
                  ),
                ),
                actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2DA44E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Yes, Done!",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
        );
        if (confirm == true && mounted) {
          _handleMarkDone();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _checkController,
        builder: (context, _) {
          final isTriggered = _checkController.value > 0.5;

          return Padding(
            padding: EdgeInsets.all(4 * Responsive.scale(context)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder:
                  (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isTriggered
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(isTriggered),
                size: 28 * Responsive.scale(context),
                color:
                    isTriggered
                        ? const Color(0xFF2DA44E)
                        : const Color(0xFFD5D5DA),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── COMBINED CALENDAR
  // ═══════════════════════════════════════════════
  Widget _buildCalendarSection() {
    return GestureDetector(
      onTap: () {},
      child: AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildDuoMonthCalendar(),
        ),
        crossFadeState:
            _calendarExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
        sizeCurve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildDuoMonthCalendar() {
    final monthDays = _monthDays;
    return Column(
      children: [
        // Legend — duo-specific
        Row(
          children: [
            _legendDot(const Color(0xFF2DA44E), 'Both'),
            const SizedBox(width: 8),
            _legendDot(const Color(0xFF5C4AE4), 'You'),
            const SizedBox(width: 8),
            _legendDot(const Color(0xFFFF6B6B), 'Them'),
            const SizedBox(width: 8),
            _legendDot(AppTheme.accentRed.withValues(alpha: 0.35), 'Miss'),
            const SizedBox(width: 8),
            _legendDot(const Color(0xFFD5D5DA), 'Rest'),
          ],
        ),
        const SizedBox(height: 8),
        // Day-of-week labels
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
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 4),
        // Grid
        ...List.generate((monthDays.length / 7).ceil(), (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: List.generate(7, (dayIdx) {
                final idx = week * 7 + dayIdx;
                if (idx >= monthDays.length || monthDays[idx] == null) {
                  return const Expanded(child: SizedBox(height: 20));
                }
                return Expanded(
                  child: Center(child: _buildDuoDayCell(monthDays[idx]!)),
                );
              }),
            ),
          );
        }),
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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDuoDayCell(DateTime day) {
    final state = _duoDayState(day);
    final isToday = _isToday(day);

    Color bgColor;
    Border? cellBorder;

    switch (state) {
      case _DuoDotState.bothDone:
        bgColor = const Color(0xFF2DA44E);
        break;
      case _DuoDotState.meOnly:
        bgColor = const Color(0xFF5C4AE4);
        break;
      case _DuoDotState.partnerOnly:
        bgColor = const Color(0xFFFF6B6B);
        break;
      case _DuoDotState.missed:
        bgColor = AppTheme.accentRed.withValues(alpha: 0.2);
        break;
      case _DuoDotState.rest:
        bgColor = const Color(0xFFE4E4EA);
        cellBorder = Border.all(color: const Color(0xFFD5D5DA), width: 0.5);
        break;
      case _DuoDotState.future:
        bgColor = const Color(0xFFEAEAEF);
        cellBorder = Border.all(color: const Color(0xFFDDDDE3), width: 0.5);
        break;
    }

    if (isToday) {
      cellBorder = Border.all(color: AppTheme.onBackground, width: 1.5);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = (constraints.maxWidth * 0.45).clamp(12.0, 16.0);
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(5),
              border: cellBorder,
            ),
            child:
                state == _DuoDotState.bothDone
                    ? Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        size: size * 0.55,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                    : null,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // ── HELPERS
  // ═══════════════════════════════════════════════
  List<DateTime?> _computeMonthDays() {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final last = DateTime(now.year, now.month + 1, 0);
    final List<DateTime?> days = [];
    for (int i = 0; i < first.weekday % 7; i++) {
      days.add(null);
    }
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(now.year, now.month, d));
    }
    return days;
  }

  bool _isMyCompleted(DateTime day) => widget.habit.myCalendar.any(
    (c) => c.year == day.year && c.month == day.month && c.day == day.day,
  );

  bool _isPartnerCompleted(DateTime day) => widget.habit.partnerCalendar.any(
    (c) => c.year == day.year && c.month == day.month && c.day == day.day,
  );

  bool _isScheduled(DateTime day) =>
      widget.habit.scheduledDays.contains(day.weekday);

  bool _isFuture(DateTime day) {
    final now = DateTime.now();
    return DateTime(
      day.year,
      day.month,
      day.day,
    ).isAfter(DateTime(now.year, now.month, now.day));
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  _DuoDotState _duoDayState(DateTime day) {
    // Before habit started
    if (widget.habit.startDate != null) {
      final start = DateTime(
        widget.habit.startDate!.year,
        widget.habit.startDate!.month,
        widget.habit.startDate!.day,
      );
      if (DateTime(day.year, day.month, day.day).isBefore(start)) {
        return _DuoDotState.future;
      }
    }
    if (_isFuture(day)) return _DuoDotState.future;

    final myDone = _isMyCompleted(day);
    final partnerDone = _isPartnerCompleted(day);

    if (myDone && partnerDone) return _DuoDotState.bothDone;
    if (myDone) return _DuoDotState.meOnly;
    if (partnerDone) return _DuoDotState.partnerOnly;
    if (!_isScheduled(day)) return _DuoDotState.rest;
    return _DuoDotState.missed;
  }
}

enum _DuoDotState { bothDone, meOnly, partnerOnly, missed, rest, future }
